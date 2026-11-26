'use strict';

const byId = id => document.getElementById(id);
const map = L.map('map').setView([46.3, 2.3], 6);
const streets = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 19,
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
});
L.control.scale({ imperial: false }).addTo(map);
const geometry = L.layerGroup().addTo(map);
const emptyPlan = () => ({ waypoints: [], bounds: null, convexHull: false });
const round = value => Number(value.toFixed(6));
const latitudeLongitude = ([longitude, latitude]) => [latitude, longitude];
const corners = ([west, south, east, north]) => [[south, west], [north, east]];
const inRange = (n, min, max) => Number.isFinite(n) && n >= min && n <= max;
let plan = emptyPlan();
let example = null;
let catalog = new Map();
const basemaps = new Map();
let terrainOptions = null;
let terrainPending = false;
let background;
let selected = -1;
let mode = 'navigate';
let anchor = null;

function say(message) {
  byId('status').textContent = message;
}

function validPoint(point) {
  return Array.isArray(point) && point.length === 2 &&
    inRange(point[0], -180, 180) && inRange(point[1], -90, 90);
}

function checkedPlan(candidate) {
  const { waypoints, bounds, convexHull } = candidate;
  if (!Array.isArray(waypoints) || !waypoints.every(validPoint) ||
      typeof convexHull !== 'boolean' ||
      (bounds !== null && (!Array.isArray(bounds) || bounds.length !== 4 ||
       !validPoint(bounds.slice(0, 2)) || !validPoint(bounds.slice(2)) ||
       bounds[0] >= bounds[2] || bounds[1] >= bounds[3]))) {
    throw new Error('Le tracé doit contenir des coordonnées WGS84 et, au besoin, une emprise rectangulaire.');
  }
  return { waypoints, bounds, convexHull };
}

function showBackground() {
  const site = catalog.get(example);
  const control = byId('layer');
  control.querySelector('[value="relief"]').disabled = !site;
  const selectedLayer = basemaps.get(control.value);
  const layerStatus = byId('layer-status');
  layerStatus.hidden = true;
  if (background) map.removeLayer(background);
  if (site && control.value === 'relief') {
    background = L.imageOverlay('relief/' + encodeURIComponent(example), corners(site.bounds), {
      attribution: site.source,
      interactive: false
    });
  } else if (selectedLayer) {
    background = selectedLayer;
  } else {
    control.value = 'osm';
    background = streets;
  }
  background.addTo(map);
}

function addBasemaps(sources) {
  const control = byId('layer');
  for (const source of sources) {
    const layer = L.tileLayer(source.url, {
      maxZoom: 19,
      maxNativeZoom: source.maxNativeZoom,
      attribution: `<a href="${source.homepage}">${source.credit[0]}</a>` +
        source.credit.slice(1).map(credit => ` · ${credit}`).join('')
    });
    layer.on('tileerror', () => {
      if (background !== layer) return;
      const status = byId('layer-status');
      status.textContent = `Certaines tuiles ${source.label} sont indisponibles. ${source.coverage}`;
      status.hidden = false;
    });
    basemaps.set(source.id, layer);
    control.append(new Option(source.label, source.id));
  }
}

function showPlan() {
  geometry.clearLayers();
  const coordinates = plan.waypoints.map(latitudeLongitude);
  const style = { color: '#f5b94f', weight: 3, interactive: false };
  if (coordinates.length >= 3) L.polygon(coordinates, { ...style, fillOpacity: 0.06 }).addTo(geometry);
  else if (coordinates.length === 2) L.polyline(coordinates, style).addTo(geometry);
  if (plan.bounds) L.rectangle(corners(plan.bounds), {
    color: '#65dce1', dashArray: '6 5', weight: 2, fillOpacity: 0.04, interactive: false
  }).addTo(geometry);
  if (anchor) L.circleMarker(latitudeLongitude(anchor), {
    radius: 5, color: '#65dce1', interactive: false
  }).addTo(geometry);

  coordinates.forEach((point, index) => {
    const icon = L.divIcon({
      className: 'waypoint-marker' + (selected === index ? ' selected' : ''),
      html: String(index + 1), iconSize: [24, 24], iconAnchor: [12, 12]
    });
    L.marker(point, { icon, draggable: true, title: 'Point ' + (index + 1) })
      .addTo(geometry)
      .on('click', () => selectPoint(index))
      .on('dragend', event => {
        const destination = map.wrapLatLng(event.target.getLatLng());
        plan.waypoints[index] = [round(destination.lng), round(destination.lat)];
        selectPoint(index);
      });
  });

  const list = byId('waypoint-list');
  list.replaceChildren(...plan.waypoints.map(([longitude, latitude], index) => {
    const item = document.createElement('li');
    const button = document.createElement('button');
    button.textContent = longitude.toFixed(6) + '  ·  ' + latitude.toFixed(6);
    button.setAttribute('aria-pressed', String(selected === index));
    button.addEventListener('click', () => selectPoint(index, true));
    item.append(button);
    return item;
  }));
  byId('waypoint-count').textContent = plan.waypoints.length;
  byId('extent').textContent = plan.bounds
    ? plan.bounds.slice(0, 2).map(round).join(', ') + ' → ' + plan.bounds.slice(2).map(round).join(', ')
    : 'Automatique';
  byId('clear-area').disabled = !plan.bounds;
  byId('hull').checked = plan.convexHull;
  byId('up').disabled = selected <= 0;
  byId('down').disabled = selected < 0 || selected >= plan.waypoints.length - 1;
  byId('remove').disabled = selected < 0;
}

function fitPlan() {
  const positions = plan.waypoints.map(latitudeLongitude);
  if (plan.bounds) positions.push(...corners(plan.bounds));
  if (positions.length) map.fitBounds(L.latLngBounds(positions), { padding: [45, 45], maxZoom: 15 });
}

function selectPoint(index, center = false) {
  selected = index;
  showPlan();
  if (center) map.panTo(latitudeLongitude(plan.waypoints[index]));
  byId('waypoint-list').children[index]?.scrollIntoView({ block: 'nearest' });
}

function movePoint(offset) {
  const next = selected + offset;
  if (selected < 0 || next < 0 || next >= plan.waypoints.length) return;
  [plan.waypoints[next], plan.waypoints[selected]] = [plan.waypoints[selected], plan.waypoints[next]];
  selectPoint(next);
}

function setMode(next) {
  mode = next;
  anchor = null;
  map.getContainer().classList.toggle('drawing', next !== 'navigate');
  document.querySelectorAll('[data-mode]').forEach(button => {
    button.setAttribute('aria-pressed', String(next === button.dataset.mode));
  });
  byId('instruction').textContent = {
    navigate: 'Déplace la carte, ou sélectionne et déplace un point.',
    point: 'Clique pour ajouter les points dans l’ordre du parcours.',
    area: 'Clique sur deux coins opposés pour fixer l’emprise.'
  }[next];
  showPlan();
}

function usePlan(newPlan, id) {
  plan = checkedPlan(newPlan);
  example = catalog.has(id) ? id : null;
  byId('example').value = example ?? '';
  selected = -1;
  setMode('navigate');
  showBackground();
  fitPlan();
}

map.on('click', event => {
  if (mode === 'navigate') return;
  const { lng, lat } = map.wrapLatLng(event.latlng);
  const point = [round(lng), round(lat)];
  if (mode === 'point') {
    plan.waypoints.push(point);
    selectPoint(plan.waypoints.length - 1);
    return;
  }
  if (!anchor) {
    anchor = point;
    byId('instruction').textContent = 'Clique sur le coin opposé.';
    showPlan();
    return;
  }
  const [west, east] = [anchor[0], point[0]].sort((a, b) => a - b);
  const [south, north] = [anchor[1], point[1]].sort((a, b) => a - b);
  if (west === east || south === north) {
    say('Choisis deux coins opposés distincts.');
    return;
  }
  plan.bounds = [west, south, east, north];
  setMode('navigate');
  say('Emprise définie.');
});

byId('layer').addEventListener('change', showBackground);
byId('new-trace').addEventListener('click', () => {
  usePlan(emptyPlan(), null);
  say('Dessine l’emprise du nouveau terrain.');
});
byId('example').addEventListener('change', event => {
  const id = event.target.value;
  if (id === '') {
    example = null;
    showBackground();
    return;
  }
  const site = catalog.get(id);
  usePlan({
    waypoints: site.waypoints.map(point => [...point]),
    bounds: [...site.bounds],
    convexHull: false
  }, id);
  say(site.label);
});
byId('center').addEventListener('submit', event => {
  event.preventDefault();
  const read = id => Number(byId(id).value.trim().replace(',', '.').replace('−', '-'));
  const longitude = read('lon');
  const latitude = read('lat');
  if (!inRange(longitude, -180, 180) || !inRange(latitude, -85, 85)) {
    say('Longitude de −180° à 180°, latitude de −85° à 85°.');
    return;
  }
  map.setView([latitude, longitude], 12);
  say('');
});
byId('fit').addEventListener('click', fitPlan);
document.querySelectorAll('[data-mode]').forEach(button => {
  button.addEventListener('click', () => setMode(button.dataset.mode));
});
byId('clear-area').addEventListener('click', () => {
  plan.bounds = null;
  anchor = null;
  showPlan();
});
byId('hull').addEventListener('change', event => { plan.convexHull = event.target.checked; });
byId('up').addEventListener('click', () => movePoint(-1));
byId('down').addEventListener('click', () => movePoint(1));
byId('remove').addEventListener('click', () => {
  if (selected < 0) return;
  plan.waypoints.splice(selected, 1);
  selected = Math.min(selected, plan.waypoints.length - 1);
  showPlan();
});

byId('save').addEventListener('click', () => {
  const file = new Blob([JSON.stringify({ format: 'sose-trace', version: 1, plan, example }, null, 2)],
    { type: 'application/json' });
  const address = URL.createObjectURL(file);
  const link = document.createElement('a');
  link.href = address;
  link.download = 'trace-sose.json';
  link.click();
  setTimeout(() => URL.revokeObjectURL(address), 1000);
  say('Tracé enregistré.');
});
byId('load').addEventListener('click', () => byId('import').click());
byId('import').addEventListener('change', async event => {
  const file = event.target.files[0];
  if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    if (!['sose-trace', 'sose-mission'].includes(data.format) || data.version !== 1) {
      throw new Error('Format de tracé SoSe inconnu.');
    }
    usePlan(data.plan, data.example);
    say('Tracé chargé.');
  } catch (error) {
    say(error.message);
  } finally {
    event.target.value = '';
  }
});

byId('apply').addEventListener('click', async () => {
  const button = byId('apply');
  button.disabled = true;
  try {
    const response = await fetch('etat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ plan, example })
    });
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message);
    }
    say('Tracé appliqué dans Pharo.');
  } catch (error) {
    say(error.message || 'Rouvre la carte depuis l’atelier.');
  } finally {
    button.disabled = false;
  }
});

function terrainStatus(message, error = false) {
  const status = byId('terrain-status');
  status.textContent = message;
  status.classList.toggle('error', error);
}

byId('save-terrain').addEventListener('click', () => {
  const site = catalog.get(example);
  byId('terrain-name').value = site?.label ?? 'Nouveau terrain';
  byId('terrain-step').value = site?.gridStep ?? terrainOptions.step;
  byId('terrain-margin').value = terrainOptions.margin;
  byId('terrain-source').value = 'copernicus';
  byId('terrain-source').querySelector('option[value="example"]').disabled = !site;
  byId('terrain-submit').disabled = false;
  byId('terrain-fields').disabled = false;
  byId('terrain-extent').textContent = (plan.bounds ? 'Emprise dessinée sur la carte' : 'Rectangle englobant le tracé') +
    ' · ' + plan.waypoints.length + ' points de passage';
  terrainStatus('Le dossier contiendra la grille du MNT et le tracé.');
  byId('terrain-dialog').showModal();
});

byId('terrain-dialog').addEventListener('cancel', event => {
  if (terrainPending) event.preventDefault();
});
byId('terrain-close').addEventListener('click', () => byId('terrain-dialog').close());

async function terrainRequest(payload) {
  const response = await fetch('terrain', payload ? {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  } : { cache: 'no-store' });
  const result = await response.json();
  if (!response.ok) throw new Error(result.message);
  return result;
}

byId('terrain-form').addEventListener('submit', async event => {
  event.preventDefault();
  if (terrainPending) return;
  const payload = {
    name: byId('terrain-name').value.trim(),
    step: byId('terrain-step').valueAsNumber,
    margin: byId('terrain-margin').valueAsNumber,
    source: byId('terrain-source').value,
    plan, example
  };
  terrainPending = true;
  byId('apply').disabled = true;
  byId('terrain-close').disabled = true;
  byId('terrain-fields').disabled = true;
  byId('terrain-submit').disabled = true;
  terrainStatus('Passe dans Pharo pour choisir le dossier de destination.');
  let saved = false;
  try {
    let result = await terrainRequest(payload);
    const job = result.id;
    while (result.state === 'pending') {
      terrainStatus(result.message);
      await new Promise(resolve => setTimeout(resolve, 800));
      result = await terrainRequest();
      if (result.id !== job) throw new Error('La session de carte a changé.');
    }
    saved = result.state === 'saved';
    terrainStatus(result.message, result.state === 'error');
    if (saved) {
      terrainOptions = { step: payload.step, margin: payload.margin };
      example = null;
      byId('example').value = '';
      showBackground();
      say(result.message);
    }
  } catch (error) {
    terrainStatus(error.message || 'Rouvre la carte depuis l’atelier.', true);
  } finally {
    terrainPending = false;
    byId('apply').disabled = false;
    byId('terrain-close').disabled = false;
    byId('terrain-fields').disabled = saved;
    byId('terrain-submit').disabled = saved;
  }
});

async function start() {
  byId('apply').disabled = true;
  try {
    const response = await fetch('etat');
    if (!response.ok) throw new Error('Rouvre la carte depuis l’atelier.');
    const state = await response.json();
    terrainOptions = state.terrainOptions;
    catalog = new Map(state.examples.map(site => [site.id, site]));
    addBasemaps(state.basemaps);
    for (const [id, site] of catalog) byId('example').append(new Option(site.label, id));
    usePlan(state.plan, state.example);
    byId('apply').disabled = false;
    byId('save-terrain').disabled = !terrainOptions;
  } catch (error) {
    say(error.message);
  }
}

start();
