Class {
	#name : 'DroneMapWithOWSView',
	#superclass : 'Object',
	#instVars : [
		'simulation',
		'centerLat',
		'centerLon',
		'zoom',
		'owsMap',
		'rsCanvas',
		'timeSlider',
		'fleetSelector',
		'infoText'
	],
	#category : 'DroneSystem-Visualization-visualization',
	#package : 'DroneSystem-Visualization',
	#tag : 'visualization'
}

{ #category : 'convertion' }
DroneMapWithOWSView class >> lonLatToWebMercator: latlon [
    | lon lat x y   |

    lon := latlon x.
    lat := latlon y.

    x := lon * 20037508.34 / 180.

     
   y := (lat /360+0.25*Float pi ) tan ln * 6378137.

    ^ x @ y
]

{ #category : 'accessing' }
DroneMapWithOWSView class >> openOnSimulation: sim [

^(self  simulation: sim) open; yourself
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView class >> referenceCodeFromThales [
 | wms operations getmap layers size map |

"Create a WMS client targeting the IGN WMS server"
wms := OWSServiceWMS new.
wms url: 'https://data.geopf.fr/wms-r'.

"Introspect the server capabilities"
operations := wms operations.

"# 'operations' is a XMLOrderedList(
#   a OWSServiceWMSOperation <GetCapabilities>
#   a OWSServiceWMSOperation <GetMap>
#   a OWSServiceWMSOperation <GetFeatureInfo>
# )"

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

"# 'map' is a Bitmap"
]

{ #category : 'accessing' }
DroneMapWithOWSView class >> simulation: sim [

^self new simulation: sim; yourself
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLat [

	^ centerLat
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLat: anObject [

	centerLat := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLon [

	^ centerLon
]

{ #category : 'accessing' }
DroneMapWithOWSView >> centerLon: anObject [

	centerLon := anObject
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> drawBaseMap [
    | wms operations getmap layers size map bitmapShape  center x y borderA borderB convertedBorderA onvertedBorderB convertedBorderB |
  borderA :=simulation  allFleets first drones first  .
borderB := simulation  allFleets first drones last  .
   convertedBorderA := self class lonLatToWebMercator:borderA longitude @ borderA latitude .
convertedBorderB := self class lonLatToWebMercator:borderB longitude @ borderB latitude .
 

    wms := OWSServiceWMS new.
    wms url: 'https://data.geopf.fr/wms-r'.

    operations := wms operations.
    getmap := operations detect: [:request | request name = 'GetMap'].
    layers := wms layers.
    size := 1000 @ 700.

    map := wms
        map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
        bbox: (convertedBorderA    corner: convertedBorderB )
"example -546079 @ 6126282 corner: -398839 @ 6212047"
        size: size
        epsg: '3857'
        format: 'image/png'.
    rsCanvas ifNil:[rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700. 
    rsCanvas clear. rsCanvas open].
    bitmapShape := RSBitmap newFrom: map.
    "bitmapShape extent: size."
    rsCanvas add: bitmapShape.
    "rsCanvas render."
]

{ #category : 'accessing' }
DroneMapWithOWSView >> fleetSelector [
fleetSelector ifNil:[fleetSelector := 'All Fleets'].
	^ fleetSelector
]

{ #category : 'accessing' }
DroneMapWithOWSView >> fleetSelector: anObject [

	fleetSelector := anObject.
	self fleetSelectorHasChanged
]

{ #category : 'accessing' }
DroneMapWithOWSView >> fleetSelectorHasChanged [

self renderDrones 
]

{ #category : 'accessing' }
DroneMapWithOWSView >> infoText [

	^ infoText
]

{ #category : 'accessing' }
DroneMapWithOWSView >> infoText: anObject [

	infoText := anObject
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeWithSimulation: aSimulation centerLat: lat centerLon: lon zoom: z [
    simulation := aSimulation.
    centerLat := lat.
    centerLon := lon.
    zoom := z.

    "Si PharoOWS est présent, configurer une carte OWS"
    (Smalltalk includesKey: #OWSServiceWMS)
        ifTrue: [
            owsMap := (Smalltalk at: #OWSMapView) new.
            (owsMap respondsTo: #center:) ifTrue: [ owsMap center: lat @ lon ].
            (owsMap respondsTo: #zoom:) ifTrue: [ owsMap zoom: z ].
        ]
        ifFalse: [ owsMap := nil ].

    "Créer un canvas Roassal pour superposer les drones"
    rsCanvas := RSCanvas new.
    rsCanvas extent: 1000@700.
	self drawBaseMap.
    "Installer le HUD fourni par le trait"
  "  self initializeHUD."

    ^ self
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> open [

self drawBaseMap; renderDrones 
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap [

	^ owsMap
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap: anObject [

	owsMap := anObject
]

{ #category : 'initialization' }
DroneMapWithOWSView >> renderDrones [
    "Change le filtre d’affichage des drones selon la flotte choisie."
    self fleetSelector = 'All Fleets' ifTrue: [
        self renderDronesWith: simulation allDrones ].
    self fleetSelector = 'Allies' ifTrue: [
        self renderDronesWith: simulation allAlliedDrones ].
     self fleetSelector ='Hostiles' ifTrue: [
        self renderDronesWith: simulation allHostileDrones ].

]

{ #category : 'rendering' }
DroneMapWithOWSView >> renderDronesWith: droneCollection [
    "Affiche une collection de drones sur la carte et le canvas."
    rsCanvas shapes do: [:s | (s isKindOf: RSCircle) ifTrue: [ rsCanvas remove: s ]].
    droneCollection do: [:d |
        | color dot |
        color := d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ].
        dot := RSCircle new
            size: 8@8;
            color: color;
            yourself.
        rsCanvas add: dot.
        dot translateTo: (d longitude * 5) @ (d latitude * -5). "Projection simplifiée"
    ].
    rsCanvas signalUpdate.
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas [

	^ rsCanvas
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas: anObject [

	rsCanvas := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> simulation [

	^ simulation
]

{ #category : 'accessing' }
DroneMapWithOWSView >> simulation: anObject [

	simulation := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> timeSlider [

	^ timeSlider
]

{ #category : 'accessing' }
DroneMapWithOWSView >> timeSlider: anObject [

	timeSlider := anObject
]

{ #category : 'initialization' }
DroneMapWithOWSView >> updateAtStep: step [
    "Met à jour la simulation et l'affichage à l'instant donné."
    simulation stepAt: step.
	 self renderDrones.
    infoText text: 'Time step: ', step asString, ' | Active fleets: ', simulation allFleets size asString.

]

{ #category : 'initialization' }
DroneMapWithOWSView >> updateFleetFilter: choice [
    "Change le filtre d’affichage des drones selon la flotte choisie."
    choice = 'All Fleets' ifTrue: [
        self renderDronesWith: simulation allDrones ].
    choice = 'Allies' ifTrue: [
        self renderDronesWith: simulation allAlliedDrones ].
    choice = 'Hostiles' ifTrue: [
        self renderDronesWith: simulation allHostileDrones ].

]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom [

	^ zoom
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom: anObject [

	zoom := anObject
]
