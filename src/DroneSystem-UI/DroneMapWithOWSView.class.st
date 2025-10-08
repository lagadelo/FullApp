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
		'menuBar',
		'overlayModel',
		'onWaypointsCommittedBlock',
		'waypointInputMode',
		'pendingWaypoints',
		'baseMapDirty',
		'centerLat',
		'centerLon',
		'zoom',
		'overlayPanel',
		'waypointStartBtn',
		'waypointCommitBtn',
		'waypointClearBtn',
		'overlayPerceptionCB',
		'overlayMissionCB',
		'overlayEnergyCB',
		'overlayAmmoCB',
		'overlayHullCB'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
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

{ #category : 'reseting' }
DroneMapWithOWSView >> addAmmoBarShapesTo: aCanvas [
    (simulation respondsTo: #drones) ifFalse: [ ^ self ].
    simulation drones do: [ :d |
        (d respondsTo: #ammunition) ifTrue: [
            | p ratio barW cap filled rect frame |
            p := self graphicalPositionOf: d position.
            p ifNil: [ ^ self ].
            barW := 34.
            cap := 10.
            ratio := ((d ammunition min: cap) / cap) max: 0.0.
            filled := (barW * ratio) max: 1.
            rect := RSBox new
                width: filled;
                height: 5;
                position: (p x - (barW / 2) @ (p y + 18));
                color: (Color orange alpha: 0.75);
                yourself.
            rect attributeAt: #overlay put: true.
            frame := RSBox new
                width: barW;
                height: 5;
                position: (p x - (barW / 2) @ (p y + 18));
                noFill;
                color: Color black;
                yourself.
            frame attributeAt: #overlay put: true.
            aCanvas add: rect; add: frame ] ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> addClusterHullShapesTo: aCanvas [
         | hullCalc geoPoints hull pts poly |
   (simulation respondsTo: #clusters) ifFalse: [ ^ self ].
  
    hullCalc := ConvexHullCalculator new.
    simulation clusters do: [ :cluster |
        (cluster respondsTo: #drones) ifFalse: [ ^ self ].
   
        geoPoints := cluster drones
            collect: [ :d | (d respondsTo: #position) ifTrue: [ d position ] ifFalse: [ nil ] ]
            thenSelect: [ :gp | gp notNil ].
        geoPoints size > 2 ifTrue: [
            hull := hullCalc hullForGeoPoints: geoPoints.
            hull size > 2 ifTrue: [
                pts := hull
                    collect: [ :g | self graphicalPositionOf: g ]
                    thenSelect: [ :p | p notNil ].
                pts size > 2 ifTrue: [
                    poly := RSPolygon new
                        points: pts;
                        color: (Color red alpha: 0.08);
                        borderColor: (Color red alpha: 0.4);
                        borderWidth: 1;
                        yourself.
                    poly attributeAt: #overlay put: true.
                    aCanvas add: poly ] ] ] ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> addEnergyBarShapesTo: aCanvas [
    (simulation respondsTo: #drones) ifFalse: [ ^ self ].
    simulation drones do: [ :d |
        (d respondsTo: #energy) ifTrue: [
            | p ratio barW filled rect frame |
            p := self graphicalPositionOf: d position.
            p ifNil: [ ^ self ].
            barW := 34.
            ratio := ((d energy max: 0) / 1000.0) min: 1.0.
            filled := (barW * ratio) max: 1.
            rect := RSBox new
                width: filled;
                height: 5;
                position: (p x - (barW / 2) @ (p y + 10));
                color: (Color green alpha: 0.75);
                yourself.
            rect attributeAt: #overlay put: true.
            frame := RSBox new
                width: barW;
                height: 5;
                position: (p x - (barW / 2) @ (p y + 10));
                noFill;
                color: Color black;
                yourself.
            frame attributeAt: #overlay put: true.
            aCanvas add: rect; add: frame ] ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> addMissionPathShapesTo: aCanvas [
    (simulation respondsTo: #missions) ifFalse: [ ^ self ].
    simulation missions do: [ :m |
        (m respondsTo: #waypoints) ifTrue: [
            | pts path lineColor |
            pts := m waypoints
                collect: [ :wp | self graphicalPositionOf: wp ]
                thenSelect: [ :p | p notNil ].
            pts size > 1 ifTrue: [
                lineColor := Color yellow alpha: 0.7.
                path := RSPolyline new
                    points: pts;
                    color: lineColor;
                    width: 1;
                    yourself.
                path attributeAt: #overlay put: true.
                aCanvas add: path ] ] ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> addPerceptionRadiusShapesTo: aCanvas [
    (simulation respondsTo: #drones) ifFalse: [ ^ self ].
    simulation drones do: [ :d |
        | range center circle pxRadius |
        (d respondsTo: #detectionRange) ifFalse: [ ^ self ].
        range := d detectionRange.
        (range isNil or: [ range <= 0 ]) ifTrue: [ ^ self ].
        center := self graphicalPositionOf: d position.
        center ifNil: [ ^ self ].
        pxRadius := range * ((self respondsTo: #scaleFactor) ifTrue: [ self scaleFactor ] ifFalse: [ 1 ]).
        circle := RSCircle new
            radius: pxRadius;
            position: center;
            color: (Color lightBlue alpha: 0.12);
            borderColor: (Color lightBlue alpha: 0.35);
            yourself.
        circle attributeAt: #overlay put: true.
        aCanvas add: circle ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> addWaypointMarkerFor: aWaypoint [
    | p shape |
    p := self graphicalPositionOf: aWaypoint.
    p ifNil: [ ^ self ].
    shape := RSCircle new
        radius: 5;
        color: Color red;
        model: aWaypoint;
        yourself.
    shape attributeAt: #overlay put: true.
    rsCanvas add: shape.
    shape translateTo: p
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> applyLayout [
    "Applique un layout: carte large à gauche, panneau (overlayPanel) étroit à droite."
    mapCanvas ifNil: [ self error: 'mapCanvas non initialisé' ].
    overlayPanel ifNil: [ self error: 'overlayPanel non initialisé' ].
    self layout: (SpBoxLayout newLeftToRight
        spacing: 10;
        add: mapCanvas expand: true;
        add: overlayPanel expand: false;
        yourself)
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

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> buildCanvas [

self setUpCanvas. 
self doSupportZoom.
self doSupportSelection.
self rsCanvas add: self bitMap.
 

 
 
^self rsCanvas 
]

{ #category : 'reseting' }
DroneMapWithOWSView >> buildClusterAndDroneLists [
    clusterList := SpListPresenter new
        headerTitle: 'Clusters';
        items: self initialClusterItems;
        yourself.
    clusterList display: [ :c | c ifNil: [ '' ] ifNotNil: [ c clusterId printString ] ].
    clusterList whenSelectionChangedDo: [ self onClusterSelectionChanged ].

    dronesList := SpListPresenter new
        headerTitle: 'Drones';
        yourself.
    dronesList display: [ :d | d uniqueId printString ].
    dronesList whenSelectionChangedDo: [ dronesList selectedItem ifNotNil: [:dr | dr inspect ] ]

]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> buildOverlayPanel [
    | overlaysBox waypointBox listsBox rightStack |
    self initializeOverlayModelIfNeeded.
    self buildToolBar.

    overlaysBox := self newPresenter.
    overlaysBox layout: (SpBoxLayout newTopToBottom
        spacing: 2;
        add: (SpLabelPresenter new label: 'Overlays');
        add: (self overlayCheckBox: #overlayPerceptionCB label: 'Perception'    getter: #showPerceptionRadius setter: #showPerceptionRadius:);
        add: (self overlayCheckBox: #overlayMissionCB    label: 'Missions'      getter: #showMissionPaths       setter: #showMissionPaths:);
        add: (self overlayCheckBox: #overlayEnergyCB     label: 'Fuel'          getter: #showEnergyBars         setter: #showEnergyBars:);
        add: (self overlayCheckBox: #overlayAmmoCB       label: 'Ammo'          getter: #showAmmoBars           setter: #showAmmoBars:);
        add: (self overlayCheckBox: #overlayHullCB       label: 'Cluster Hull'  getter: #showClusterHull        setter: #showClusterHull:);
        yourself).

    waypointBox := self newPresenter.
    waypointBox layout: (SpBoxLayout newTopToBottom
        spacing: 2;
        add: (SpLabelPresenter new label: 'Waypoints');
        add: (waypointStartBtn ifNotNil:[waypointStartBtn] ifNil: [
            waypointStartBtn := SpButtonPresenter new label: 'Capture'; action: [ self startWaypointCapture ] ]);
        add: (waypointCommitBtn ifNotNil:[waypointCommitBtn]  ifNil: [
	waypointCommitBtn := SpButtonPresenter new label: 'Commit'; action: [ self commitPendingWaypoints ] ]);
        add: (waypointClearBtn ifNotNil:[waypointClearBtn]  ifNil: [
            waypointClearBtn := SpButtonPresenter new label: 'Clear'; action: [ self clearPendingWaypoints ] ]);
        yourself).

    listsBox := self newPresenter.
    listsBox layout: (SpBoxLayout newTopToBottom
        spacing: 4;
        add: (SpLabelPresenter new label: 'Entities');
        add: clusterList;
        add: dronesList;
        yourself).

    rightStack := self newPresenter.
    rightStack layout: (SpBoxLayout newTopToBottom
        spacing: 6;
        add: toolBar expand: false;
        add: overlaysBox;
        add: waypointBox;
        add: listsBox;
        yourself).

    overlayPanel := rightStack
 
 
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> buildToolBar [
    toolBar ifNotNil: [ ^ toolBar ].
    toolBar := SpBoxLayout newLeftToRight
        spacing: 4;
        add: (SpButtonPresenter new
            label: 'Reload';
            action: [ self markBaseMapDirty. self refreshAll ]);
        add: (SpButtonPresenter new
            label: 'Overlays ON';
            action: [
                overlayModel
                    showPerceptionRadius: true;
                    showMissionPaths: true;
                    showEnergyBars: true;
                    showAmmoBars: true;
                    showClusterHull: true.
                self refreshOverlays ]);
        add: (SpButtonPresenter new
            label: 'Overlays OFF';
            action: [
                overlayModel
                    showPerceptionRadius: false;
                    showMissionPaths: false;
                    showEnergyBars: false;
                    showAmmoBars: false;
                    showClusterHull: false.
                self refreshOverlays ]);
        add: (SpButtonPresenter new
            label: 'Capture WP';
            action: [ self startWaypointCapture ]);
        add: (SpButtonPresenter new
            label: 'Commit WP';
            action: [ self commitPendingWaypoints ]);
        add: (SpButtonPresenter new
            label: 'Clear WP';
            action: [ self clearPendingWaypoints ]);
        yourself
]

{ #category : 'accessing' }
DroneMapWithOWSView >> canvas [
"Legacy - Should refactor"
	^ rsCanvas
]

{ #category : 'reseting' }
DroneMapWithOWSView >> clearPendingWaypoints [
    pendingWaypoints ifNotNil: [ pendingWaypoints removeAll ].
    self refreshOverlays
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> clusterList [

	^ clusterList
]

{ #category : 'accessing - widgets' }
DroneMapWithOWSView >> clusterList: anObject [

	clusterList := anObject
]

{ #category : 'reseting' }
DroneMapWithOWSView >> commitPendingWaypoints [
    (pendingWaypoints isNil or: [ pendingWaypoints isEmpty ]) ifTrue: [ ^ self ].
    onWaypointsCommittedBlock ifNotNil: [ onWaypointsCommittedBlock value: pendingWaypoints copy ].
    self disableWaypointInput
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

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> defaultLayout [
    "Spec va appeler ceci. Pas de bloc; juste un SpBoxLayout.
    Si ta version exige un bloc → dé-commente defaultLayoutBlock ci-dessous."
    mapCanvas ifNil: [ self error: 'mapCanvas non initialisé (initializePresenters non appelé)' ].
    overlayPanel ifNil: [ self error: 'overlayPanel non initialisé (initializePresenters non appelé)' ].
    ^ SpBoxLayout newLeftToRight
        spacing: 10;
        add: mapCanvas;
        add: overlayPanel;
        yourself
]

{ #category : 'reseting' }
DroneMapWithOWSView >> defaultLayoutBlock [
    "Retourne le bloc que Spec évaluera (et non un layout direct)."
    ^ [ :p |
        mapCanvas ifNil: [ self error: 'mapCanvas nil au moment du layout' ].
        overlayPanel ifNil: [ self error: 'overlayPanel nil au moment du layout' ].
        SpBoxLayout newLeftToRight
            spacing: 10;
            add: mapCanvas;
            add: overlayPanel;
            yourself ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> disableWaypointInput [
    waypointInputMode := false.
    self redraw
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

{ #category : 'reseting' }
DroneMapWithOWSView >> enableWaypointInput [
    waypointInputMode := true.
    pendingWaypoints ifNil: [ pendingWaypoints := OrderedCollection new ].
    self redraw
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
DroneMapWithOWSView >> initialClusterItems [
    | fleets |
    simulation ifNil: [ ^ #() ].
    (simulation respondsTo: #allFleets) ifFalse: [ ^ #() ].
    fleets := simulation allFleets.
    fleets isEmpty ifTrue: [ ^ #() ].
    ^ ((fleets first clusters copy) add: nil; yourself)
]

{ #category : 'rendering' }
DroneMapWithOWSView >> initialize [
  "  super initialize."
   " baseMapDirty := true.
    pendingWaypoints := OrderedCollection new.
    waypointInputMode := false"
]

{ #category : 'reseting' }
DroneMapWithOWSView >> initializeOverlayModelIfNeeded [
    overlayModel ifNil: [
        overlayModel := DroneOverlayModel new
            showPerceptionRadius: true;
            showMissionPaths: true;
            showEnergyBars: true;
            showAmmoBars: false;
            showClusterHull: true;
            yourself ]
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> initializePresenters [
    "Construit seulement les presenters; ne touche pas au layout."
     self initializeOverlayModelIfNeeded.
    mapCanvas ifNil: [
        mapCanvas := self newRoassal
            canvas: self buildCanvas;
            yourself ].
    self buildClusterAndDroneLists.
    self buildOverlayPanel
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeWindow: aWindowPresenter [
  aWindowPresenter
    title: 'Simulator';
    initialExtent: 3000@2000;
    menu: menuBar
]

{ #category : 'initialization' }
DroneMapWithOWSView >> initializeWithSimulation: aSimulation centerLat: lat centerLon: lon zoom: z [
    "Initialisation sans gestion de centrage OWS (pas de OWSServiceWMS).
    lat / lon / z sont acceptés mais non utilisés pour configurer une carte serveur."
    simulation := aSimulation.
    "Les paramètres reçus ne sont pas exploités (pas de moteur de centrage)."
    centerLat := lat.
    centerLon := lon.
    zoom := z.

    "Prépare la zone et la taille d’image à partir du modèle (battleZone)."
    self computeBoundingBox.
    self computeImageSize.

    "Canvas Roassal."
    rsCanvas := RSCanvas new.
    rsCanvas extent: self imageSize.
    self setUpCanvas.

    "Fond (WMS local ou déjà implémenté dans #drawBaseMap / #bitMap)."
    self drawBaseMap.

    "Présenters (listes clusters / drones)."
    self initializePresenters.

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

{ #category : 'reseting' }
DroneMapWithOWSView >> installWaypointCaptureHandler [
    (waypointInputMode and: [ rsCanvas notNil ]) ifFalse: [ ^ self ].
    self uninstallWaypointCaptureHandler.
    rsCanvas when: RSMouseClick do: [ :evt | self waypointCanvasClick: evt ] for: self
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> layout: application [ 
self halt.
^super layout: application 
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

{ #category : 'reseting' }
DroneMapWithOWSView >> markBaseMapDirty [
    baseMapDirty := true
]

{ #category : 'reseting' }
DroneMapWithOWSView >> ommitPendingWaypoints [
    (pendingWaypoints isNil or: [ pendingWaypoints isEmpty ]) ifTrue: [ ^ self ].
    onWaypointsCommittedBlock ifNotNil: [ onWaypointsCommittedBlock value: pendingWaypoints copy ].
    self stopWaypointCapture
]

{ #category : 'initialization' }
DroneMapWithOWSView >> onClusterSelectionChanged [
    | cluster |
    cluster := clusterList selectedItem.
    dronesList items: (cluster
        ifNil: [ #() ]
        ifNotNil: [ cluster drones ]).
    cluster ifNotNil: [ self visitCluster: cluster ].
    self refreshOverlays.
    mapCanvas canvas invalidate
]

{ #category : 'reseting' }
DroneMapWithOWSView >> onWaypointsCommitted: aBlock [
   
onWaypointsCommittedBlock := aBlock
]

{ #category : 'as yet unclassified' }
DroneMapWithOWSView >> open [
    "Assure l'initialisation avant ouverture; pas de layout: manuel ici."
    simulation ifNil: [ self error: 'Appeler initializeWithSimulation:centerLat:centerLon:zoom: avant #open' ].
    mapCanvas ifNil: [ self initializePresenters ].
    ^ super open
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayAmmoCB [
^ overlayAmmoCB   
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayAmmoCB: aValue [ 
overlayAmmoCB  := aValue 
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayCheckBox: ivarSymbol label: aString getter: getSel setter: setSel [
    | cb |
    cb := SpCheckBoxPresenter new.
    cb
        label: aString;
        state: (overlayModel perform: getSel);
        whenChangedDo: [ :newState |
            overlayModel perform: setSel with: newState.
            self refreshOverlays ].
    self instVarNamed: ivarSymbol put: cb.
    ^ cb
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayEnergyCB [ 
^overlayEnergyCB  
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayEnergyCB: aValue [
overlayEnergyCB := aValue
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayHullCB [ 
^overlayHullCB  
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayHullCB: aValue [ 
overlayHullCB  := aValue 
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayMissionCB [
^overlayMissionCB
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayMissionCB: aValue [
overlayMissionCB := aValue
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayModel: aModel [
    overlayModel := aModel
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayPerceptionCB [
^overlayPerceptionCB
]

{ #category : 'reseting' }
DroneMapWithOWSView >> overlayPerceptionCB:aValue [
overlayPerceptionCB := aValue
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

{ #category : 'reseting' }
DroneMapWithOWSView >> rebuildOverlayShapes [
    | c |
    c := self canvas ifNil: [ ^ self ].
    self removeExistingOverlayShapesFrom: c.
    overlayModel ifNil: [ ^ self ].
    overlayModel showPerceptionRadius ifTrue: [ self addPerceptionRadiusShapesTo: c ].
    overlayModel showMissionPaths ifTrue: [ self addMissionPathShapesTo: c ].
    overlayModel showEnergyBars ifTrue: [ self addEnergyBarShapesTo: c ].
    overlayModel showAmmoBars ifTrue: [ self addAmmoBarShapesTo: c ].
    overlayModel showClusterHull ifTrue: [ self addClusterHullShapesTo: c ].
    c signalUpdate
]

{ #category : 'rendering' }
DroneMapWithOWSView >> refresh [
	"Affiche une collection de drones sur la carte et le canvas."

	rsCanvas shapes do: [ :s |  
		"(s model isKindOf: Drone)| (s model isKindOf: DroneCluster )|(s model isKindOf: ClusterMission ) ifTrue:" s model ifNotNil:[ rsCanvas removeShape: s ] ].
 
	 
]

{ #category : 'reseting' }
DroneMapWithOWSView >> refreshAll [
    baseMapDirty
        ifTrue: [ self refreshBaseMap ].
    self refreshOverlays
]

{ #category : 'reseting' }
DroneMapWithOWSView >> refreshBaseMap [
    | bmpShape |
    baseMapDirty ifFalse: [ ^ self ].
    self resetBitMap.
    self computeBoundingBox.

    bmpShape := self bitMap.
    rsCanvas shapes
        select: [ :s | s isKindOf: RSBitmap ]
        thenDo: [ :old | rsCanvas removeShape: old ].
    rsCanvas add: bmpShape.
    baseMapDirty := false.
    rsCanvas signalUpdate
]

{ #category : 'reseting' }
DroneMapWithOWSView >> refreshOverlay [
    self rebuildOverlayShapes
]

{ #category : 'reseting' }
DroneMapWithOWSView >> refreshOverlays [
    self rebuildOverlayShapes
]

{ #category : 'reseting' }
DroneMapWithOWSView >> removeExistingOverlayShapesFrom: aCanvas [
    (aCanvas shapes copy) do: [ :s |
        ((s respondsTo: #attributeAt:ifAbsent:) and: [
            (s attributeAt: #overlay ifAbsent: [ false ]) = true ])
            ifTrue: [ aCanvas remove: s ] ]
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

{ #category : 'reseting' }
DroneMapWithOWSView >> simulation: aSimulation [
    simulation := aSimulation.
  "  self redraw"
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

{ #category : 'reseting' }
DroneMapWithOWSView >> startWaypointCapture [
    waypointInputMode := true.
    pendingWaypoints ifNil: [ pendingWaypoints := OrderedCollection new ].
    self installWaypointCaptureHandler
]

{ #category : 'actions' }
DroneMapWithOWSView >> stepSimulation [

Transcript show: 'Step Simulation';cr
]

{ #category : 'actions' }
DroneMapWithOWSView >> stopSimulation [

Transcript show: 'Stop Simulation';cr
]

{ #category : 'reseting' }
DroneMapWithOWSView >> stopWaypointCapture [
    waypointInputMode := false.
    self uninstallWaypointCaptureHandler
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

{ #category : 'reseting' }
DroneMapWithOWSView >> uninstallWaypointCaptureHandler [
    rsCanvas ifNil: [ ^ self ].
    rsCanvas removeInteractionsFor: self
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

{ #category : 'reseting' }
DroneMapWithOWSView >> waypointCanvasClick: evt [
    | geoPoint wp |
   waypointInputMode ifFalse: [ ^ self ].
 
    geoPoint := self physicalPositionOf: evt positionFromCamera.
    geoPoint ifNil: [ ^ self ].
    wp := (Smalltalk at: #Waypoint ifAbsent: [ nil ])
        ifNotNil: [ (Smalltalk at: #Waypoint) latitude: geoPoint y longitude: geoPoint x altitude: 1000 ].
    wp ifNotNil: [
        pendingWaypoints add: wp.
        self addWaypointMarkerFor: wp.
        self refreshOverlays ]
]

{ #category : 'reseting' }
DroneMapWithOWSView >> waypointClearBtn [
    ^ waypointClearBtn
]

{ #category : 'reseting' }
DroneMapWithOWSView >> waypointCommitBtn [
    ^ waypointCommitBtn

]

{ #category : 'reseting' }
DroneMapWithOWSView >> waypointStartBtn [
    ^ waypointStartBtn
]
