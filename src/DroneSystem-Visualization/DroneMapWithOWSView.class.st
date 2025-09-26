Class {
	#name : 'DroneMapWithOWSView',
	#superclass : 'SpPresenter',
	#instVars : [
		'simulation',
		'centerLat',
		'centerLon',
		'zoom',
		'owsMap',
		'rsCanvas',
		'timeSlider',
		'fleetSelector',
		'infoText',
		'boundingBox',
		'imageSize',
		'imageWidth',
		'infoBox',
		'bitMap',
		'clusterList',
		'dronesList',
		'mapCanvas'
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
DroneMapWithOWSView class >> pixelForLat: lat lon: lon inBbox: aBbox width: widthPx height: heightPx [
    "Retourne un Point x@y en pixels dans l'image."
    |  coord xMin yMin xMax yMax xGeo yGeo xNorm yNorm xPx yPx |

    "1) projeter en WebMercator (EPSG:3857)"
    coord := self  lonLatToWebMercator: (lon @ lat).
    xGeo := coord x.
    yGeo := coord y.

    "2) extraire bbox"
    xMin := aBbox origin x.
    yMin := aBbox origin y.
    xMax := aBbox corner x.
    yMax := aBbox corner y.

    "3) normaliser (attention inversion Y pour l'image)"
    xNorm := (xGeo - xMin) / (xMax - xMin).
    yNorm := (yMax - yGeo) / (yMax - yMin).

    "Optionnel : clipper entre 0 et 1"
    xNorm := xNorm min: 1 max: 0.
    yNorm := yNorm min: 1 max: 0.

    "4) convertir en pixels"
    xPx := (xNorm * widthPx) rounded.
    yPx := (yNorm * heightPx) rounded.

    ^ xPx @ (yPx)

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
  size: 800 @ 800
  epsg: '3857'
  format: 'image/png'.

"# 'map' is a Bitmap"
]

{ #category : 'accessing' }
DroneMapWithOWSView class >> simulation: sim [

| tmp |
tmp := self basicNew simulation: sim.
tmp initialize.
^tmp 
]

{ #category : 'rendered elements' }
DroneMapWithOWSView >> bitMap [

 

	  | wms operations getmap layers map |
bitMap ifNil:[self computeBoundingBox.
	wms := OWSServiceWMS new.
	wms url: 'https://data.geopf.fr/wms-r'.
	operations := wms operations.
	getmap := operations detect: [ :request | request name = 'GetMap' ].
	getmap formats.
	layers := wms layers.

	map := wms
		       map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' "'HRL_ForestType_2018:FTY_MosaicSymbology'"}
		       bbox: self boundingBox
		       size: self imageSize
		       epsg: '3857'
		       format: 'image/png'.
	 bitMap :=  RSBitmap newFrom: map.].
 ^bitMap
]

{ #category : 'accessing' }
DroneMapWithOWSView >> boundingBox [

	boundingBox ifNil:[self computeBoundingBox].
	^ boundingBox
]

{ #category : 'accessing' }
DroneMapWithOWSView >> boundingBox: anObject [

	boundingBox := anObject
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> buildCanvas [

self setUpCanvas. 
self doSupportZoom.
self doSupportSelection.
self rsCanvas add: self bitMap.
 

 
 
^self rsCanvas 
]

{ #category : 'accessing' }
DroneMapWithOWSView >> clusterList [

	^ clusterList
]

{ #category : 'accessing' }
DroneMapWithOWSView >> clusterList: anObject [

	clusterList := anObject
]

{ #category : 'rendering' }
DroneMapWithOWSView >> computeBoundingBox [
  | borderA borderB convertedBorderA convertedBorderB latitudeMax latitudeMin longitudeMax longitudeMin tmp |
" borderA :=simulation  allFleets first allDrones first  .
 borderB := simulation  allFleets first allDrones last  ."
tmp := simulation battleZone.
latitudeMax := tmp first latitude.
latitudeMin := tmp first latitude.
longitudeMax := tmp first longitude.
longitudeMin := tmp first longitude.
tmp do:[:a|
	latitudeMax := latitudeMax max: a latitude.
	latitudeMin := latitudeMin min: a latitude.
	longitudeMax := longitudeMax max: a longitude.
	longitudeMin := longitudeMin min: a longitude.].
	
 convertedBorderA := self class lonLatToWebMercator:longitudeMin -2 @ (latitudeMax+2) .
 convertedBorderB := self class lonLatToWebMercator:longitudeMax +2 @ (latitudeMin -2) .
boundingBox := (convertedBorderA   corner: convertedBorderB) expandBy: 2.
^ boundingBox
]

{ #category : 'rendering' }
DroneMapWithOWSView >> computeImageSize [
  
   imageSize := self imageWidth @(self heightFor: self boundingBox width: self imageWidth).
^imageSize
]

{ #category : 'defaults values' }
DroneMapWithOWSView >> defaultImageWidth [

^1600
]

{ #category : 'initialization' }
DroneMapWithOWSView >> defaultLayout [ 
|   sp2 |
 
 
sp2 := self newPresenter.
 

sp2 layout: (SpBoxLayout newTopToBottom beHomogeneous;

           add: self clusterList  ;
           add: self dronesList  ;
 
 
           spacing: 1;
           yourself).
 

 
^SpBoxLayout newLeftToRight beHomogeneous; add: self mapCanvas   ; add: sp2  ; spacing:10; yourself 
  
]

{ #category : 'configuring' }
DroneMapWithOWSView >> doSupportSelection [


rsCanvas when: RSSelectionChangedEvent do: [:evt |
    | sel |
  sel := rsCanvas selectedShapes.
    Transcript show: 'Sélection : ', sel size asString; cr.
    "feedback visuel : colorer sélection"
    rsCanvas shapes do: [:s | s color: (s color alpha: 1) ]. "reset"
    sel do: [:s | s color: Color green ].
] for: self.
]

{ #category : 'configuring' }
DroneMapWithOWSView >> doSupportZoom [

			self rsCanvas
				when: RSMouseDoubleClick
				do: [ :evt | rsCanvas camera zoomToFit ]
				for: self 
]

{ #category : 'rendering' }
DroneMapWithOWSView >> drawBaseMap [

	| wms operations getmap layers map bitmapShape |
	self computeBoundingBox.
	wms := OWSServiceWMS new.
	wms url: 'https://data.geopf.fr/wms-r'.

	operations := wms operations.
	getmap := operations detect: [ :request | request name = 'GetMap' ].
	layers := wms layers.

	map := wms
		       map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
		       bbox: self boundingBox
		       size: self imageSize
		       epsg: '3857'
		       format: 'image/png'.
	rsCanvas ifNil: [
			rsCanvas := RSCanvas new.
			rsCanvas extent: imageSize.
			rsCanvas clear.
			rsCanvas @ RSCanvasController.
			rsCanvas open.
			rsCanvas
				when: RSMouseDoubleClick
				do: [ :evt | rsCanvas camera zoomToFit ]
				for: self ].
			
		"	rsCanvas when: RSMouseDown do: [:evt |
   
    selectionRect ifNotNil: [ rsCanvas remove: selectionRect ].
    selectionRect := RSBox new
        color: (Color red alpha: 0.2);
        border: (RSBorder new color: Color red);
        translateTo: evt position.
    selectionRect extent: 0@0.
   rsCanvas add: selectionRect.
    evt userData at: #start put: evt position.
].

c when: RSMouseMove do: [:evt |
    (evt buttons anySatisfy: #isPressed) ifTrue: [
        | start now |
        start := evt userData at: #start ifAbsent: [ evt position ].
        now := evt position.
        selectionRect ifNotNil: [
            selectionRect translateTo: (start min: now).
            selectionRect extent: (now - start) abs.
        ]."
    
rsCanvas when: RSSelectionChangedEvent do: [:evt |
    | sel |
  sel := rsCanvas selectedShapes.
    Transcript show: 'Sélection : ', sel size asString; cr.
    "feedback visuel : colorer sélection"
    rsCanvas shapes do: [:s | s color: (s color alpha: 1) ]. "reset"
    sel do: [:s | s color: Color green ].
] for: self.
	bitmapShape := RSBitmap newFrom: map.
	rsCanvas camera zoomToFit.
	"bitmapShape extent: size."
	rsCanvas add: bitmapShape


	"rsCanvas render."
]

{ #category : 'accessing' }
DroneMapWithOWSView >> dronesList [

	^ dronesList
]

{ #category : 'accessing' }
DroneMapWithOWSView >> dronesList: anObject [

	dronesList := anObject
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

{ #category : 'system changes' }
DroneMapWithOWSView >> fleetSelectorHasChanged [

self renderDrones 
]

{ #category : 'rendering' }
DroneMapWithOWSView >> floatingInformationBow [

infoBox := RSBox new
    size: 160@100;
    color: (Color white alpha: 0.85);
    border: (RSBorder new color: Color black);
    visible: false.
 
"--- ajouter un label dans la boîte ---"
infoBox add: (RSLabel new text: 'Sélection vide').

]

{ #category : 'rendering' }
DroneMapWithOWSView >> heightFor: aBbox width: widthPx [
    "Calcule la hauteur en pixels qui garde les proportions de la zone (BBOX)."
    | xMin xMax yMin yMax widthReal heightReal ratio |
    
    xMin := aBbox origin x.
    yMin := aBbox origin y.
    xMax := aBbox corner x.
    yMax := aBbox corner y.

    widthReal := xMax - xMin.
    heightReal := yMax - yMin.

    ratio := heightReal asFloat / widthReal asFloat.

    ^ (widthPx * ratio) rounded
]

{ #category : 'accessing' }
DroneMapWithOWSView >> imageSize [

	imageSize ifNil:[self computeImageSize].
	^ imageSize
]

{ #category : 'accessing' }
DroneMapWithOWSView >> imageSize: anObject [

	imageSize := anObject
]

{ #category : 'rendering' }
DroneMapWithOWSView >> imageWidth [

	imageWidth ifNil:[imageWidth := self defaultImageWidth].
	^imageWidth
]

{ #category : 'accessing' }
DroneMapWithOWSView >> imageWidth: anObject [

	imageWidth := anObject
]

{ #category : 'accessing' }
DroneMapWithOWSView >> infoBox [

	^ infoBox
]

{ #category : 'accessing' }
DroneMapWithOWSView >> infoBox: anObject [

	infoBox := anObject
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
DroneMapWithOWSView >> initializePresenters [ 

mapCanvas := self newRoassal canvas: self buildCanvas; yourself.
clusterList := (SpListPresenter new items: (self simulation allFleets first clusters copy add:nil;yourself); headerTitle:'Clusters'; yourself).
clusterList display:[:c| c ifNil:[''] ifNotNil:   [c clusterId printString]].
 

clusterList whenSelectionChangedDo:[    dronesList items:(clusterList selectedItem  ifNil: [ OrderedCollection new ] ifNotNil:[clusterList selectedItem drones ] ). self halt. "self renderDrones" self refresh. self visitCluster: clusterList selectedItem . mapCanvas canvas invalidate].
dronesList := (SpListPresenter new headerTitle:'Drones'; yourself).
dronesList display:[:d| d uniqueId printString].
dronesList whenSelectionChangedDo:[dronesList selectedItem inspect].
 
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

{ #category : 'system changes' }
DroneMapWithOWSView >> inspectOn: aRSShape [

"Model agnostic"
"(self infoBox shapes first) text: aRSShape model printString.
       self  infoBox translateTo: aRSShape position + (20@ -20).
       self  infoBox visible: true.
		 self rsCanvas signalUpdate "
		
	aRSShape model inspect
]

{ #category : 'system changes' }
DroneMapWithOWSView >> mapCanvas [

^mapCanvas
]

{ #category : 'system changes' }
DroneMapWithOWSView >> mapCanvas: aCanvas [

 mapCanvas := aCanvas
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap [

	^ owsMap
]

{ #category : 'accessing' }
DroneMapWithOWSView >> owsMap: anObject [

	owsMap := anObject
]

{ #category : 'rendering' }
DroneMapWithOWSView >> refresh [
	"Affiche une collection de drones sur la carte et le canvas."

	rsCanvas shapes do: [ :s |  
		"(s model isKindOf: Drone)| (s model isKindOf: DroneCluster )|(s model isKindOf: ClusterMission ) ifTrue:" s model ifNotNil:[ rsCanvas removeShape: s ] ].
 
	 
]

{ #category : 'rendering' }
DroneMapWithOWSView >> renderDrones [
    "Change le filtre d’affichage des drones selon la flotte choisie."
    self fleetSelector = 'All Fleets' ifTrue: [
        self renderDronesWith: "simulation allDrones"( clusterList selectedItem ifNil:[#()] ifNotNil:[ clusterList selectedItem drones ])].
    self fleetSelector = 'Allies' ifTrue: [
        self renderDronesWith: simulation allAlliedDrones ].
     self fleetSelector ='Hostiles' ifTrue: [
        self renderDronesWith: simulation allHostileDrones ].

]

{ #category : 'rendering' }
DroneMapWithOWSView >> renderDronesWith: droneCollection [
	"Affiche une collection de drones sur la carte et le canvas."

	rsCanvas shapes do: [ :s |  
		(s model isKindOf: Drone)| (s model isKindOf: ClusterMission ) ifTrue: [ rsCanvas removeShape: s ] ].
	droneCollection do: [ :d |
		| color dot |
		color := d isHostile
			         ifTrue: [ Color red ]
			         ifFalse: [ Color black ].
		dot := RSCircle new
			       size:  20@20;
			       color: color;
			       model: d;
			       yourself.
		"dot@ RSPopup." "popup sur clic (affiche model par défaut)"
		dot @ RSDraggable.
		rsCanvas add: dot.
		dot translateTo: (self class
				 pixelForLat: d latitude
				 lon: d longitude
				 inBbox: self boundingBox
				 width: imageSize x
				 height: imageSize y) + bitMap encompassingRectangle origin .

		"	dot
				when: RSMouseClick
				do: [ :evt |
						Transcript
							show: 'Drone cliqué à ' , dot position asString;
							cr.
						dot color: Color red.
						d inspect" "change de couleur en feedback" "]
				for: self."
		dot when: RSMouseClick do: [ :evt | self inspectOn: dot ] for: self ]
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> reset [

self rsCanvas shapes do:[:a| self rsCanvas removeShape:a]
 
]

{ #category : 'reseting' }
DroneMapWithOWSView >> resetBitMap [

bitMap := nil
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas [

	^ rsCanvas
]

{ #category : 'accessing' }
DroneMapWithOWSView >> rsCanvas: anObject [

	rsCanvas := anObject
]

{ #category : 'rendered elements' }
DroneMapWithOWSView >> setUpCanvas [

	self rsCanvas ifNil: [
			rsCanvas := RSCanvas new.
			rsCanvas extent: self bitMap extent .
			rsCanvas clear.
			rsCanvas @ RSCanvasController.
		 
			"zoom ajuste"
			rsCanvas
				when: RSMouseDoubleClick
				do: [ :evt | rsCanvas camera zoomToFit ]
				for: self ].
			
			"referme l'infobox"
			rsCanvas
				when: RSMouseClick
				do: [ :evt |     ( evt position isInsideRectangle:  self infoBox) ifFalse: [ self infoBox visible: false. rsCanvas signalUpdate ]] 
				for: self.


			"Affoche la selection"
			
			rsCanvas 
			  when: RSSelectionChangedEvent 
			  do: [:evt | | sel |
					
    				sel := rsCanvas selectedShapes.
    				Transcript show: 'Sélection : ', sel size asString; cr.
   	 				"feedback visuel : colorer sélection"
   					 rsCanvas shapes do: [:s | s color: (s color alpha: 1) ]. "reset"
    					sel do: [:s | s color: Color green ].] 
			 for: self.
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

{ #category : 'system changes' }
DroneMapWithOWSView >> update: aSimulationStep [


self renderDrones
]

{ #category : 'system changes' }
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

{ #category : 'visiting' }
DroneMapWithOWSView >> visitCluster: obj [
              | dronesShape poly   |
 


dronesShape := obj updateCoverageGeo collect:[:a |(self visitDrone:a) color:Color blue].	
obj drones do:[:a |(self visitDrone:a) ]. 
 poly := (RSPolygon new points: (dronesShape collect:[:shape| shape position])
		 ) color: (Color blue setAlpha:0.5; yourself);   model: obj; yourself.
		
rsCanvas add:   poly.
obj updateCoverageGeo do:[:a |(self visitDrone:a) color:Color black;   @ RSHighlightable red.].
obj currentMission ifNotNil:[  obj currentMission accept: self]
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitDrone: obj [

	| dot |
	dot := RSCircle new
		       size: 20@20;
		       color: (obj isHostile ifTrue: [ Color  red]  ifFalse: [Color  black]);
		       model: obj;
		       yourself.

	dot @ RSDraggable.
	rsCanvas add: dot.
	dot translateTo: (self class
			 pixelForLat: obj latitude
			 lon: obj longitude
			 inBbox: self boundingBox
			 width: imageSize x
			 height: imageSize y) + bitMap encompassingRectangle origin.

	^ dot
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitSecurizationMission: aValue [

 |pointShapes poly points |
points := ConvexHullCalculator new  convexHullGeoVerbose: aValue  polygon.
 pointShapes:= points collect:[:a| |dot| 
	dot := RSBox new
		       size: 40;
		       color:   Color  red;
		       model: a ;
		       yourself.

	dot @ RSDraggable.
	rsCanvas add: dot.
	dot translateTo: (self class
			 pixelForLat: a latitude
			 lon: a longitude
			 inBbox: self boundingBox
			 width: imageSize x
			 height: imageSize y) + bitMap encompassingRectangle origin.].

 poly := (RSPolygon new points: (pointShapes collect:[:shape| shape position])
		 ) color: (Color red setAlpha:0.5; yourself);   model: aValue; yourself.  
			rsCanvas add: poly .
		"
		self visitSurveillanceMission: aValue "
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitStrikeMission: obj [

 
 

	| dot |
	dot := RSBox new
		       size: 30;
		       color: Color red;
		       model: obj target;
		       yourself.
	dot rotateByDegrees: 45.
	dot @ RSDraggable.
	rsCanvas add: dot.
	dot translateTo: (self class
			 pixelForLat: obj latitude
			 lon: obj longitude
			 inBbox: self boundingBox
			 width: imageSize x
			 height: imageSize y) + bitMap encompassingRectangle origin.

	^ dot
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitSurveillanceMission: aValue [

 |pointShapes poly points rsEB |
points := ConvexHullCalculator new  convexHullGeoVerbose: aValue  polygon.
 pointShapes:= points collect:[:a| |dot| 
	dot := RSBox new
		       size: 40;
		       color:   Color  brown;
		       model: a ;
		       yourself.

	dot @ RSDraggable.
	rsCanvas add: dot.].
rsEB := RSEdgeBuilder verticalBezier
	color: Color red translucent;
	canvas: rsCanvas; width:40;
	"withVerticalAttachPoint;"
	noRepetition; 	useAssociations:
 ((1 to: pointShapes size)  collect:[:i| ((pointShapes at: i) model ) -> ( (pointShapes at: i % pointShapes size + 1) model )]).

	"rsCanvas add: rsEB. "
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitZoneBasedMission: obj [
              | waypoints poly |
                waypoints := obj waypoints.
                poly := (RSPolygon new points: waypoints) color: Color lightBlue.
                ^ poly  
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom [

	^ zoom
]

{ #category : 'accessing' }
DroneMapWithOWSView >> zoom: anObject [

	zoom := anObject
]
