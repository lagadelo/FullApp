import * as THREE from 'three';
import { OrbitControls } from './vendor/OrbitControls.js';

const ui = Object.fromEntries(
  ['canvas', 'notice', 'summary', 'play', 'step', 'time', 'rate'].map(id => [id, document.getElementById(id)])
);
const numbers = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });

function showNotice(message) {
  ui.notice.textContent = message;
  ui.notice.hidden = false;
}

function createTerrain({ x, z, heights }) {
  const vertices = [];
  const faces = [];
  const colors = [];
  const elevations = heights.flat().filter(height => height !== null);
  const min = elevations.length ? Math.min(...elevations) : 0;
  const relief = Math.max(...elevations) - min || 1;
  const low = new THREE.Color('#375f54');
  const high = new THREE.Color('#aec1a6');
  const color = new THREE.Color();
  for (let row = 0; row < z.length; row++) {
    for (let column = 0; column < x.length; column++) {
      const height = heights[row][column];
      vertices.push(x[column], height ?? 0, z[row]);
      color.copy(low).lerp(high, ((height ?? min) - min) / relief);
      colors.push(color.r, color.g, color.b);
      if (row === 0 || column === 0) continue;
      const current = row * x.length + column;
      const above = current - x.length;
      if (height !== null && heights[row][column - 1] !== null &&
          heights[row - 1][column] !== null && heights[row - 1][column - 1] !== null) {
        faces.push(above - 1, current - 1, above, above, current - 1, current);
      }
    }
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
  geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
  geometry.setIndex(faces);
  geometry.computeVertexNormals();
  return new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 1 }));
}

function surfaceAt({ x, z, heights }, east, south) {
  if (east < x[0] || south < z[0] || x.length < 2 || z.length < 2) return null;
  const column = x.findIndex(value => value >= east);
  const row = z.findIndex(value => value >= south);
  if (column === -1 || row === -1) return null;
  const right = Math.max(1, column);
  const bottom = Math.max(1, row);
  const nw = heights[bottom - 1][right - 1];
  const ne = heights[bottom - 1][right];
  const sw = heights[bottom][right - 1];
  const se = heights[bottom][right];
  if ([nw, ne, sw, se].includes(null)) return null;
  const u = (east - x[right - 1]) / (x[right] - x[right - 1]);
  const v = (south - z[bottom - 1]) / (z[bottom] - z[bottom - 1]);
  return u + v <= 1
    ? nw + (ne - nw) * u + (sw - nw) * v
    : se + (sw - se) * (1 - u) + (ne - se) * (1 - v);
}

function createRoute(points, terrain, size) {
  const vertices = [];
  const offset = size / 500;
  for (let index = 0; index < points.length; index++) {
    const [x, y, z] = points[index];
    const [nextX, nextY, nextZ] = points[(index + 1) % points.length];
    if (!terrain) {
      vertices.push(new THREE.Vector3(x, y + offset, z), new THREE.Vector3(nextX, nextY + offset, nextZ));
      continue;
    }
    const divisions = Math.max(1, Math.ceil(Math.hypot(nextX - x, nextZ - z) * 200 / size));
    let previous;
    for (let step = 0; step <= divisions; step++) {
      const east = THREE.MathUtils.lerp(x, nextX, step / divisions);
      const south = THREE.MathUtils.lerp(z, nextZ, step / divisions);
      const altitude = surfaceAt(terrain, east, south);
      const current = altitude === null ? null : new THREE.Vector3(east, altitude + offset, south);
      if (previous && current) vertices.push(previous, current);
      previous = current;
    }
  }
  return new THREE.LineSegments(
    new THREE.BufferGeometry().setFromPoints(vertices),
    new THREE.LineBasicMaterial({ color: '#ffc078' })
  );
}

function createViewer(replay) {
  const world = new THREE.Scene();
  world.background = new THREE.Color('#14232a');
  const bounds = new THREE.Box3();
  for (const [x, y, z] of replay.route) bounds.expandByPoint(new THREE.Vector3(x, y ?? 0, z));
  if (replay.terrain) {
    const terrain = createTerrain(replay.terrain);
    world.add(terrain);
    bounds.expandByObject(terrain);
  }
  bounds.max.y += replay.heightAboveGround;
  const size = Math.max(bounds.getSize(new THREE.Vector3()).length(), 1);
  if (!replay.terrain) {
    const grid = new THREE.GridHelper(size * 1.15, 24, '#59767a', '#365056');
    world.add(grid);
  }
  world.add(createRoute(replay.route, replay.terrain, size));
  world.add(new THREE.HemisphereLight('#d8edff', '#5f5142', 1.25));
  const sun = new THREE.DirectionalLight('#fff2cf', 2);
  sun.position.set(-1, 2, -1.2);
  world.add(sun);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  ui.canvas.append(renderer.domElement);
  const camera = new THREE.PerspectiveCamera(50, 1, size / 10000, size * 15);
  const controls = new OrbitControls(camera, renderer.domElement);
  controls.target.copy(bounds.getCenter(new THREE.Vector3()));
  const viewDirection = new THREE.Vector3(0.4, 0.58, 0.65).normalize();
  controls.maxDistance = size * 10;
  controls.minDistance = size / 500;
  controls.maxPolarAngle = Math.PI / 2 - 0.005;

  const avatars = new Map();
  const sphere = new THREE.SphereGeometry(size / 170, 12, 8);
  const material = new THREE.MeshStandardMaterial({ color: '#8ad6ff', emissive: '#34647d' });
  const frames = replay.frames;
  let selected = 0;
  let seconds = frames[0].seconds;
  let playing = false;
  let previous;

  function seek(index) {
    selected = index;
    ui.step.value = index;
    const { tick, seconds: frameTime, drones } = frames[index];
    ui.time.textContent = `Tik ${tick} · ${numbers.format(frameTime)} s`;
    const visible = drones.filter(({ position }) => position[1] !== null);
    const mode = { terrain: 'Relief MNT', planar: 'Parcours sur plan', abstract: 'Circuit abstrait' }[replay.mode];
    const missing = drones.length - visible.length;
    const summary = `${mode} · ${visible.length} drone${visible.length === 1 ? '' : 's'}` +
      (missing ? ` · ${missing} sans altitude de sol` : '');
    if (ui.summary.textContent !== summary) ui.summary.textContent = summary;
    for (const avatar of avatars.values()) avatar.visible = false;
    for (const { id, position } of visible) {
      if (!avatars.has(id)) {
        const avatar = new THREE.Mesh(sphere, material);
        avatars.set(id, avatar);
        world.add(avatar);
      }
      const avatar = avatars.get(id);
      avatar.position.fromArray(position);
      avatar.visible = true;
    }
  }

  function setPlaying(value) {
    playing = value;
    ui.play.textContent = value ? 'Pause' : 'Lire';
  }

  ui.step.max = frames.length - 1;
  ui.step.disabled = frames.length === 1;
  ui.rate.disabled = ui.play.disabled = frames.length === 1;
  ui.step.addEventListener('input', () => {
    setPlaying(false);
    seek(ui.step.valueAsNumber);
    seconds = frames[selected].seconds;
  });
  ui.play.addEventListener('click', () => {
    if (!playing && selected === frames.length - 1) {
      seek(0);
      seconds = frames[0].seconds;
    }
    setPlaying(!playing);
  });
  seek(0);

  let framed = false;
  new ResizeObserver(() => {
    const { width, height } = ui.canvas.getBoundingClientRect();
    if (!height || !width) return;
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
    if (!framed) {
      const halfVertical = THREE.MathUtils.degToRad(camera.fov / 2);
      const halfHorizontal = Math.atan(Math.tan(halfVertical) * camera.aspect);
      const distance = size * 0.44 / Math.sin(Math.min(halfVertical, halfHorizontal));
      camera.position.copy(controls.target).addScaledVector(viewDirection, distance);
      controls.update();
      framed = true;
    }
  }).observe(ui.canvas);

  renderer.setAnimationLoop(now => {
    if (playing && previous !== undefined) {
      seconds += Math.min(now - previous, 250) / 1000 * Number(ui.rate.value);
      let next = selected;
      while (next < frames.length - 1 && frames[next + 1].seconds <= seconds) next++;
      if (next !== selected) seek(next);
      if (selected === frames.length - 1) setPlaying(false);
    }
    previous = now;
    renderer.render(world, camera);
  });
}

try {
  const response = await fetch('./scene.json');
  if (!response.ok) throw new Error(`Historique indisponible (HTTP ${response.status})`);
  const scene = await response.json();
  if (scene.format !== 'sose-replay-3d' || scene.version !== 1 || !scene.frames.length) {
    throw new Error('Format de rejeu inconnu');
  }
  createViewer(scene);
} catch (error) {
  ui.summary.textContent = 'Rejeu indisponible';
  showNotice(error.message);
}
