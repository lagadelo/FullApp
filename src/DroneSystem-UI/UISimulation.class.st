Class {
	#name : 'UISimulation',
	#superclass : 'SpPresenter',
	#instVars : [
		'simulation',
		'canvasPresenter',
		'rsCanvas',
		'baseBitmap',
		'overlayModel',
		'toolBarPresenter',
		'overlayPanelPresenter',
		'clusterListPresenter',
		'droneListPresenter',
		'statusLabelPresenter',
		'waypointCaptureOn',
		'pendingWaypoints',
		'bbox',
		'imageSize',
		'imageWidth',
		'baseMapDirty',
		'overlayChecks',
		'baseShapes',
		'zoomLevel',
		'bboxBase',
		'overlayShapes',
		'simRunning',
		'simLoopProcess',
		'timeLabelPresenter'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
UISimulation class >> exampleClasses [ 

| polygon drones sim cluster1 cluster2 d1 d2 mission fleet view intervalMs running   |

intervalMs := 300.  "ms entre steps"
running := true.
sim := SimulationState new.
drones := {
    (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beAlly ; yourself.   "Paris"
    (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120) beAlly ; yourself. "Bordeaux"
    (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100) beAlly; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100) beHostile; yourself. "?"
} asOrderedCollection.

cluster1 := DroneCluster new initializeWithDrones: drones clusterId: 1.
cluster2 := DroneCluster example: 20.

fleet := DroneFleet new.
fleet addCluster: cluster1.
fleet addCluster: cluster2.
sim addFleet: fleet.

polygon := {
    {50.6292 . 3.0573  . 100}. "Lille"
    {48.3904 . -4.4947 . 100}. "Brest"
    {43.2965 . 5.3698 . 100}. "Marseille"
    {51.5074 . -0.1276   . 100}. "Londres"
} collect: [:a | GeoPoint with: a ].

mission := (SecurizationMission new polygon: polygon) assignToCluster: cluster1.
"mission connaît les waypoints, cluster1 mission: mission"
view := self  openOn: sim.

]

{ #category : 'as yet unclassified' }
UISimulation class >> lonLatToWebMercator: lonLatPoint [
    | lon lat x y |
    lon := lonLatPoint x.
    lat := lonLatPoint y.
    x := lon * 20037508.34 / 180.
    y := ((lat + 90) * Float pi / 360) tan ln * 6378137.
    ^ x @ y.
]

{ #category : 'instance creation' }
UISimulation class >> openOn: aSimulation [
    ^ (self basicNew simulation: aSimulation; initialize ) open.
]

{ #category : 'as yet unclassified' }
UISimulation class >> pixelForLon: lon lat: lat inBbox: aBbox width: w height: h [
    | coord xMin yMin xMax yMax xNorm yNorm |
    coord := self lonLatToWebMercator: (lon @ lat).
    xMin := aBbox origin x. yMin := aBbox origin y.
    xMax := aBbox corner x. yMax := aBbox corner y.
    xNorm := (coord x - xMin) / (xMax - xMin).
    yNorm := (yMax - coord y) / (yMax - yMin).
    ^ ((xNorm * w) rounded) @ ((yNorm * h) rounded).
]

{ #category : 'presenters' }
UISimulation >> addBaseShape: aShape [
    baseShapes ifNil: [ baseShapes := OrderedCollection new ].
    (baseShapes includes: aShape) ifTrue: [ ^ aShape ].
    baseShapes add: aShape.
    (rsCanvas notNil and: [ rsCanvas shapes includes: aShape ] ) ifFalse: [
        rsCanvas add: aShape ].
    ^ aShape
]

{ #category : 'debugging' }
UISimulation >> allDrones [
    | selClusters clusters |
    selClusters := self selectedClusters.
    clusters := selClusters isEmpty
        ifTrue: [ self clustersFromSimulation ]
        ifFalse: [ selClusters ].
    clusters isEmpty ifTrue: [ ^ #() ].
    ^ clusters gather: [ :c | (c respondsTo: #drones) ifTrue: [ c drones ifNil: [ #() ] ] ifFalse: [ #() ] ]

]

{ #category : 'accessing' }
UISimulation >> baseBitmap [

	^ baseBitmap
]

{ #category : 'accessing' }
UISimulation >> baseBitmap: anObject [

	baseBitmap := anObject
]

{ #category : 'accessing' }
UISimulation >> baseMapDirty [

	^ baseMapDirty
]

{ #category : 'accessing' }
UISimulation >> baseMapDirty: anObject [

	baseMapDirty := anObject
]

{ #category : 'accessing' }
UISimulation >> bbox [

	bbox ifNil: [ bbox := self computeBoundingBox ].
	^ bbox
]

{ #category : 'accessing' }
UISimulation >> bbox: anObject [

	bbox := anObject
]

{ #category : 'canvas' }
UISimulation >> boundingBox [
    bbox ifNil: [ bbox := self computeBoundingBox ].
    ^ bbox.
]

{ #category : 'overlay models' }
UISimulation >> buildBaseMap [
    rsCanvas ifNil: [ ^ self ].
    baseMapDirty := false.
    "Retirer anciens shapes de base (si on reconstruit)"
    baseShapes do: [ :s | (rsCanvas shapes includes: s) ifTrue: [ rsCanvas removeShape: s ] ].
    baseShapes removeAll.

    (Smalltalk includesKey: #OWSServiceWMS)
        ifTrue: [
            | wms img bmp |
            [ wms := OWSServiceWMS new ] on: Error do: [ ^ self buildFallbackBaseMap ].
            wms url: 'https://data.geopf.fr/wms-r'.
            [ img := wms
                map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
                bbox: self boundingBox
                size: self imageSize
                epsg: '3857'
                format: 'image/png' ]
                on: Error do: [ ^ self buildFallbackBaseMap ].
            bmp := RSBitmap newFrom: img.
            self addBaseShape: bmp ]
        ifFalse: [ self buildFallbackBaseMap ]
]

{ #category : 'presenters' }
UISimulation >> buildCanvasPresenter [
    canvasPresenter ifNotNil: [ ^ canvasPresenter ].
    self buildToolBar.   "Assure toolbar prête"
    self ensureCanvas.
    canvasPresenter := self newPresenter.
    canvasPresenter layout: (SpBoxLayout newTopToBottom
        spacing: 4;
        add: toolBarPresenter;          "<<< Toolbar au dessus de la carte"
        add: (self buildCanvasWidget);
        yourself).
    ^ canvasPresenter
]

{ #category : 'presenters-building' }
UISimulation >> buildCanvasWidget [
    rsCanvas ifNil: [ ^ SpLabelPresenter new label: 'RSCanvas indisponible' ].
    (Smalltalk includesKey: #SpRoassalPresenter) ifTrue: [
        ^ SpRoassalPresenter new
            canvas: rsCanvas;
            yourself ].
    "Fallback: embed le morph"
    (Smalltalk includesKey: #SpMorphPresenter) ifTrue: [
        ^ SpMorphPresenter new
            morph: rsCanvas asMorph;
            yourself ].
    ^ SpLabelPresenter new label: 'Pas de presenter Roassal'
]

{ #category : 'as yet unclassified' }
UISimulation >> buildFallbackBaseMap [
    | rect |
    rect := RSBox new
        width: self imageSize x;
        height: self imageSize y;
        color: Color veryLightGray;
        yourself.
    self addBaseShape: rect.
]

{ #category : 'debugging' }
UISimulation >> buildLists [
    clusterListPresenter ifNil: [
        clusterListPresenter := SpListPresenter new
            headerTitle: 'Clusters';
            items: self clusterItems;
            yourself.

        "Activer multi‑sélection selon l’API dispo"
        (clusterListPresenter respondsTo: #beMultipleSelection)
            ifTrue: [ clusterListPresenter beMultipleSelection ]
            ifFalse: [
                (clusterListPresenter respondsTo: #multipleSelection:)
                    ifTrue: [ clusterListPresenter multipleSelection: true ]
                    ifFalse: [
                        (clusterListPresenter respondsTo: #allowMultipleSelection:)
                            ifTrue: [ clusterListPresenter allowMultipleSelection: true ] ] ].

        clusterListPresenter display: [ :c |
            c ifNil: [ '' ] ifNotNil: [
                (c respondsTo: #name)
                    ifTrue: [ c name ]
                    ifFalse: [
                        (c respondsTo: #clusterId)
                            ifTrue: [ 'C', c clusterId printString ]
                            ifFalse: [ c printString ] ] ] ].

        clusterListPresenter whenSelectionChangedDo: [
            self updateDroneListFromSelectedClusters.
            self refreshDrones ] ].

    droneListPresenter ifNil: [
        droneListPresenter := SpListPresenter new
            headerTitle: 'Drones';
            yourself.
        droneListPresenter display: [ :d |
            d ifNil: [ '' ] ifNotNil: [
                (d respondsTo: #uniqueId)
                    ifTrue: [ d uniqueId printString ]
                    ifFalse: [
                        (d respondsTo: #name)
                            ifTrue: [ d name ]
                            ifFalse: [ d printString ] ] ] ] ].

    self updateDroneListFromSelectedClusters
]

{ #category : 'presenters-building' }
UISimulation >> buildOverlayPanel [

	| lay p |
	overlayPanelPresenter ifNotNil: [ ^ overlayPanelPresenter ].

	lay := SpBoxLayout newTopToBottom
		       spacing: 2;
		       add: (SpLabelPresenter new label: 'Overlays');
		       add:
			       (self
				        overlayCheckboxLabel: 'Perception'
				        flag: #showPerceptionRadius:);
		       add:
			       (self
				        overlayCheckboxLabel: 'Missions'
				        flag: #showMissionPaths:);
		       add:
			       (self overlayCheckboxLabel: 'Fuel' flag: #showEnergyBars:);
		       add: (self overlayCheckboxLabel: 'Ammo' flag: #showAmmoBars:);
		       add:
			       (self overlayCheckboxLabel: 'Hull' flag: #showClusterHull:);
		       yourself.
	p := self newPresenter.
	p layout: lay.
	overlayPanelPresenter := p
]

{ #category : 'presenters-building' }
UISimulation >> buildStatusLabel [
    statusLabelPresenter ifNotNil: [ ^ statusLabelPresenter ].
    statusLabelPresenter := SpLabelPresenter new label: 'Ready'.
    ^ statusLabelPresenter.
]

{ #category : 'presenters' }
UISimulation >> buildToolBar [
    toolBarPresenter ifNotNil: [ ^ toolBarPresenter ].
    timeLabelPresenter := SpLabelPresenter new label: 't=0'.
    toolBarPresenter := self newPresenter.
    toolBarPresenter layout: (SpBoxLayout newLeftToRight
        spacing: 4;
        add: (self newButton: 'Play'    icon: 'play'    action: [ self startSimulationLoop ]);
        add: (self newButton: 'Pause'   icon: 'pause'   action: [ self pauseSimulationLoop ]);
        add: (self newButton: 'Save'    icon: 'save'    action: [ self saveSimulationDialog ]);
        add: (self newButton: 'Load'    icon: 'open'    action: [ self loadSimulationDialog ]);
        add: (self newButton: 'Inspect' icon: 'inspect' action: [ simulation inspect ]);
        add: (self newButton: 'Reload'  icon: 'refresh' action: [ self markBaseMapDirty; refreshAll ]);
        add: (self newButton: 'All ON'  icon: 'flag'    action: [ self setAllOverlays: true ]);
        add: (self newButton: 'All OFF' icon: 'flag'    action: [ self setAllOverlays: false ]);
        add: (self newButton: 'Cap WP'  icon: 'flag'    action: [ self startWaypointCapture ]);
        add: (self newButton: 'Commit'  icon: 'commit'  action: [ self commitPendingWaypoints ]);
        add: (self newButton: 'Clear'   icon: 'clear'   action: [ self clearPendingWaypoints ]);
        add: (self newButton: 'Refresh D' icon: 'refresh' action: [ self refreshDrones ]);
        add: (self newButton: 'Zoom +'  icon: 'zoomIn'  action: [ self zoomIn ]);
        add: (self newButton: 'Zoom -'  icon: 'zoomOut' action: [ self zoomOut ]);
        add: (self newButton: 'Reset'   icon: 'reset'   action: [ self resetZoom ]);
        addLast: timeLabelPresenter;
        yourself).
    ^ toolBarPresenter
]

{ #category : 'presenters' }
UISimulation >> canvasPointFromPixel: pixelPoint [
    | w h |
    w := self imageSize x asFloat.
    h := self imageSize y asFloat.
    "Roassal: on centre => x' = x - w/2 ; y' = (h/2) - y (inversion verticale)."
    ^ (pixelPoint x - (w / 2)) @ ((h / 2) - pixelPoint y)
]

{ #category : 'accessing' }
UISimulation >> canvasPresenter [

	^ canvasPresenter
]

{ #category : 'accessing' }
UISimulation >> canvasPresenter: anObject [

	canvasPresenter := anObject
]

{ #category : 'presenters' }
UISimulation >> clearOverlayShapes [
    overlayShapes ifNil: [ ^ self ].
    overlayShapes do: [ :s | (rsCanvas shapes includes: s) ifTrue: [ rsCanvas removeShape: s ] ].
    overlayShapes removeAll.
]

{ #category : 'waypoints' }
UISimulation >> clearPendingWaypoints [
    pendingWaypoints removeAll.
    self status: 'Cleared WP'.
    self refreshOverlays.
]

{ #category : 'tests - test data' }
UISimulation >> clusterItems [
    (simulation respondsTo: #clusters) ifTrue: [ ^ simulation clusters ifNil: [ #() ] ].
    (simulation respondsTo: #allFleets) ifTrue: [
        | fleets |
        fleets := simulation allFleets.
        (fleets isEmpty or: [ (fleets first respondsTo: #clusters) not ])
            ifTrue: [ ^ #() ].
        ^ fleets first clusters ].
    ^ #().
]

{ #category : 'accessing' }
UISimulation >> clusterListPresenter [

	^ clusterListPresenter
]

{ #category : 'accessing' }
UISimulation >> clusterListPresenter: anObject [

	clusterListPresenter := anObject
]

{ #category : 'debugging' }
UISimulation >> clustersFromSimulation [
     | fleets |   (simulation respondsTo: #clusters) ifTrue: [ ^ simulation clusters ifNil: [ #() ] ].

    fleets := (simulation respondsTo: #fleets)
        ifTrue: [ simulation fleets ]
        ifFalse: [ (simulation respondsTo: #allFleets) ifTrue: [ simulation allFleets first clusters] ifFalse: [ #() ] ].
    fleets isNil ifTrue: [ ^ #() ].
    ^ fleets gather: [ :f | (f respondsTo: #clusters) ifTrue: [ f clusters ] ifFalse: [ #() ] ]

]

{ #category : 'waypoints' }
UISimulation >> commitPendingWaypoints [
    pendingWaypoints isEmpty
        ifTrue: [ ^ self status: 'No WP' ].
    "Brancher la logique métier ici."
    self status: 'Committed ', pendingWaypoints size printString, ' WP'.
    self stopWaypointCapture.
    self refreshOverlays.
]

{ #category : 'presenters' }
UISimulation >> computeBoundingBox [
    | points latMin latMax lonMin lonMax padLat padLon |
    "1. Collecte des points source (battleZone sinon dérive des drones)"
    points := (simulation respondsTo: #battleZone)
        ifTrue: [ simulation battleZone ]
        ifFalse: [ nil ].
    (points isNil or: [ points isEmpty ]) ifTrue: [
        points := (simulation allDrones collect: [ :d |
            ((d respondsTo: #latitude) and: [ d respondsTo: #longitude ])
                ifTrue: [ GeoPoint latitude: d latitude longitude: d longitude altitude: 0 ]
                ifFalse: [ nil ] ]) reject: #isNil ].
    (points isNil or: [ points isEmpty ]) ifTrue: [
        "Fallback constant (France approx.)"
        points := {
            GeoPoint latitude: 51.2 longitude: -5   altitude: 0.
            GeoPoint latitude: 41.0 longitude:  9   altitude: 0.
            GeoPoint latitude: 41.0 longitude: -5   altitude: 0.
            GeoPoint latitude: 51.2 longitude:  9   altitude: 0 } ].

    "2. Min / Max"
    latMin := latMax := points first latitude.
    lonMin := lonMax := points first longitude.
    points do: [ :gp |
        latMin := latMin min: gp latitude.
        latMax := latMax max: gp latitude.
        lonMin := lonMin min: gp longitude.
        lonMax := lonMax max: gp longitude ].

    "3. Padding 5% (évite bords collés); si delta nul, impose petite aire."
    (latMax = latMin) ifTrue: [
        latMax := latMax + 0.05.
        latMin := latMin - 0.05 ].
    (lonMax = lonMin) ifTrue: [
        lonMax := lonMax + 0.05.
        lonMin := lonMin - 0.05 ].
    padLat := (latMax - latMin) * 0.05.
    padLon := (lonMax - lonMin) * 0.05.
    latMax := latMax + padLat.
    latMin := latMin - padLat.
    lonMax := lonMax + padLon.
    lonMin := lonMin - padLon.

    "4. Conversion WebMercator -> bboxBase"
    bboxBase := (self class lonLatToWebMercator: (lonMin @ latMax))
        corner: (self class lonLatToWebMercator: (lonMax @ latMin)).

    "5. Applique le zoom"
    self updateZoomedBBox.
    self computeImageSize  "recalcule imageSize dépendant du nouveau bbox"
]

{ #category : 'canvas' }
UISimulation >> computeImageSize [
    | w h ratio |
    w := self imageWidth.
    ratio := ((self bbox corner y - bbox origin y) asFloat
        / (bbox corner x - bbox origin x) asFloat) max: 0.0001.
    h := (w * ratio) rounded.
    imageSize := w @ h.
]

{ #category : 'canvas' }
UISimulation >> connectCanvasEvents [
    rsCanvas ifNil: [ ^ self ].
    (Smalltalk includesKey: #RSMouseClick) ifTrue: [
        rsCanvas when: RSMouseClick do: [ :evt |
            waypointCaptureOn ifTrue: [ self handleWaypointClick: evt ] ] for: self ].
]

{ #category : 'debugging' }
UISimulation >> debugBaseShapes [
    Transcript
        show: 'Base shapes count: ', baseShapes size printString; cr;
        show: 'Canvas shapes total: ', (rsCanvas ifNil: [ 0 ] ifNotNil: [ rsCanvas shapes size ]) printString; cr;
        show: 'Base shapes still present: ',
            (baseShapes count: [ :s | rsCanvas shapes includes: s ]) printString; cr.
]

{ #category : 'tests - test data' }
UISimulation >> debugDrones [
    (simulation respondsTo: #drones)
        ifFalse: [ Transcript show: 'simulation has no #drones'; cr. ^ self ].
    Transcript
        show: 'Drone count: ', simulation drones size printString; cr.
    simulation drones do: [ :d |
        | p |
        p := self pixelForDrone: d.
        Transcript
            show: ((d respondsTo: #uniqueId)
                ifTrue: [ d uniqueId printString ]
                ifFalse: [ d printString ]);
            show: ' -> pixel: ', p printString; cr ].
]

{ #category : 'debugging' }
UISimulation >> debugGeo: lat lon: lon [
    | pix canvas |
    self computeBoundingBox.
    pix := self class
        pixelForLon: lon
        lat: lat
        inBbox: self boundingBox
        width: self imageSize x
        height: self imageSize y.
    canvas := pix ifNotNil: [ self canvasPointFromPixel: pix ].
    Transcript
        show: 'Geo (lat=', lat printString, ' lon=', lon printString, ') -> pixel(top-left)=', pix printString, ' -> canvas(center)=', canvas printString; cr.
    ^ canvas
]

{ #category : 'debugging' }
UISimulation >> debugLayout [
    Transcript
        show: 'layout: ', (self layout ifNil: [ 'nil' ]) printString; cr;
        show: 'canvasPresenter: ', (canvasPresenter ifNil: [ 'nil' ] ifNotNil: [ canvasPresenter class name ]); cr;
        show: 'overlayPanelPresenter: ', (overlayPanelPresenter ifNil: [ 'nil' ] ifNotNil: [ overlayPanelPresenter class name ]); cr. 

]

{ #category : 'presenters-building' }
UISimulation >> debugLists [
    Transcript
        show: 'Clusters count: ', (clusterListPresenter ifNil:[0] ifNotNil:[ clusterListPresenter items size ]) printString; cr;
        show: 'Selected cluster: ', (clusterListPresenter ifNil:[ 'nil' ] ifNotNil:[ clusterListPresenter selectedItem printString ]); cr;
        show: 'Drones count: ', (droneListPresenter ifNil:[0] ifNotNil:[ droneListPresenter items size ]) printString; cr.
]

{ #category : 'accessing' }
UISimulation >> defaultImageWidth [

^1600
]

{ #category : 'presenters' }
UISimulation >> defaultLayout [
    | right |
    right := SpBoxLayout newTopToBottom
        spacing: 6;
        add: overlayPanelPresenter;
        add: clusterListPresenter;
        add: droneListPresenter;
        add: statusLabelPresenter;
        yourself.
    ^ SpBoxLayout newLeftToRight
        spacing: 10;
        add: canvasPresenter;
        add: (self newPresenter
            layout: right;
            yourself);
        yourself
]

{ #category : 'overlays' }
UISimulation >> drawAmmoOverlay [
    ((overlayModel respondsTo: #showAmmoBars)
        and: [ overlayModel showAmmoBars ]) ifFalse: [ ^ self ].
    (simulation respondsTo: #drones) ifFalse: [ ^ self ].
    simulation drones do: [ :d |
        (d respondsTo: #ammunition) ifTrue: [
            | pos barW cap ratio filled fill frame |
            pos := self pixelForDrone: d.
            pos ifNil: [ ^ self ].
            barW := 34. cap := 10.
            ratio := ((d ammunition min: cap) / cap) max: 0.
            filled := (barW * ratio) max: 1.
            fill := RSBox new
                width: filled; height: 5;
                color: (Color orange alpha: 0.75);
                yourself.
            frame := RSBox new
                width: barW; height: 5;
                noFill; color: Color black; yourself.
            fill attributeAt: #overlay put: true.
            frame attributeAt: #overlay put: true.
            fill translateTo: (pos x - (barW / 2) @ (pos y + 18)).
            frame translateTo: (pos x - (barW / 2) @ (pos y + 18)).
            rsCanvas add: fill; add: frame ] ]
]

{ #category : 'overlays' }
UISimulation >> drawClusterHullOverlay [

	((overlayModel respondsTo: #showClusterHull) and: [
		 overlayModel showClusterHull ]) ifFalse: [ ^ self ].
	((Smalltalk includesKey: #ConvexHullCalculator) and: [
		 simulation respondsTo: #clusters ]) ifFalse: [ ^ self ].
	simulation clusters do: [ :cluster |
			(cluster respondsTo: #drones) ifTrue: [
					| points hull pts poly |
					points := cluster drones
						          collect: [ :d |
								          (d respondsTo: #position)
									          ifTrue: [ d position ]
									          ifFalse: [ nil ] ]
						          thenSelect: #notNil.
					points size > 2 ifTrue: [
							hull := ConvexHullCalculator new hullForGeoPoints: points.
							pts := hull
								       collect: [ :gp | self graphicalPixelOf: gp ]
								       thenSelect: #notNil.
							pts size > 2 ifTrue: [
									poly := RSPolygon new
										        points: pts;
										        color: (Color red alpha: 0.07);
										        borderColor: (Color red alpha: 0.4);
										        borderWidth: 1;
										        yourself.
									poly attributeAt: #overlay put: true.
									self markOverlayShape: poly.
									rsCanvas add: poly ] ] ] ]
]

{ #category : 'presenters' }
UISimulation >> drawDroneIcons [
    | drones |
    rsCanvas ifNil: [ ^ self ].
   drones := self simulation allFleets first  allDrones.
    drones isEmpty ifTrue: [ ^ self ].
    drones do: [ :d |
        | p dot lbl |
        p := self pixelForDrone: d.
        p ifNil: [ ^ self ].
        dot := RSCircle new
            radius: 5 ;
            color: (((d respondsTo: #isHostile) and: [ d isHostile ])
                ifTrue: [ Color red ] ifFalse: [ Color green ]);
            yourself.
        dot translateTo: p.
        self markOverlayShape: dot.
        rsCanvas add: dot.
        lbl := RSLabel new
            text: ((d respondsTo: #uniqueId)
                ifTrue: [ d uniqueId printString ]
                ifFalse: [ (d respondsTo: #name) ifTrue: [ d name ] ifFalse: [ 'D' ] ]);
            color: Color black;
            yourself.
        lbl translateTo: (p x + 6) @ (p y - 6).
        self markOverlayShape: lbl.
        rsCanvas add: lbl ].
rsCanvas signalUpdate. 
rsCanvas signalUpdate. 
]

{ #category : 'overlays' }
UISimulation >> drawEnergyOverlay [

	((overlayModel respondsTo: #showEnergyBars) and: [
		 overlayModel showEnergyBars ]) ifFalse: [ ^ self ].
	(simulation respondsTo: #allDrones) ifFalse: [ ^ self ].
	simulation allDrones do: [ :d |
			(d respondsTo: #energy) ifTrue: [
					| pos barW ratio filled fill frame |
					pos := self pixelForDrone: d.
					pos ifNil: [ ^ self ].
					barW := 34.
					ratio := (d energy max: 0) / 100.0 min: 1.0.
					filled := barW * ratio max: 1.
					fill := RSBox new
						        width: filled;
						        height: 5;
						        color: (Color purple alpha: 0.3);
						        yourself.
					frame := RSBox new
						         width: barW;
						         height: 5; fill: (Color purple alpha: 1);
						      	  borderColor: #black;
						         yourself.

					fill translateTo: pos x - (barW / 2) @ (pos y + 10).
					frame translateTo: pos x - (barW / 2) @ (pos y + 10).
					self markOverlayShape: frame.
					self markOverlayShape: fill.
					rsCanvas
						add: fill;
						add: frame ] ]
]

{ #category : 'overlays' }
UISimulation >> drawMissionOverlay [

	| pts poly m |
	self selectedClusters do:[:c| 	m := c currentMission . 
				m ifNotNil:[
					pts := m "waypoints" polygon
						       collect: [ :wp | self pixelForWaypoint: wp ]
						       thenSelect: #notNil.
					pts size > 1 ifTrue: [
							poly := RSPolygon new
								        points: pts;
								        color: (Color yellow alpha: 0.7);
								        width: 10;
								        yourself.
							"   poly attributeAt: #overlay put: true."
							self markOverlayShape: poly.
							rsCanvas add: poly ] ]]
]

{ #category : 'overlays' }
UISimulation >> drawPerceptionOverlay [

	((overlayModel respondsTo: #showPerceptionRadius) and: [
		 overlayModel showPerceptionRadius ]) ifFalse: [ ^ self ].
	(simulation respondsTo: #allDrones) ifFalse: [ ^ self ].
	simulation allDrones do: [ :d |
			(d respondsTo: #detectionRange) ifTrue: [
					| pos range circle |
					range := d detectionRange.
					pos := self pixelForDrone: d.
					(pos isNil or: [ range isNil ]) ifFalse: [
							circle := RSCircle new
								          radius: (range / 5  );
								          color: (Color lightBlue alpha: 0.15);
								          borderColor: (Color lightBlue alpha: 0.4);
								          yourself.
					 
							circle translateTo: pos.
							self markOverlayShape: circle.
							rsCanvas add: circle ] ] ]
]

{ #category : 'waypoints' }
UISimulation >> drawTempWaypoint: aWaypoint [

	| p c |
	rsCanvas ifNil: [ ^ self ].

	p := self pixelForWaypoint: aWaypoint.
	p ifNil: [ ^ self ].
	c := RSCircle new
		     radius: 5;
		     color: Color red;
		     yourself.
	c attributeAt: #overlay put: true.
	c translateTo: p.
	rsCanvas add: c.
	self markOverlayShape: c.
	rsCanvas signalUpdate
]

{ #category : 'accessing' }
UISimulation >> droneListPresenter [

	^ droneListPresenter
]

{ #category : 'accessing' }
UISimulation >> droneListPresenter: anObject [

	droneListPresenter := anObject
]

{ #category : 'as yet unclassified' }
UISimulation >> ensureBaseShapes [
    baseShapes ifNil: [ baseShapes := OrderedCollection new ].
    ^ baseShapes
]

{ #category : 'tests - test data' }
UISimulation >> ensureBattleZoneFromDrones [

	| drones latMin latMax lonMin lonMax |
	(simulation respondsTo: #battleZone) ifFalse: [ ^ self ].
	(simulation battleZone isNil or: [ simulation battleZone isEmpty ])
		ifFalse: [ ^ self ].

	drones := self simulation allDrones.
	drones isEmpty ifTrue: [ ^ self ].
	latMin := latMax := drones first latitude.
	lonMin := lonMax := drones first longitude.
	drones do: [ :d |
			latMin := latMin min: d latitude.
			latMax := latMax max: d latitude.
			lonMin := lonMin min: d longitude.
			lonMax := lonMax max: d longitude ].
	simulation battleZone: {
			(GeoPoint latitude: latMin longitude: lonMin altitude: 0).
			(GeoPoint latitude: latMin longitude: lonMax altitude: 0).
			(GeoPoint latitude: latMax longitude: lonMax altitude: 0).
			(GeoPoint latitude: latMax longitude: lonMin altitude: 0) }
]

{ #category : 'canvas' }
UISimulation >> ensureCanvas [

	rsCanvas ifNotNil: [ ^ rsCanvas ].

	rsCanvas := RSCanvas new.
	self ensureBattleZoneFromDrones.
	self computeBoundingBox.
	self computeImageSize.
	self ensureBaseShapes.
	self buildBaseMap.
	self connectCanvasEvents.
	^ rsCanvas
]

{ #category : 'presenters' }
UISimulation >> ensureOverlayChecks [
    overlayChecks ifNil: [ overlayChecks := Dictionary new ].
]

{ #category : 'overlay models' }
UISimulation >> ensureOverlayModel [
    overlayModel ifNil: [
        overlayModel := (Smalltalk includesKey: #DroneOverlayModel)
            ifTrue: [
                DroneOverlayModel new
                    showPerceptionRadius: true;
                    showMissionPaths: true;
                    showEnergyBars: true;
                    showAmmoBars: false;
                    showClusterHull: true;
                    yourself ]
            ifFalse: [ Dictionary new ] ]
]

{ #category : 'canvas' }
UISimulation >> fetchBitmapFromWMS [
    | wms img bmp  operations getmap layers map |
    rsCanvas ifNil: [ ^ self ].
    [(Smalltalk at: #OWSServiceWMS) new] on: Error do: [ ^ self ].
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
 
    bmp := RSBitmap newFrom: map.
    "bmp attributeAt: #base put: true."
    rsCanvas add: bmp.
]

{ #category : 'updating status' }
UISimulation >> fullDroneRefresh [
    self computeBoundingBox.
    self markBaseMapDirty.
    self refreshAll.
]

{ #category : 'presenters' }
UISimulation >> graphicalPixelOf: geoPoint [

	| pix |
	(geoPoint respondsTo: #latitude) ifFalse: [ ^ nil ].

	pix := self class
		       pixelForLon: geoPoint longitude
		       lat: geoPoint latitude
		       inBbox: self boundingBox
		       width: self imageSize x
		       height: self imageSize y.
	pix ifNil: [ ^ nil ].
	^ self canvasPointFromPixel: pix
]

{ #category : 'waypoints' }
UISimulation >> handleWaypointClick: evt [
    | wpClass geo wp |
    (Smalltalk includesKey: #Waypoint) ifFalse: [ ^ self ].
    wpClass := Waypoint.
    geo := self physicalLonLatFromPixel: evt positionFromCamera.
    geo ifNil: [ ^ self ].
    wp := wpClass latitude: geo y longitude: geo x altitude: 100.
    pendingWaypoints add: wp.
    self drawTempWaypoint: wp.
    self status: 'WP count: ', pendingWaypoints size printString.
]

{ #category : 'presenters' }
UISimulation >> iconNamed: aBaseName [
    "Essaie ThemeIcons / Icons. Retourne nil si introuvable (le label restera)."
    | candidates iconProviders |
    iconProviders := {
        [ ThemeIcons current ].
        [ Smalltalk at: #Icons ifAbsent: [ nil ] ] }.
    candidates := {
        ('small', aBaseName capitalized, 'Icon') asSymbol.
        (aBaseName , 'Icon') asSymbol }.
    iconProviders do: [ :provBlock |
        | prov |
        prov := provBlock value.
        prov ifNotNil: [
            candidates do: [ :sel |
                (prov respondsTo: sel) ifTrue: [
                    ^ (prov perform: sel) ] ] ] ].
    ^ nil
]

{ #category : 'accessing' }
UISimulation >> imageSize [

	^ imageSize
]

{ #category : 'accessing' }
UISimulation >> imageSize: anObject [

	imageSize := anObject
]

{ #category : 'accessing' }
UISimulation >> imageWidth [

	 imageWidth ifNil:[self imageWidth: self defaultImageWidth].
	^imageWidth
]

{ #category : 'accessing' }
UISimulation >> imageWidth: anObject [

	imageWidth := anObject
]

{ #category : 'presenters' }
UISimulation >> initialize [

	super initialize.
	baseMapDirty := true.
	imageWidth := 1200.
	overlayChecks := Dictionary new.
	waypointCaptureOn := false.
	pendingWaypoints := OrderedCollection new.
	zoomLevel := 1.
	baseShapes := OrderedCollection new.
	overlayShapes := OrderedCollection new.
	simRunning := false.
	simLoopProcess := nil.
	self
		ensureOverlayModel;
		ensureOverlayChecks;
		ensureBaseShapes
]

{ #category : 'presenters-building' }
UISimulation >> initializePresenters [
    self buildCanvasPresenter;
        buildLists;
        buildOverlayPanel;
        buildToolBar;
        buildStatusLabel.
]

{ #category : 'presenters' }
UISimulation >> installCanvasMenu [
    canvasPresenter ifNil: [ ^ self ].
    (canvasPresenter respondsTo: #contextMenu:) ifFalse: [ ^ self ].
    canvasPresenter contextMenu: [
        SpMenuPresenter new
            addItem: [ :i | i name: 'Refresh Drones'; action: [ self refreshDrones ] ];
            addItem: [ :i | i name: 'Full Refresh'; action: [ self fullDroneRefresh ] ];
            yourself ].
]

{ #category : 'presenters' }
UISimulation >> installShortcuts [
    (self respondsTo: #bindKeyCombination:toAction:) ifFalse: [ ^ self ].
    self bindKeyCombination: $r meta toAction: [ self refreshDrones ].
    self bindKeyCombination: $R meta toAction: [ self fullDroneRefresh ].
]

{ #category : 'presenters' }
UISimulation >> installShortcutsAndMenus [
    "Raccourcis + menu contextuel après construction."
    self installShortcuts.
    self installCanvasMenu.
]

{ #category : 'presenters' }
UISimulation >> isBaseShape: aShape [
    ^ baseShapes notNil and: [ baseShapes includes: aShape ]

]

{ #category : 'presenters' }
UISimulation >> isOverlayShape: aShape [
    ^ overlayShapes notNil and: [ overlayShapes includes: aShape ]
]

{ #category : 'overlays' }
UISimulation >> loadSimulationDialog [
    | ref |
    (Smalltalk includesKey: #UIManager)
        ifFalse: [ ^ self ].
    ref := UIManager default
        request: 'Fichier à charger (.fuel)'.
    ref ifNil: [ ^ self ].
    self loadSimulationFrom: ref asFileReference.
]

{ #category : 'overlays' }
UISimulation >> loadSimulationFrom: aFileRef [
    (Smalltalk includesKey: #FLMaterializer)
        ifFalse: [ ^ Transcript show: 'Fuel non chargé'; cr ].
    [ simulation := FLMaterializer materializeFromFileNamed: aFileRef fullName.
      self updateDroneListFromSelectedClusters.
      self computeBoundingBox.
      self markBaseMapDirty.
      self refreshAll.
      self updateTimeLabel.
      Transcript show: 'Simulation chargée: ', aFileRef fullName; cr ]
        on: Error do: [ :ex | Transcript show: 'Load error: ', ex messageText; cr ].
]

{ #category : 'canvas' }
UISimulation >> markBaseMapDirty [
    baseMapDirty := true.
]

{ #category : 'presenters' }
UISimulation >> markOverlayShape: aShape [
    overlayShapes ifNil: [ overlayShapes := OrderedCollection new ].
    (overlayShapes includes: aShape) ifFalse: [ overlayShapes add: aShape ].
    ^ aShape
]

{ #category : 'overlay models' }
UISimulation >> migrateMarkExistingBase [

	| guess |
	rsCanvas ifNil: [ ^ self ].

	guess := rsCanvas shapes copy.
	guess do: [ :s |
			(self shape: s hasAttribute: #base equals: true) ifTrue: [
				baseShapes addIfAbsent: s ] ]
]

{ #category : 'presenters' }
UISimulation >> newButton: labelString icon: iconName action: aBlock [

	| b ic |
	b := SpButtonPresenter new.
	labelString isEmpty ifFalse: [ b label: labelString ].
	(Smalltalk respondsTo: #at:) ifTrue: [ "just to silence" ].
	ic := (self respondsTo: #iconNamed:)
		      ifTrue: [ self iconNamed: iconName ]
		      ifFalse: [ nil ].
	ic ifNotNil: [ b icon: ic ].
	b action: aBlock.
	^ b
]

{ #category : 'presenters' }
UISimulation >> newButtonLabel: aString icon: baseName action: aBlock [
    | b ic |
    b := SpButtonPresenter new.
    ic := self iconNamed: baseName.
    ic ifNotNil: [ b icon: ic ].
    b label: aString; action: aBlock.
    ^ b
]

{ #category : 'presenters' }
UISimulation >> open [
    self layout ifNil: [
        self initializePresenters.
        self layout: self defaultLayout.
        self installShortcutsAndMenus ].
    ^ super open

]

{ #category : 'overlay models' }
UISimulation >> overlayCheckboxLabel: aLabel flag: setterSelector [
    | getter cb |
    getter := (setterSelector allButLast) asSymbol.
    cb := SpCheckBoxPresenter new
        label: aLabel;
        state: ((overlayModel respondsTo: getter)
            ifTrue: [ overlayModel perform: getter ]
            ifFalse: [ false ]);
        whenChangedDo: [ :st |
            (overlayModel respondsTo: setterSelector)
                ifTrue: [ overlayModel perform: setterSelector with: st ].
            self refreshOverlays ].
    self overlayChecks at: setterSelector put: cb.
    ^ cb.
]

{ #category : 'presenters' }
UISimulation >> overlayChecks [

	overlayChecks ifNil: [ overlayChecks := Dictionary new ].
	^ overlayChecks
]

{ #category : 'accessing' }
UISimulation >> overlayChecks: anObject [

	overlayChecks := anObject
]

{ #category : 'overlay models' }
UISimulation >> overlayFlags [
    ^ #(
        showPerceptionRadius:
        showMissionPaths:
        showEnergyBars:
        showAmmoBars:
        showClusterHull:
    ).
]

{ #category : 'accessing' }
UISimulation >> overlayModel [

	^ overlayModel
]

{ #category : 'accessing' }
UISimulation >> overlayModel: anObject [

	overlayModel := anObject
]

{ #category : 'accessing' }
UISimulation >> overlayPanelPresenter [

	^ overlayPanelPresenter
]

{ #category : 'accessing' }
UISimulation >> overlayPanelPresenter: anObject [

	overlayPanelPresenter := anObject
]

{ #category : 'overlays' }
UISimulation >> pauseSimulationLoop [
    simRunning := false.
    simLoopProcess ifNotNil: [
        simLoopProcess isTerminated ifFalse: [ simLoopProcess suspend ] ].
]

{ #category : 'accessing' }
UISimulation >> pendingWaypoints [

	^ pendingWaypoints
]

{ #category : 'accessing' }
UISimulation >> pendingWaypoints: anObject [

	pendingWaypoints := anObject
]

{ #category : 'waypoints' }
UISimulation >> physicalLonLatFromPixel: pixel [
    "Approx inverse WebMercator (lat reconstruction simplifiée)."
    | xMin yMin xMax yMax lon lat |
    bbox ifNil: [ ^ nil ].
    xMin := bbox origin x. yMin := bbox origin y.
    xMax := bbox corner x. yMax := bbox corner y.
    lon := xMin + (xMax - xMin) * (pixel x / self imageSize x).
    lat := yMax - (yMax - yMin) * (pixel y / self imageSize y).
    lat := ((lat / 6378137) exp atan * 360 / Float pi) - 90.
    ^ lon @ lat.
]

{ #category : 'presenters' }
UISimulation >> pixelForDrone: d [

	| pix |
	(d respondsTo: #latitude) ifFalse: [ ^ nil ].

	pix := self class
		       pixelForLon: d longitude
		       lat: d latitude
		       inBbox: self boundingBox
		       width: self imageSize x
		       height: self imageSize y.
	pix ifNil: [ ^ nil ].
	^ self canvasPointFromPixel: pix
]

{ #category : 'as yet unclassified' }
UISimulation >> pixelForLat: lat lon: lon inBbox: aBbox width: widthPx height: heightPx [
    | coord xMin yMin xMax yMax dx dy xGeo yGeo xNorm yNorm |
    aBbox ifNil: [ ^ nil ].
    xMin := aBbox origin x.
    yMin := aBbox origin y.
    xMax := aBbox corner x.
    yMax := aBbox corner y.
    dx := xMax - xMin.
    dy := yMax - yMin.
    (dx = 0 or: [ dy = 0 ]) ifTrue: [ ^ nil ].

    "1) Projection WebMercator"
    coord := self lonLatToWebMercator: (lon @ lat).
    xGeo := coord x.
    yGeo := coord y.

    "2) Normalisation"
    xNorm := (xGeo - xMin) / dx.
    yNorm := (yMax - yGeo) / dy.  "inversion Y"

    "3) Clamp 0..1"
    xNorm := (xNorm max: 0.0) min: 1.0.
    yNorm := (yNorm max: 0.0) min: 1.0.

    "4) Pixels"
    ^ (xNorm * widthPx) rounded @ ((yNorm * heightPx) rounded)
]

{ #category : 'presenters' }
UISimulation >> pixelForWaypoint: wp [

	| pix |
	(wp respondsTo: #latitude) ifFalse: [ ^ nil ].

	pix := self class
		       pixelForLon: wp longitude
		       lat: wp latitude
		       inBbox: self boundingBox
		       width: self imageSize x
		       height: self imageSize y.
	pix ifNil: [ ^ nil ].
	^ self canvasPointFromPixel: pix
]

{ #category : 'overlay models' }
UISimulation >> rebuildBaseMap [
    rsCanvas ifNil: [ ^ self ].
    self buildBaseMap.

]

{ #category : 'overlays' }
UISimulation >> refreshAll [
    rsCanvas ifNil: [ ^ self ].
    baseMapDirty ifTrue: [ self rebuildBaseMap ].
    self refreshOverlays.
    rsCanvas signalUpdate.
]

{ #category : 'updating status' }
UISimulation >> refreshDrones [
    "Force uniquement la partie drones (icônes + overlays dépendants)."
    rsCanvas ifNil: [ ^ self ].
    self removeOverlayShapes.
    self drawDroneIcons.
    self drawPerceptionOverlay.
    self drawMissionOverlay.
    self drawEnergyOverlay.
    self drawAmmoOverlay.
    rsCanvas signalUpdate.
]

{ #category : 'tests - test data' }
UISimulation >> refreshOverlays [
    rsCanvas ifNil: [ ^ self ].
    self removeOverlayShapes.
self halt. 
    self drawDroneIcons.          
    self drawClusterHullOverlay.
    self drawPerceptionOverlay.
    self drawMissionOverlay.
    self drawEnergyOverlay.
    self drawAmmoOverlay.
    rsCanvas signalUpdate.
]

{ #category : 'presenters' }
UISimulation >> removeOverlayShapes [
    self clearOverlayShapes.
]

{ #category : 'presenters' }
UISimulation >> resetZoom [
    self zoomLevel: 1.0.
]

{ #category : 'accessing' }
UISimulation >> rsCanvas [

	^ rsCanvas
]

{ #category : 'accessing' }
UISimulation >> rsCanvas: anObject [

	rsCanvas := anObject
]

{ #category : 'overlays' }
UISimulation >> saveSimulationDialog [
    | ref |
    (Smalltalk includesKey: #UIManager)
        ifFalse: [ ^ self saveSimulationTo: 'simulation.fuel' asFileReference ].
    ref := UIManager default
        request: 'Nom fichier (extension .fuel)'
        initialAnswer: 'simulation.fuel'.
    ref ifNil: [ ^ self ].
    self saveSimulationTo: ref asFileReference.
]

{ #category : 'overlays' }
UISimulation >> saveSimulationTo: aFileRef [
    (Smalltalk includesKey: #FLSerializer)
        ifFalse: [ ^ Transcript show: 'Fuel non chargé'; cr ].
    [ FLSerializer serialize: simulation toFileNamed: aFileRef fullName.
      Transcript show: 'Simulation sauvegardée: ', aFileRef fullName; cr ]
        on: Error do: [ :ex | Transcript show: 'Save error: ', ex messageText; cr ].
]

{ #category : 'presenters' }
UISimulation >> selectedClusters [

	| one |
	clusterListPresenter ifNil: [ ^ #(  ) ].
	(clusterListPresenter respondsTo: #selectedItems) ifTrue: [
		^ clusterListPresenter selectedItems reject: #isNil ].

	one := (clusterListPresenter respondsTo: #selectedItem)
		       ifTrue: [ clusterListPresenter selectedItem ]
		       ifFalse: [
				       (clusterListPresenter respondsTo: #selection)
					       ifTrue: [ clusterListPresenter selection ifNil: [ nil ] ]
					       ifFalse: [ nil ] ].
	^ one ifNil: [ #(  ) ] ifNotNil: [ { one } ]
]

{ #category : 'overlay models' }
UISimulation >> setAllOverlays: aBoolean [
    self overlayFlags do: [ :setter |
        (overlayModel respondsTo: setter)
            ifTrue: [ overlayModel perform: setter with: aBoolean ] ].
    self syncOverlayCheckboxStates.
    self refreshOverlays.
]

{ #category : 'overlay models' }
UISimulation >> shape: aShape hasAttribute: key equals: expected [
    (aShape respondsTo: #attributeAt:ifAbsent:)
        ifTrue: [ ^ (aShape attributeAt: key ifAbsent: [ ^ false ]) = expected ].
    ^ false
]

{ #category : 'accessing' }
UISimulation >> simulation [

	^ simulation
]

{ #category : 'accessing' }
UISimulation >> simulation1: anObject [

	simulation := anObject
]

{ #category : 'accessing' }
UISimulation >> simulation: aSim [
    simulation := aSim.
    ^ self.
]

{ #category : 'overlays' }
UISimulation >> simulationStepOnce [
    (simulation respondsTo: #step)
        ifTrue: [
            [ simulation step ] on: Error do: [ :ex |
                Transcript show: 'Step error: ', ex messageText; cr ] ].
    self refreshDrones.
    self updateTimeLabel.
]

{ #category : 'overlays' }
UISimulation >> startSimulationLoop [

	simRunning ifTrue: [ ^ self ].
	simRunning := true.
	simLoopProcess isNil ifFalse: [
			(simLoopProcess isTerminated or: [ simLoopProcess suspended ])
				ifFalse: [ ^ self ] ].
	simLoopProcess := [
		                  [ simRunning ] whileTrue: [
				                  self simulationStepOnce.
				                  (Delay forMilliseconds: 200) wait ] ] forkAt:
		                  Processor userInterruptPriority.
	simLoopProcess name: 'UISimulationLoop'
]

{ #category : 'waypoints' }
UISimulation >> startWaypointCapture [
    waypointCaptureOn := true.
    pendingWaypoints removeAll.
    self status: 'Capture ON'
]

{ #category : 'updating status' }
UISimulation >> status: aString [
    statusLabelPresenter ifNotNil: [ statusLabelPresenter label: aString ].


]

{ #category : 'accessing' }
UISimulation >> statusLabelPresenter [

	^ statusLabelPresenter
]

{ #category : 'accessing' }
UISimulation >> statusLabelPresenter: anObject [

	statusLabelPresenter := anObject
]

{ #category : 'waypoints' }
UISimulation >> stopWaypointCapture [
    waypointCaptureOn := false.
    self status: 'Capture OFF'.
]

{ #category : 'overlay models' }
UISimulation >> syncOverlayCheckboxStates [
    overlayChecks keysAndValuesDo: [ :setter :cb |
        | getter |
        getter := (setter allButLast) asSymbol.
        (overlayModel respondsTo: getter) ifTrue: [
            cb state: (overlayModel perform: getter) ] ]
]

{ #category : 'accessing' }
UISimulation >> toolBarPresenter [

	^ toolBarPresenter
]

{ #category : 'accessing' }
UISimulation >> toolBarPresenter: anObject [

	toolBarPresenter := anObject
]

{ #category : 'presenters-building' }
UISimulation >> updateDroneListFromSelectedCluster [
    | cluster drones |
    (clusterListPresenter isNil or: [ droneListPresenter isNil ]) ifTrue: [ ^ self ].
    cluster := clusterListPresenter selectedItem.
    drones := cluster
        ifNil: [ #() ]
        ifNotNil: [
            (cluster respondsTo: #drones)
                ifTrue: [ cluster drones ifNil: [ #() ] ]
                ifFalse: [
                    (cluster respondsTo: #droneList)
                        ifTrue: [ cluster droneList ifNil: [ #() ] ]
                        ifFalse: [ #() ] ] ].
    droneListPresenter items: drones.
]

{ #category : 'debugging' }
UISimulation >> updateDroneListFromSelectedClusters [

	| drones |
	droneListPresenter ifNil: [ ^ self ].

	drones := self allDrones.
	droneListPresenter items: drones
]

{ #category : 'overlays' }
UISimulation >> updateTimeLabel [

	| t |
	timeLabelPresenter ifNil: [ ^ self ].

	t := (simulation respondsTo: #currentTime)
		     ifTrue: [ simulation currentTime ]
		     ifFalse: [
				     (simulation respondsTo: #time)
					     ifTrue: [ simulation time ]
					     ifFalse: [ nil ] ].
	timeLabelPresenter label: 't=' , (t ifNil: [ '?' ]) printString
]

{ #category : 'presenters' }
UISimulation >> updateZoomedBBox [

	| min max cx cy dx dy factor |
	bboxBase ifNil: [ ^ self ].
	zoomLevel ifNil: [ zoomLevel := 1.0 ].
	zoomLevel <= 0 ifTrue: [ zoomLevel := 1.0 ].

	min := bboxBase origin.
	max := bboxBase corner.
	cx := min x + max x / 2.
	cy := min y + max y / 2.
	dx := max x - min x / 2 / zoomLevel.
	dy := max y - min y / 2 / zoomLevel.
	factor := 1.0. "placeholder si besoin d’aspect ratio"
	bbox := cx - dx @ (cy - dy * factor) corner:
		        cx + dx @ (cy + dy * factor)
]

{ #category : 'accessing' }
UISimulation >> waypointCaptureOn [

	^ waypointCaptureOn
]

{ #category : 'accessing' }
UISimulation >> waypointCaptureOn: anObject [

	waypointCaptureOn := anObject
]

{ #category : 'presenters-building' }
UISimulation >> wrapLayout: aLayout [
	"Encapsule un SpBoxLayout dans un presenter."

	| p |
	p := self newPresenter.
	p layout: aLayout.
	^ p
]

{ #category : 'presenters' }
UISimulation >> zoomIn [
    self zoomLevel: zoomLevel * 1.4.

]

{ #category : 'presenters' }
UISimulation >> zoomLevel: aNumber [
    zoomLevel := (aNumber asFloat max: 0.1) min: 50.
    self updateZoomedBBox.
    self markBaseMapDirty.
    self refreshAll.
]

{ #category : 'presenters' }
UISimulation >> zoomOut [
    self zoomLevel: zoomLevel / 1.4.
]
