"
""-----------------------------""
"" Scenarios convenience class""
""-----------------------------""

"
Class {
	#name : 'DroneScenarios',
	#superclass : 'Object',
	#category : 'DroneSystem-Examples',
	#package : 'DroneSystem-Examples'
}

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSecuring [
    | sim drones cluster mission polygon   |
   " sim := SimulationState new initialize." sim := nil.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8766 longitude: 2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.8366 longitude: 2.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 2.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 2 hostile: false name: 'Green').
    polygon := { { 48.88. 2.34. 100 }. { 48.87. 2.37. 100 }. { 48.84. 2.36. 100 }. }.
    mission := ClusterMission new initializeWithType: #securisation zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
"    view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open."
    ^ sim.
]

{ #category : 'as yet unclassified' }
DroneScenarios class >> exampleSurveillance [
    | sim drones cluster mission polygon   |
"    sim := SimulationState new initialize." sim := nil.
    sim setAsCurrent.
    drones := { Drone new. Drone new. Drone new } asOrderedCollection.
    (drones at: 1) moveToLatitude: 48.8566 longitude: 2.3522 altitude: 120.
    (drones at: 2) moveToLatitude: 48.8666 longitude: 2.3622 altitude: 120.
    (drones at: 3) moveToLatitude: 48.8466 longitude: 2.3422 altitude: 120.
    cluster := DroneCluster new initializeWithDrones: drones clusterId: 1.
    sim addFleet: (DroneFleet new initializeWithClusters: { cluster } id: 1 hostile: false name: 'Blue').
    polygon := { { 48.86. 2.34. 100 }. { 48.87. 2.36. 100 }. { 48.85. 2.37. 100 }. }.
    mission := ClusterMission new initializeWithType: #surveillance zoneParameters: (Dictionary new at: #polygon put: polygon; yourself).
    mission assignToCluster: cluster.
  "  view := DroneMapWithOWSView new initializeWithSimulation: sim centerLat: 48.8566 centerLon: 2.3522 zoom: 12.
    view open."
    ^ sim.

]

{ #category : 'as yet unclassified' }
DroneScenarios class >> techPoint [
   | wms operations getmap layers size map |

"Create a WMS client targeting the IGN WMS server"
wms := OWSServiceWMS new.
wms url: 'https://data.geopf.fr/wms-r'.

"Introspect the server capabilities"
operations := wms operations.
"
# 'operations' is a XMLOrderedList(
#   a OWSServiceWMSOperation <GetCapabilities>
#   a OWSServiceWMSOperation <GetMap>
#   a OWSServiceWMSOperation <GetFeatureInfo>
# )
"
"Listing available image formats for maps"
getmap := operations detect: [ :request | request name = 'GetMap' ].
getmap formats.

"# 'formats' is an OrderedCollection(
#   image/jpeg
#   image/png
#   image/tiff
#   image/geotiff
#   image/x-bil;bits=32
# )"

"Listing available layers"
layers := wms layers.

"# 'layers' is a XMLOrderedList(
#   a OWSServiceWMSLayer(ADMINEXPRESS-COG-CARTO.LATEST)
#   a OWSServiceWMSLayer(ADMINEXPRESS-COG.2017)
#   [...]
# )
"
"Download a raster map with two layers for a bounding box 
    defined by EPSG:3857 coordinates"
map := wms
  map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
  bbox: (-546079 @ 6126282 corner: -398839 @ 6212047)
  size: 800 @ 600
  epsg: '3857'
  format: 'image/png'.
"
# 'map' is a Bitmap"
]
