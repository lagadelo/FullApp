"DroneHeuristicSystem_WithHTML.st"

"Adds an interactive HTML export (Chart.js) to the existing StrategyEvaluator and calls it from the demo."

"-----------------------------"
" StrategyEvaluator: HTML export"
"-----------------------------"
StrategyEvaluator class >> exportResults: results toHTML: filePath
    "Export the given results dictionary to a standalone HTML file using Chart.js for interactive charts.
    results is expected to be a Dictionary mapping strategy-name -> metrics-dictionary.
    This method uses NeoJSON to serialize data which the HTML will load as a JS variable."
    | stream jsonString |
    jsonString := NeoJSONWriter toString: results.
    stream := FileStream forceNewFileNamed: filePath.
    stream nextPutAll: '<!doctype html>' ; cr.
    stream nextPutAll: '<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' ; cr.
    stream nextPutAll: '<title>Drone Strategy Results</title>' ; cr.
    "Chart.js from CDN"
    stream nextPutAll: '<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>' ; cr.
    stream nextPutAll: '<style>body{font-family:system-ui,Segoe UI,Roboto,Helvetica,Arial;margin:20px}h1{font-size:20px}#charts{display:flex;flex-wrap:wrap;gap:24px}canvas{background:#fff;border:1px solid #ddd;padding:8px}</style>' ; cr.
    stream nextPutAll: '</head><body>' ; cr.
    stream nextPutAll: '<h1>Drone Strategy Comparison</h1>' ; cr.
    stream nextPutAll: '<p>Interactive charts generated from the simulation results. Hover items for details; download PNG via right-click.</p>' ; cr.
    stream nextPutAll: '<div id="charts">' ; cr.
    stream nextPutAll: '<div style="width:600px"><canvas id="alliesChart"></canvas></div>' ; cr.
    stream nextPutAll: '<div style="width:600px"><canvas id="hostilesChart"></canvas></div>' ; cr.
    stream nextPutAll: '<div style="width:1200px"><canvas id="radarChart"></canvas></div>' ; cr.
    stream nextPutAll: '</div>' ; cr.
    stream nextPutAll: '<script>' ; cr.
    "Embed the JSON data as a JS variable"
    stream nextPutAll: 'const results = ' , jsonString , ';' ; cr.
    stream nextPutAll: '
function keysAndValues(obj) {
  const keys = Object.keys(obj);
  const vals = keys.map(k => obj[k]);
  return { keys, vals };
}

const strategies = Object.keys(results);
const alliesValues = strategies.map(s => results[s].alliesAlive || 0);
const hostilesValues = strategies.map(s => results[s].hostilesAlive || 0);
const fuelValues = strategies.map(s => Math.round((results[s].fuelRemaining || 0) * 100)/100);
const missionsValues = strategies.map(s => results[s].missionsCompleted || 0);

// Allies bar chart
new Chart(document.getElementById("alliesChart").getContext("2d"), {
  type: "bar",
  data: {
    labels: strategies,
    datasets: [{ label: "Allied survivors", data: alliesValues, backgroundColor: "rgba(54,162,235,0.6)" }]
  },
  options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
});

// Hostiles bar chart
new Chart(document.getElementById("hostilesChart").getContext("2d"), {
  type: "bar",
  data: {
    labels: strategies,
    datasets: [{ label: "Hostile survivors", data: hostilesValues, backgroundColor: "rgba(255,99,132,0.6)" }]
  },
  options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
});

// Radar chart: Allies vs Hostiles vs Fuel vs Missions
new Chart(document.getElementById("radarChart").getContext("2d"), {
  type: "radar",
  data: {
    labels: ["Allied survivors","Hostile survivors","Avg fuel","Missions"],
    datasets: strategies.map((s, idx) => ({
      label: s,
      data: [ alliesValues[idx], hostilesValues[idx], fuelValues[idx], missionsValues[idx] ]
    }))
  },
  options: { responsive: true, elements: { line: { tension: 0.2 } } }
});
' ; cr.
    stream nextPutAll: '</script>' ; cr.
    stream nextPutAll: '</body></html>' ; cr.
    stream close.
    ^ self.

"-----------------------------"
" Update demo to call HTML export"
"-----------------------------"
" Append a small extension method to DroneHeuristicDemo to call HTML export as part of reporting."

DroneHeuristicDemo class >> runWithAllies: nAllies hostiles: nHostiles steps: nSteps
    | sim strategies results |
    sim := SimulationState new initialize.
    sim addManyAlliedDrones: nAllies.
    sim addManyHostileDrones: nHostiles.
    sim assignDefaultMissions.

    strategies := {
        ProactiveInterceptionStrategy new.
        AdaptiveEnergyStrategy new.
        DivideAndSurroundStrategy new.
        PriorityDefenseStrategy new.
        LearningBasedStrategy new }.

    results := StrategyEvaluator
        compareStrategies: strategies
        onSimulation: sim
        forSteps: nSteps.

    StrategyEvaluator exportResults: results toCSV: 'strategies.csv'.
    StrategyEvaluator saveVisualization: results toPNG: 'strategies.png'.
    StrategyEvaluator exportResults: results toJSON: 'strategies.json'.
    StrategyEvaluator exportResults: results toHTML: 'strategies.html'.
    StrategyEvaluator exportLog: results allies: nAllies hostiles: nHostiles steps: nSteps toFile: 'simulation.log'.
    StrategyEvaluator summarizeResults: results.
    ^ results.
