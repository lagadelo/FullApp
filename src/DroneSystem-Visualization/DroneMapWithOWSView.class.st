"
This class is the GUI of SimulationState
"
Class {
	#name : 'DroneMapWithOWSView',
	#superclass : 'SpPresenter',
	#instVars : [
		'simulation',
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
		'mapCanvas',
		'toolBar',
		'menuBar'
	],
	#category : 'DroneSystem-Visualization-visualization',
	#package : 'DroneSystem-Visualization',
	#tag : 'visualization'
}

{ #category : 'converting' }
DroneMapWithOWSView class >> latLonForPixel: aPoint inBbox: aBbox width: widthPx height: heightPx [
    "Retourne une coordonnée lon@lat pour un point pixel donné dans l’image."
    | xPx yPx xMin yMin xMax yMax xNorm yNorm xGeo yGeo coord   |

    xPx := aPoint x asFloat.
    yPx := aPoint y asFloat.

    "1) Extraire le bounding box (en WebMercator)"
    xMin := aBbox origin x.
    yMin := aBbox origin y.
    xMax := aBbox corner x.
    yMax := aBbox corner y.

    "2) Convertir les pixels en coordonnées normalisées"
    xNorm := xPx / widthPx.
    yNorm := yPx / heightPx.

    "3) Calculer les coordonnées WebMercator"
    xGeo := xNorm * (xMax - xMin) + xMin.
    yGeo := yMax - (yNorm * (yMax - yMin)). "Inversion Y"

    "4) Convertir WebMercator vers lon/lat"
    coord := self webMercatorToLonLat: (xGeo @ yGeo).
    ^ coord  "lon @ lat"
]

{ #category : 'converting' }
DroneMapWithOWSView class >> lonLatToWebMercator: aCoord [
    | lon lat radius x y latRad |
 
    radius := 6378137.0.
    lon := aCoord x.
    lat := aCoord y.
    latRad := lat * Float pi / 180.0.
    x := lon * Float pi / 180.0 * radius.
    y := radius * ((Float pi / 4.0 + (latRad / 2.0)) tan ln).
    ^ x @ y
]

{ #category : 'accessing' }
DroneMapWithOWSView class >> openOnSimulation: sim [

^(self  simulation: sim) open; yourself
]

{ #category : 'converting' }
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

{ #category : 'baselines - legacy' }
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

{ #category : 'converting' }
DroneMapWithOWSView class >> webMercatorToLonLat: aPoint [
    | x y lon lat radius |
    radius := 6378137.0.
    x := aPoint 	x.
    y := aPoint y.
    lon := (x / radius) * 180.0 / Float pi.
    lat := ((2.0 * (y / radius)  exp  arcTan) - (Float pi / 2.0)) * 180.0 / Float pi.
    ^ lon @ lat
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

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> boundingBox [

	boundingBox ifNil:[self computeBoundingBox].
	^ boundingBox
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> boundingBox: anObject [

	boundingBox := anObject
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> buildCanvas [

self setUpCanvas. 
self doSupportZoom.
self doSupportSelection.
self rsCanvas add: self bitMap.
 

 
 
^self rsCanvas 
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> clusterList [

	^ clusterList
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> clusterList: anObject [

	clusterList := anObject
]

{ #category : 'rendering' }
DroneMapWithOWSView >> computeBoundingBox [

	| convertedBorderA convertedBorderB latitudeMax latitudeMin longitudeMax longitudeMin tmp |
	tmp := simulation battleZone.
	latitudeMax := tmp first latitude.
	latitudeMin := tmp first latitude.
	longitudeMax := tmp first longitude.
	longitudeMin := tmp first longitude.
	tmp do: [ :a |
		latitudeMax := latitudeMax max: a latitude.
		latitudeMin := latitudeMin min: a latitude.
		longitudeMax := longitudeMax max: a longitude.
		longitudeMin := longitudeMin min: a longitude ].

	convertedBorderA := self class lonLatToWebMercator:
		                    longitudeMin - 2 @ (latitudeMax + 2).
	convertedBorderB := self class lonLatToWebMercator:
		                    longitudeMax + 2 @ (latitudeMin - 2).
	boundingBox := (convertedBorderA corner: convertedBorderB) expandBy:
		               2.
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

{ #category : 'layout' }
DroneMapWithOWSView >> defaultLayout [

	| sp2   |
"	sp2 := self newPresenter."
"

	sp2 layout: "
	
	sp2 :=  
	(SpBoxLayout newTopToBottom
			" beHomogeneous;"
 add:   toolBar expand:false;
			 add: self clusterList;
			 add: self dronesList;
			 spacing: 1;
			 yourself).
	"sp1 := SpBoxLayout newTopToBottom spacing: 5; add:   toolBar expand:false; add: sp2."
	


	^ SpBoxLayout newLeftToRight
		  beHomogeneous;
		  add: self mapCanvas;
		  add: sp2;
		  spacing: 10;
		  yourself
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

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> dronesList [

	^ dronesList
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> dronesList: anObject [

	dronesList := anObject
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> fleetSelector [
fleetSelector ifNil:[fleetSelector := 'All Fleets'].
	^ fleetSelector
]

{ #category : 'accessing - widgets' }
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

{ #category : 'convertion' }
DroneMapWithOWSView >> graphicalPositionOf: obj [

(self class
			 pixelForLat: obj latitude
			 lon: obj longitude
			 inBbox: self boundingBox
			 width: imageSize x
			 height: imageSize y) + bitMap encompassingRectangle origin.
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

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> imageSize [

	imageSize ifNil:[self computeImageSize].
	^ imageSize
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> imageSize: anObject [

	imageSize := anObject
]

{ #category : 'rendering' }
DroneMapWithOWSView >> imageWidth [

	imageWidth ifNil:[imageWidth := self defaultImageWidth].
	^imageWidth
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> imageWidth: anObject [

	imageWidth := anObject
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> infoBox [

	^ infoBox
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> infoBox: anObject [

	infoBox := anObject
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> infoText [

	^ infoText
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> infoText: anObject [

	infoText := anObject
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeCanvas [

	mapCanvas := self newRoassal
		             canvas: self buildCanvas;
		             yourself
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeClusterList [

	clusterList := SpListPresenter new
		               items:
			               (self simulation allFleets first clusters copy
				                add: nil;
				                yourself);
		               headerTitle: 'Clusters';
		               yourself.
	clusterList display: [ :c |
		c ifNil: [ '' ] ifNotNil: [ c clusterId printString ] ].
	clusterList whenSelectionChangedDo: [
		dronesList items: (clusterList selectedItem
				 ifNil: [ OrderedCollection new ]
				 ifNotNil: [ clusterList selectedItem drones ]).
		self refresh.
		self visitCluster: clusterList selectedItem.
		mapCanvas canvas invalidate ]
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeDronesList [

	dronesList := SpListPresenter new
		              headerTitle: 'Drones';
		              yourself.
	dronesList display: [ :d | d uniqueId printString ].
	dronesList whenSelectionChangedDo: [ dronesList selectedItem inspect ]
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeMenuBar [
  menuBar := self newMenuBar
    addItem: [ :item |
      item
        name: 'Simulation';
		  subMenu: self simulationMenu;
               yourself ];
           addItem: [ :item |
             item
               name: 'View'";
               subMenu: self viewMenu";
               yourself ];
           addItem: [ :item |
             item
               name: 'Inspect'";
               subMenu: self inspectMenu";
               yourself ];
yourself
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializePresenters [
 

	self initializeCanvas.
	self initializeDronesList.
	self initializeClusterList.
	self initializeToolbar
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeToolbar [

	toolBar := self newToolbar
		           addItem: (SpToolbarButtonPresenter new
				            label: 'Ok';
				            icon: (self iconNamed: #glamorousGo);
				            help: 'Ok';
				            action: [ toolBar inform: 'Start' ];
				            yourself);
		           addItem: (SpToolbarButtonPresenter new
				            label: 'Pause';
				            icon: (self iconNamed: #pause);
				            help: 'Step by step';
				            action: [ simulation step ];
				            addItem: (SpToolbarButtonPresenter new
						             label: 'Step';
						             icon: (self iconNamed: #play);
						             help: 'Step by step';
						             action: [ toolBar inform: 'stop' ];
						             yourself);
				            addItem: (SpToolbarButtonPresenter new
						             label: 'Cancel';
						             icon: (self iconNamed: #stop);
						             help: 'stop';
						             action: [ toolBar inform: 'stop' ];
						             yourself))
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeWindow: aWindowPresenter [
  aWindowPresenter
    title: 'Simulator';
    initialExtent: 3000@2000;
    menu: menuBar
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

{ #category : 'actions' }
DroneMapWithOWSView >> loadSimulation [

Transcript show: 'Load Simulation';cr
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

{ #category : 'convertion' }
DroneMapWithOWSView >> physicalPositionOf: position [

	^ self class
		  latLonForPixel:
		  (position    "* rsCanvas extent x / bitMap encompassingRectangle origin x negated " )  - bitMap encompassingRectangle origin
		  inBbox: self boundingBox
		  width: imageSize x
		  height: imageSize y
	 
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

{ #category : 'accessing - widgets' }
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
    				Transcript show: 'Sélection : '; show: sel size asString; cr.
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

{ #category : 'initialization' }
DroneMapWithOWSView >> simulationMenu [
         "Empty placeholder Not defined in this chapter"
         ^ self newMenu
addGroup:[:group | group 
	      addItem: [ :item | item name: 'Start'; shortcut: $s meta;
            action: [ self startSimulation ] ];
             addItem: [ :item | item name: 'Step' ; shortcut: $n meta;
            action: [ self stepSimulation ]];
             addItem: [ :item | item name: 'Stop' ; shortcut: $h meta;
            action: [ self stopSimulation ]]];
 addGroup:[:group | group            addItem: [ :item | item name: 'Save' ; shortcut: $wn meta;
            action: [ self storeSimulation ] ];
             addItem: [ :item | item name: 'Load'; shortcut: $r meta;
            action: [ self loadSimulation ] ]];
             yourself
]

{ #category : 'actions' }
DroneMapWithOWSView >> startSimulation [

Transcript show: 'Start Simulation';cr
]

{ #category : 'actions' }
DroneMapWithOWSView >> stepSimulation [

Transcript show: 'Step Simulation';cr
]

{ #category : 'actions' }
DroneMapWithOWSView >> stopSimulation [

Transcript show: 'Stop Simulation';cr
]

{ #category : 'actions' }
DroneMapWithOWSView >> storeSimulation [

Transcript show: 'Store Simulation';cr
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> timeSlider [

	^ timeSlider
]

{ #category : 'accessing - widgets' }
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
DroneMapWithOWSView >> updateModelPositionOf: evt [

" Update latitude and longitude of model, keeping constant the altitude.
eg. After a drag/drop operation"

|p|

	p := self physicalPositionOf:   evt  positionFromCamera  .
	(self class
			 pixelForLat: evt shape model latitude
			 lon: evt shape model  longitude
			 inBbox: self boundingBox
			 width: imageSize x
			 height: imageSize y) + bitMap encompassingRectangle origin.
	evt shape  model longitude: p x. evt shape   model latitude: p y.
	"evt shape size: 40@40; translateTo: evt position.
	rsCanvas invalidate."
]

{ #category : 'visiting' }
DroneMapWithOWSView >> visitCluster: obj [
              | dronesShape poly   dronesOnConvexHull internalDrones  |
 

dronesOnConvexHull := obj updateCoverageGeo.
internalDrones := obj drones reject:[:d| dronesOnConvexHull includes: d].

dronesShape := dronesOnConvexHull collect:[:a | |shape|  shape := (self visitDrone:a). shape  color:Color blue; size:30@30;@ RSHighlightable red.
shape when: RSMouseDragEnd do:[:evt| "self halt. "self updateModelPositionOf: evt.  rsCanvas   invalidate.  ] for: self. shape].
						"referme l'infobox"
		internalDrones do:[:a |(self visitDrone:a) ]. 
 poly := (RSPolygon new points: (dronesShape collect:[:shape| shape position])
		 ) color: (Color blue setAlpha:0.5; yourself);   model: obj; yourself.
		
rsCanvas add:   poly.
"obj updateCoverageGeo do:[:a |(self visitDrone:a) color:Color black;   @ RSHighlightable red.]."
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
		       color:   Color  brown;
				 rotateByDegrees: 45;
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
