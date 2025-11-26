Class {
	#name : 'UISimulation',
	#superclass : 'SpToggleSplitPresenter',
	#instVars : [
		'currentTime',
		'generateVideo',
		'simulation',
		'simulator',
		'dronesAllButton',
		'dronesSelectedButton',
		'dronesModeLabel',
		'showAllDrones',
		'canvasPresenter',
		'rsCanvas',
		'baseBitmap',
		'overlayModel',
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
		'timeLabelPresenter',
		'haltOnError',
		'allDrones',
		'missionListPresenter',
		'droneShapes',
		'clusterShapes',
		'scriptPresenter',
		'isRunning',
		'menuBarPresenter',
		'selectionRectangle'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
UISimulation class >> exampleClasse2 [

| polygon   sim      mission fleet view intervalMs running   |

intervalMs := 300.  "ms entre steps"
running := true.

sim := SimulationState  new.
fleet := DroneFleet new.
sim addFleet: fleet.

view := self  openOn: sim.
view presenter importClustersFromCSVDialog.
 

polygon := {
    {50.6292 . 3.0573  . 100}. "Lille"
    {48.3904 . -4.4947 . 100}. "Brest"
    {43.2965 . 5.3698 . 100}. "Marseille"
    {51.5074 . -0.1276   . 100}. "Londres"
} collect: [:a | GeoPoint with: a ].
 
mission := (SecurizationMission new polygon: polygon) assignToCluster: sim allClusters last.
"mission connaît les waypoints, cluster1 mission: mission"
 

]

{ #category : 'examples' }
UISimulation class >> exampleClasses [ 

| polygon drones sim cluster1 cluster2  mission fleet view intervalMs running   |

intervalMs := 300.  "ms entre steps"
running := true.
sim := SimulationState  new.
drones := {
    (Drone new moveToLatitude: 48.8566 longitude: 2.3522 altitude: 100) beAlly ; yourself.   "Paris"
    (Drone new moveToLatitude: 44.8378 longitude: -0.5792 altitude: 120) beAlly ; yourself. "Bordeaux"
    (Drone new moveToLatitude: 45.7640 longitude: 4.8357 altitude: 100) beAlly; yourself. "Lyon"
    (Drone new moveToLatitude: 40.7640 longitude: 2 altitude: 100) beHostile; yourself. "?"
} asOrderedCollection.

cluster1 := DroneCluster new initializeWithDrones: drones clusterId: #Surveillance.
cluster2 := DroneCluster example: 20. cluster2 clusterId:#Permanent.

fleet := DroneFleet new.
"fleet addCluster: cluster2."
fleet addCluster: cluster1.
sim addFleet: fleet.

polygon := {
    {50.6292 . 3.0573  . 100}. "Lille"
    {48.3904 . -4.4947 . 100}. "Brest"
    {43.2965 . 5.3698 . 100}. "Marseille"
    {51.5074 . -0.1276   . 100}. "Londres"
} collect: [:a | GeoPoint with: a ].
self halt. 
mission := (SecurizationMission new polygon: polygon) assignToCluster: cluster1.
"mission connaît les waypoints, cluster1 mission: mission"
view := self  openOn: sim.

]

{ #category : 'examples' }
UISimulation class >> exampleClasses3 [

	| polygon drones sim cluster1 mission fleet view intervalMs running |
	intervalMs := 300. "ms entre steps"
	running := true.
	sim := SimulationState new.
	drones := { ((Drone new
		            moveToLatitude: 48.8566
		            longitude: 2.3522
		            altitude: 100)
		           beAlly;
		           yourself) } asOrderedCollection.

	cluster1 := DroneCluster new
		            initializeWithDrones: drones
		            clusterId: #Surveillance.


	fleet := DroneFleet new.

	fleet addCluster: cluster1.
	sim addFleet: fleet.

	polygon := {
		           { 50.6292. 3.0573. 100 }. "Lille"
		           { 48.3904. -4.4947. 100 }. "Brest"
		           { 43.2965. 5.3698. 100 }. "Marseille"
		           { 51.5074. -0.1276. 100 } "Londres" } collect: [ :a |
		           GeoPoint with: a ].

	mission := (SecurizationMission new polygon: polygon)
		           assignToCluster: cluster1.

	view := self openOn: sim.
	^ sim
]

{ #category : 'examples' }
UISimulation class >> exampleClusterFile [
^'# Synthetic drone deployment for simulation ONLY (not real-world defense layout)
# Columns: clusterId,droneId,latitude,longitude,altitude(m)
clusterId,droneId,latitude,longitude,altitude
10,D001,48.2829,-4.4645,150
10,D002,48.2835,-4.4682,160
10,D003,48.2818,-4.4598,155
10,D004,48.2852,-4.4621,150
10,D005,48.2844,-4.4559,145
10,D006,48.2860,-4.4575,150
10,D007,48.2830,-4.4725,170
10,D008,48.2812,-4.4689,165
10,D009,48.2871,-4.4652,155
10,D010,48.2799,-4.4615,160
10,D011,48.2858,-4.4512,140
10,D012,48.2884,-4.4588,145
10,D013,48.2807,-4.4550,150
10,D014,48.2821,-4.4504,145
10,D015,48.2869,-4.4710,165
20,D016,48.4700,-5.0600,200
20,D017,48.4500,-5.1000,200
20,D018,48.4300,-5.1400,210
20,D019,48.4100,-5.1800,210
20,D020,48.3900,-5.2100,220
20,D021,48.3600,-5.2300,220
20,D022,48.3300,-5.2400,230
20,D023,48.3000,-5.2500,230
20,D024,48.2700,-5.2400,220
20,D025,48.2400,-5.2300,215
30,D026,48.4000,-4.8000,180
30,D027,48.4200,-4.7600,180
30,D028,48.4400,-4.7200,185
30,D029,48.4600,-4.6800,185
30,D030,48.4800,-4.6400,190'
]

{ #category : 'GoeReferencing' }
UISimulation class >> lonLatToWebMercator: lonLatPoint [
"lonLatPoint in degrees"
    | lon lat x y |
    lon := lonLatPoint x.
    lat := lonLatPoint y.
    x := lon * 20037508.34 / 180.
    y := ((lat + 90) * Float pi / 360) tan ln * 6378137.
    ^ x @ y.
]

{ #category : 'GoeReferencing' }
UISimulation class >> normalizedPixel: pixel inBbox: aBbox width: w height: h [
	"Approx inverse WebMercator (lat reconstruction simplifiée)."

	| xMin yMin xMax yMax px py |
	xMin := aBbox origin x.
	yMin := aBbox origin y.
	xMax := aBbox corner x.
	yMax := aBbox corner y.
	px := xMax - xMin * (pixel x / w) + xMin.
	py := yMax - (yMax - yMin * (pixel y / h)).
	^    px @ py
]

{ #category : 'instance creation' }
UISimulation class >> openOn: aSimulation [

	| tmp |
	tmp := self basicNew
		       simulation: aSimulation;
		       initialize.
	tmp open.
	^ tmp
]

{ #category : 'GoeReferencing' }
UISimulation class >> physicalLonLatFromPixel: pixel inBbox: aBbox width: w height: h [
	"Approx inverse WebMercator (lat reconstruction simplifiée)."

	^ self webMercatorToLongitureLatitude: (self
			   normalizedPixel: pixel
			   inBbox: aBbox
			   width: w
			   height: h)
]

{ #category : 'GoeReferencing' }
UISimulation class >> pixelForLon: lon lat: lat inBbox: aBbox width: w height: h [
    | coord xMin yMin xMax yMax xNorm yNorm |

 
    coord := self lonLatToWebMercator: (lon @ lat).
    xMin := aBbox origin x. yMin := aBbox origin y.
    xMax := aBbox corner x. yMax := aBbox corner y.
    xNorm := (coord x - xMin) / (xMax - xMin).
    yNorm := ( coord y - yMin) / (yMax - yMin).
    ^ ((xNorm * w) rounded) @ ((yNorm * h) rounded).
  "self  physicalLonLatFromPixel:  ((xNorm * w) rounded) @ ((yNorm * h) rounded) inBbox: aBbox width: w height: h ( "
]

{ #category : 'GoeReferencing' }
UISimulation class >> webMercatorToLongitureLatitude: lonLatPoint [
"returns a value in degrees based on mercator input"
    | lon lat x y |
    lon := lonLatPoint x.
    lat := lonLatPoint y.
    x := lon / 20037508.34 * 180.
    y :=  ((lat / 6378137) exp arcTan * 360 / Float pi) - 90.
    ^GeoPoint latitude: y longitude:  x altitude: 0.
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

{ #category : 'accessing - model' }
UISimulation >> allClusters [
    | clusters |
 
    self showAllDrones  not 
        ifTrue: [ clusters := self clustersFromSimulation ]
        ifFalse: [ clusters := self selectedClusters ].
    clusters isEmpty ifTrue: [ ^ #() ].
    ^ clusters  
]

{ #category : 'accessing - model' }
UISimulation >> allDrones [
  
    ^ self allClusters gather: [ :c | (c respondsTo: #drones) ifTrue: [ c drones ifNil: [ #() ] ] ifFalse: [ #() ] ]
]

{ #category : 'CSV' }
UISimulation >> attachImportedClusters: clusters [
    (simulation respondsTo: #addCluster:) ifTrue: [
        clusters do: [ :c | simulation addCluster: c ].
        ^ self ].
    (simulation respondsTo: #allFleets) ifTrue: [
        | fleet fleetClass |
        fleet := simulation allFleets ifNotEmpty: [ :fs | fs first ] ifEmpty: [
            fleetClass := Smalltalk at: #DroneFleet ifAbsent: [ nil ].
            fleetClass ifNil: [ ^ self ].
            fleetClass new ].
        clusters do: [ :c | (fleet respondsTo: #addCluster:) ifTrue: [ fleet addCluster: c ] ] ]
]

{ #category : 'CSV' }
UISimulation >> attachImportedMissions: missions [

	(simulation respondsTo: #addMission:) ifTrue: [
			missions do: [ :m | simulation addMission: m ].
			^ self ].
	(simulation respondsTo: #missions) ifTrue: [
			(simulation missions respondsTo: #add:) ifTrue: [
				missions do: [ :m | simulation missions add: m ] ] ]
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
UISimulation >> bbox [

	bbox ifNil: [  self computeBoundingBox ].
	^ bbox
]

{ #category : 'accessing' }
UISimulation >> bbox: anObject [

	bbox := anObject
]

{ #category : 'canvas' }
UISimulation >> boundingBox [
^self bbox
]

{ #category : 'Menus' }
UISimulation >> buildBaseMap [

	rsCanvas ifNil: [ ^ self ].
	baseMapDirty := false.
	"Retirer anciens shapes de base (si on reconstruit)"
	"baseShapes ifNotNil:[baseShapes do: [ :s | (rsCanvas shapes includes: s) ifTrue: [ rsCanvas removeShape: s ] ].
    baseShapes removeAll.]."
	rsCanvas shapes do: [ :a | a remove ].

	(Smalltalk includesKey: #OWSServiceWMS)
		ifTrue: [
				| wms img bmp |
				[ wms := OWSServiceWMS new ]
					on: Error
					do: [ ^ self buildFallbackBaseMap ].
				wms url: 'https://data.geopf.fr/wms-r'.
				[
					img := wms
						       map: { 'EL.GridCoverage'. 'FORETS.PUBLIQUES' }
						       bbox: self boundingBox
						       size: self imageSize
						       epsg: '3857'
						       format: 'image/png' ]
					on: Error
					do: [ ^ self buildFallbackBaseMap ].
				bmp := RSBitmap newFrom: img.
				self addBaseShape: bmp ]
		ifFalse: [ self buildFallbackBaseMap ]
]

{ #category : 'Menus' }
UISimulation >> buildCSVMenu [

	^ SpMenuPresenter new
		  addItem: [ :it |
				  it
					  name: 'Clusters CSV…';
					  icon: (self iconNamed: #smallOpen);
					  action: [ self importClustersFromCSVDialog ] ];
		  addItem: [ :it |
				  it
					  name: 'Missions CSV…';
					  icon: (self iconNamed: #smallOpen);
					  action: [ self importMissionsFromCSVDialog ] ];
		  yourself
]

{ #category : 'presenters-building' }
UISimulation >> buildCanvasPresenter [
    canvasPresenter ifNotNil: [ ^ canvasPresenter ].
   self ensureCanvas.
   self ensureOverlayModel.
    canvasPresenter := self newPresenter.
    canvasPresenter layout: (SpBoxLayout newTopToBottom
        spacing: 0;
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

{ #category : 'presenters-building' }
UISimulation >> buildCheckList [

	| cbx collection checkBoxesLayout |
	collection := OrderedCollection new.

	cbx := { #perception. #energy. #ammunitions. #missions. #hull }
		       with:
			       { #showPerceptionRadius:.
			       #showEnergyBars:. #showAmmoBars:. #showMissionPaths: .#showClusterHull: }
		       do: [ :aSymbol :aMessage |
				       | aCheckBox |
				       aCheckBox := self newCheckBox
					                    label: aSymbol;
					                    state: true;
					                    yourself.
				       aCheckBox whenChangedDo: [
					       self overlayModel perform: aMessage with: aCheckBox state. self refreshDrones  ].
				       collection add: aCheckBox.
				       ].

	checkBoxesLayout := SpBoxLayout newLeftToRight.
	collection do: [ :aCheckBox |
			checkBoxesLayout add: aCheckBox withConstraints: [ :constraints |
					constraints
						height: 20;
						width: 80 ] ].

	^ self newPresenter
		  layout: checkBoxesLayout;
		  yourself
]

{ #category : 'presenters-building' }
UISimulation >> buildClusterListPresenter [

	| menu |
	^ clusterListPresenter
		  ifNil: [
				  menu := self buildClusterListPresenterMenu.
				  self clusterListPresenter: (self newList display: [ :c |
								   c ifNil: [ '' ] ifNotNil: [ c id asString ] ];actions: menu) ; yourself ] 
		   
]

{ #category : 'Menus' }
UISimulation >> buildClusterListPresenterMenu [
^ SpActionGroup new
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Focus On';
							          iconName: #start;
							          description:
								          'Focus on the selected cluster by changing the battle zone';
							          action: [
									          self battleZone ."self clusterListPresenter selectedItem ifNotNil: [
												          self missionListPresenter selectedItem
													          assignToCluster:
														          self clusterListPresenter selectedItem" ] ];
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Focus Off';
							          iconName: #start;
							          description:
								          'Focus on the selected cluster by changing the battle zone';
							          action: [
									          self battleZone ."self clusterListPresenter selectedItem ifNotNil: [
												          self missionListPresenter selectedItem
													          assignToCluster:
														          self clusterListPresenter selectedItem" ] ] ;
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Choose color';
							          iconName: #start;
							          action: [
									          SpDroneColorPickerPresenter new
										          colorSelector: #color:;
										          target: self clusterListPresenter selectedItem; open ] ];
				          yourself.

		 
]

{ #category : 'Menus' }
UISimulation >> buildDevMenu [

	^ SpMenuPresenter new
		  addItem: [ :it |
				  it
					  name: 'Inspect';
					  icon: (self iconNamed: #inspect);
					  action: [ self inspect ] ];
		  yourself
]

{ #category : 'presenters-building' }
UISimulation >> buildDroneListPresenter [

	^ droneListPresenter
		  ifNil: [
				  self droneListPresenter: (self newList display: [ :c |
								   c ifNil: [ '' ] ifNotNil: [ 'Drone ' , c id asString ] ]) ];
		  yourself
]

{ #category : 'presenters-building' }
UISimulation >> buildDroneModePanel [
    "Panel radio Drones (All | Selected)"
    dronesAllButton ifNil: [ dronesAllButton := self   newRadioButton ]. dronesAllButton inspect.
    dronesSelectedButton ifNil: [ dronesSelectedButton := self newRadioButton ].
    dronesModeLabel ifNil: [ dronesModeLabel := self newLabel ].

    dronesAllButton associatedRadioButtons: { dronesSelectedButton }.
    dronesAllButton label: 'All'.
    dronesSelectedButton label: 'Selected'.

    "État initial (showAllDrones doit être un slot booléen)"
    showAllDrones ifNil: [ showAllDrones := true ].
    dronesAllButton state: showAllDrones.
    dronesSelectedButton state: showAllDrones not.

    "Callbacks"
    dronesAllButton whenChangedDo: [
        showAllDrones := true.
        self updateDroneListFromSelectedClusters.
        self refreshDrones ].
    dronesSelectedButton whenChangedDo: [
        showAllDrones := false.
        self updateDroneListFromSelectedClusters.
        self refreshDrones ].

    ^ (self newPresenter)
        layout: (SpBoxLayout newTopToBottom
            add: (SpBoxLayout newTopToBottom
                    add: dronesAllButton expand: false;
                    add: dronesSelectedButton expand: false;
                    yourself)
                expand: false;
            yourself)
]

{ #category : 'presenters-building' }
UISimulation >> buildFallbackBaseMap [
    | rect |
    rect := RSBox new
        width: self imageSize x;
        height: self imageSize y;
        color: Color veryLightGray;
        yourself.
    self addBaseShape: rect.
]

{ #category : 'Menus' }
UISimulation >> buildMenuBar [

	| menuBar   simMenu zoomMenu importMenu waypointsMenu devMenu |
 
	menuBar := self newMenuBar.

	"Simulation"
	simMenu := self buildSimulationMenu.
	"Zoom"
	zoomMenu := self buildZoomMenu.
	"Import CSV"
	importMenu := self buildCSVMenu.
	"Capture WP"
	waypointsMenu := self buildWaypointsMenu.
	devMenu := self buildDevMenu.

	menuBar addGroup: [ :group |
			group addItem: [ :it |
					it
						name: 'Simulation';
						subMenu: simMenu ].
			group addItem: [ :it |
					it
						name: 'Zoom';
						subMenu: zoomMenu ].
			group addItem: [ :it |
					it
						name: 'Import';
						subMenu: importMenu ].
			group addItem: [ :it |
					it
						name: 'Waypoints';
						subMenu: waypointsMenu ].
			group addItem: [ :it |
					it
						name: 'Developpement';
						subMenu: devMenu ] ].

	menuBarPresenter := menuBar.
	^ menuBarPresenter
]

{ #category : 'presenters-building' }
UISimulation >> buildMissionListPresenter [

	| menu |
	^ missionListPresenter ifNil: [
			  menu := self buildMissionListPresenterMenu.

			  self
				  missionListPresenter: (self newList
						   display: [ :m |
							   m
								   ifNil: [ '' ]
								   ifNotNil: [   m class printString, ' id:', m id printString ] ];
						   actions: menu);
				  yourself ]
]

{ #category : 'Menus' }
UISimulation >> buildMissionListPresenterMenu [

^ SpActionGroup new
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Assign to cluster';
							          iconName: #start;
							          description:
								          'Assign the current mission to the selected cluster';
							          action: [
									          self clusterListPresenter selectedItem ifNotNil: [
												          self missionListPresenter selectedItem
													          assignToCluster:
														          self clusterListPresenter selectedItem ] ] ];
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Activate';
							          iconName: #start;
							          action: [
									          simulator scheduleEvent:
											          (MissionStartEvent model:
													           self missionListPresenter selectedItem) ] ];
				          addActionWith: [ :anItem |
						          anItem
							          name: 'Choose color';
							          iconName: #start;
							          action: [
									          SpDroneColorPickerPresenter new
										          colorSelector: #color:;
										          target: self missionListPresenter selectedItem; open ] ];
				          yourself.
 
]

{ #category : 'presenters-building' }
UISimulation >> buildScriptPresenter [

 
	| clearButton runButton saveButton readButton |
	scriptPresenter := self instantiate: SpTextInputFieldPresenter.
	clearButton := self newButton
		               label: 'Clear';
		 iconName: #trash;
		               action: [ self clearScript ].
	runButton := self newButton
		               label: 'Run';
		 iconName: #go;
		               action: [ self runScript ].
		  
	saveButton := self newButton
		              label: 'Save';
				iconName: #glamorousSave;
		              action: [ self saveScript ].
	readButton := self newButton
		              label: 'Load';
				iconName: #catalog;
		              action: [ self loadScript ].
	^ self newPresenter layout: (SpBoxLayout newTopToBottom
			   add: (SpBoxLayout newLeftToRight
					    add: runButton    withConstraints: [ :constraints | constraints height: 20; width:  60]  ;
					    add: clearButton   withConstraints: [ :constraints | constraints height: 20; width:  60] ;
					    add: readButton    withConstraints: [ :constraints | constraints height: 20; width:  60];
					    add: saveButton    withConstraints: [ :constraints | constraints height: 20; width:  60];
					    yourself)
			   expand: false;
			   add: scriptPresenter  withConstraints: [ :constraints | constraints height: 150  ];  
			   yourself)
]

{ #category : 'Menus' }
UISimulation >> buildSimulationMenu [

	^ SpMenuPresenter new
		  addItem: [ :it |
				  it
					  name: 'Start';
					  icon: (self iconNamed: #play);
					  action: [ self runSimulationLoop ] ];
		  addItem: [ :it |
				  it
					  name: 'Stop';
					  icon: (self iconNamed: #pause);
					  action: [ self stopSimulationLoop ] ];
		  addItem: [ :it |
				  it
					  name: 'Run steps';
					  icon: (self iconNamed: #smallDoIt);
					  action: [
							  self
								  simulationMenuItem: 'Provide nb steps'
								  do: [ :nb | self runSimulationSteps: nb ] ] ];
		  addItem: [ :it |
				  it
					  name: 'Run to date';
					  icon: (self iconNamed: #smallProfile);
					  action: [
							  self
								  simulationMenuItem: 'Provide timestamp'
								  do: [ :nb | self runSimulationLoopUntilTimestamp: nb ] ] ];
		  addItem: [ :it |
				  it
					  name: 'HaltOn';
					  icon: (self iconNamed: #breakpoint);
					  action: [
							  self
								  simulationMenuItem: 'Provide condition'
								  do: [ :blk | self runSimulationLoopUntilCondition: blk ] ] ];
		    
		  addItem: [ :it |
				  it
					  name: 'Save frames';
					  icon: (self iconNamed: #enable);
					  action: [ self generateVideo: true ] ];
		  addItem: [ :it |
				  it
					  name: 'Neglect frames';
					  icon: (self iconNamed: #disable);
					  action: [ self generateVideo: false ] ];
						  addItem: [ :it |
				  it
					  name: 'Generate video from frames';
					  icon: (self iconNamed: #window);
					  action: [ self saveVideo  ] ];
		  yourself
]

{ #category : 'presenters-building' }
UISimulation >> buildStatusLabel [
    statusLabelPresenter ifNotNil: [ ^ statusLabelPresenter ].
    statusLabelPresenter := SpLabelPresenter new label: 'Ready'.
    ^ statusLabelPresenter.
]

{ #category : 'presenters-building' }
UISimulation >> buildTimeLabel [

 timeLabelPresenter ifNil: [timeLabelPresenter :=self   instantiate: SpLabelPresenter. ].
 ^timeLabelPresenter 
]

{ #category : 'Menus' }
UISimulation >> buildWaypointsMenu [

	^ SpMenuPresenter new
		  addItem: [ :it |
				  it
					  name: 'Start';
					  icon: (self iconNamed: #add);
					  action: [ self startWaypointCapture ] ];
		  addItem: [ :it |
				  it
					  name: 'Commit';
					  icon: (self iconNamed: #accept);
					  action: [ self commitPendingWaypoints ] ];
		  addItem: [ :it |
				  it
					  name: 'Cancel';
					  icon: (self iconNamed: #cancel);
					  action: [ self clearPendingWaypoints ] ];
		   
		  yourself
]

{ #category : 'Menus' }
UISimulation >> buildZoomMenu [

	^ SpMenuPresenter new
		  addItem: [ :it |
				  it
					  name: 'Fit';
					  icon: (self iconNamed: #smallFind);
					  action: [ self fitZoom ] ];
		  addItem: [ :it |
				  it
					  name: 'Zoom +';
					  icon: (self iconNamed: #glamorousZoomIn);
					  action: [ self zoomIn ] ];
		  addItem: [ :it |
				  it
					  name: 'Zoom -';
					  icon: (self iconNamed: #glamorousZoomOut);
					  action: [ self zoomOut ] ];
		  addItem: [ :it |
				  it
					  name: 'Custom';
					  icon: (self iconNamed: #smallFind);
					  action: [ self customZoom ] ];
		  yourself
]

{ #category : 'canvas' }
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

{ #category : 'CSV' }
UISimulation >> chooseCSVFileLabel: aLabel [
    (Smalltalk includesKey: #UIManager) ifFalse: [ ^ nil ].
    ^ (UIManager default chooseFullFileNameMatching: #('*.csv') label: aLabel)
        ifNotNil: [ :path | path asFileReference ]
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

{ #category : 'scripting' }
UISimulation >> clearScript [

scriptPresenter text:''

]

{ #category : 'closing' }
UISimulation >> close [ 
self isRunning: false.
^ super close 

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

{ #category : 'canvas' }
UISimulation >> clusterShapes [

	clusterShapes ifNil: [ clusterShapes := Dictionary new ].
	^ clusterShapes
]

{ #category : 'debugging' }
UISimulation >> clustersFromSimulation [
     | fleets |   (simulation respondsTo: #clusters) ifTrue: [ ^ simulation clusters ifNil: [ #() ] ].

    ^simulation allFleets   gather: [ :f | (f respondsTo: #clusters) ifTrue: [ f clusters ] ifFalse: [ #() ] ]

]

{ #category : 'waypoints' }
UISimulation >> commitPendingWaypoints [

self halt. 
    pendingWaypoints isEmpty
        ifTrue: [ ^ self status: 'No WP' ].
    "Brancher la logique métier ici."
    self status: 'Committed ', pendingWaypoints size printString, ' WP'.
    self stopWaypointCapture.
    self refreshOverlays.
]

{ #category : 'presenters' }
UISimulation >> computeBoundingBox [

	| points latMin latMax lonMin lonMax padLat padLon tmp |
	  "1. Collecte des points source (battleZone sinon dérive des drones)"
	points := "(simulation respondsTo: #battleZone)   
		          ifTrue: [ simulation battleZone ]
		          ifFalse: [ nil ]." nil.
	(points isNil or: [ points isEmpty ]) ifTrue: [
			points := (simulation allDrones collect: [ :d |
					           ((d respondsTo: #latitude) and: [
						            d respondsTo: #longitude ])
						           ifTrue: [
						           GeoPoint
							           latitude: d latitude
							           longitude: d longitude
							           altitude: 0 ]
						           ifFalse: [ nil ] ]) reject: #isNil ]. self model missions do:[:m| points addAll: m polygon].
	 (points isNil or: [ points isEmpty ])  ifTrue: [ "Fallback constant (France approx.)"
			points := {
				          (GeoPoint latitude: 51.2 longitude: -5 altitude: 0).
				          (GeoPoint latitude: 41.0 longitude: 9 altitude: 0).
				          (GeoPoint latitude: 41.0 longitude: -5 altitude: 0).
				          (GeoPoint latitude: 51.2 longitude: 9 altitude: 0) } ].

	self forceBoundingBox: points
]

{ #category : 'presenters' }
UISimulation >> computeBoundingBoxOld [

	| points latMin latMax lonMin lonMax padLat padLon tmp |
	  "1. Collecte des points source (battleZone sinon dérive des drones)"
	points := "(simulation respondsTo: #battleZone)" false
		          ifTrue: [ simulation battleZone ]
		          ifFalse: [ nil ].
	(points isNil or: [ points isEmpty ]) ifTrue: [
			points := (simulation allDrones collect: [ :d |
					           ((d respondsTo: #latitude) and: [
						            d respondsTo: #longitude ])
						           ifTrue: [
						           GeoPoint
							           latitude: d latitude
							           longitude: d longitude
							           altitude: 0 ]
						           ifFalse: [ nil ] ]) reject: #isNil ].
	"(points isNil or: [ points isEmpty ])" true ifTrue: [ "Fallback constant (France approx.)"
			points := {
				          (GeoPoint latitude: 51.2 longitude: -5 altitude: 0).
				          (GeoPoint latitude: 41.0 longitude: 9 altitude: 0).
				          (GeoPoint latitude: 41.0 longitude: -5 altitude: 0).
				          (GeoPoint latitude: 51.2 longitude: 9 altitude: 0) } ].

	"2. Min / Max"
	latMin := latMax := points first latitude.
	lonMin := lonMax := points first longitude.
	points do: [ :gp |
			latMin := latMin min: gp latitude.
			latMax := latMax max: gp latitude.
			lonMin := lonMin min: gp longitude.
			lonMax := lonMax max: gp longitude ].

	"3. Padding 5% (évite bords collés); si delta nul, impose petite aire."
	latMax = latMin ifTrue: [
			latMax := latMax + 0.05.
			latMin := latMin - 0.05 ].
	lonMax = lonMin ifTrue: [
			lonMax := lonMax + 0.05.
			lonMin := lonMin - 0.05 ].
	padLat := latMax - latMin * 0.05.
	padLon := lonMax - lonMin * 0.05.
	latMax := latMax + padLat.
	latMin := latMin - padLat.
	lonMax := lonMax + padLon.
	lonMin := lonMin - padLon.

	"4. Conversion WebMercator -> bboxBase"
	tmp := (self class lonLatToWebMercator: lonMin @ latMax) corner:
		       (self class lonLatToWebMercator: lonMax @ latMin).
	bboxBase = tmp ifTrue: [ ^ self ]. "beLazy"
	bboxBase := tmp.
	"5. Applique le zoom"
	self updateZoomedBBox.
	self computeImageSize "recalcule imageSize dépendant du nouveau bbox"
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
    (Smalltalk includesKey: #RSMouseRightClick) ifTrue: [
        rsCanvas when: RSMouseRightClick do: [ :evt |
            self startOrStopHandlingWaypoints ] for: self ].
]

{ #category : 'presenters' }
UISimulation >> connectDroneModePresenters [

	dronesAllButton whenChangedDo: [
			showAllDrones := true.
			self updateDronesModeLabel.
			self updateDroneListFromSelectedClusters.
			self refreshDrones ].
	dronesSelectedButton whenChangedDo: [
			showAllDrones := false.
			self updateDronesModeLabel.
			self updateDroneListFromSelectedClusters.
			self refreshDrones ]
]

{ #category : 'Simulation control' }
UISimulation >> currentTime [

	currentTime ifNil: [ currentTime := 0 ].
	^ currentTime
]

{ #category : 'Simulation control' }
UISimulation >> currentTime: aValue [

	currentTime := aValue
]

{ #category : 'zoom animation' }
UISimulation >> customZoom [

| presenter |
	presenter := SpRequestDialog new.
	presenter
		title: 'Zoom';
		label: 'Custom zoom';
		text: self zoomLevel asFloat printString;
		acceptLabel: 'Set';
		cancelLabel: 'Cancel';
		onAccept: [ :dialog |   self zoomLevel: dialog presenter text asNumber ];
		openDialog
		 
]

{ #category : 'accessing' }
UISimulation >> defaultImageWidth [

^1600
]

{ #category : 'layout' }
UISimulation >> defaultLayout [

	| right |
	self buildMenuBar. "assure menuBarPresenter"

	right := self newPresenter.
	right layout: (SpBoxLayout newTopToBottom
			 spacing: 6;
			 add: self buildDroneModePanel height:50;
			 add: self buildCheckList height:40;
			 "			 add: self buildOverlayChecksPanel expand: false;""Missions/Hull/Ammunition/Fuel"
			 add: missionListPresenter;
			 add: clusterListPresenter;
			 add: droneListPresenter;
			 add: self buildScriptPresenter height: 120;
			 add: statusLabelPresenter height: 20;
			 add: timeLabelPresenter height: 20;
			 yourself).
	^ SpBoxLayout newTopToBottom
		  spacing: 2;
		  add: menuBarPresenter height: 20;
		  add: (SpPanedLayout newLeftToRight
				   positionOfSlider: 20 percent;
				   add: canvasPresenter;
				   add: right;
				   yourself);
		  yourself
]

{ #category : 'accessing' }
UISimulation >> dirForVideos [


^	(FileSystem workingDirectory / 'frames')
]

{ #category : 'overlays' }
UISimulation >> drawAmmoOverlayFor:  d at: p [

	| s |
	s := self ensureDroneShapes: d.
	(self  overlayModel  showAmmoBars ) ifTrue:	[s ammunitions ifNil: [
			s ammunitions: (RSBox new
					 width: (d capabilities availablePercentage: #ammunitions) * 20 ;
					 height: 5;
					 color: Color transparent;
					 yourself).

			rsCanvas add: s ammunitions ].
	s ammunitions translateTo: p x @ (p y + 10)]
]

{ #category : 'overlays' }
UISimulation >> drawClusterOverlayFor: c [

	| points pts poly s |
	s := self undrawClusterOverlayFor: c.

self overlayModel showClusterHull ifTrue:[



	points := (c drones reject:[:d| d isDestroyed]) collect: [ :d |
		         (self pixelForDrone: d) ].

	pts := points size > 2
		       ifTrue: [ ConvexHullCalculator new hullForPoints: points ]
		       ifFalse: [ #(  ) ].



	pts size > 2 ifTrue: [
			poly := RSPolygon new
				        points: pts;
				        color: c color;
				        borderColor: (Color red alpha: 0.2);
				        borderWidth: 1;
				        yourself. "(Color red alpha: 0.07);
						        borderColor: (Color red alpha: 0.4)"
			"poly moveTo: (self pixelForDrone: c drones first)."


			s hull: poly.
			rsCanvas addShape: poly ] "rsCanvas signalUpdate"]
]

{ #category : 'presenters' }
UISimulation >> drawDroneIcons [
    | drones |
    rsCanvas ifNil: [ ^ self ].
   drones := self    allDrones.
    drones isEmpty ifTrue: [ ^ self ].
    drones do: [ :d |
        | p     |
        p := self pixelForDrone: d.
        p ifNil: [ ^ self ].
       self drawDroneIconsFor:d at:p. rsCanvas signalUpdate .
       self drawDroneIconsTextFor:d at:p.].
 
]

{ #category : 'overlays' }
UISimulation >> drawDroneIconsFor: d at: p [

	| dot s |
	s := self ensureDroneShapes: d.
	s position ifNil: [
			dot := RSBox new model: d;
				       extent: 8 @ 8;
				       color: Color black;
				       yourself. "transparent"
			s position: dot. "s is a DroneShape"
			dot
			@ (RSLabeled new text: [ :model | 'id = ' , model id asString ]).
			dot @ RSHighlightable  color:Color yellow .
			dot @ (RSMenuActivable new menuDo: [ :aMenuMorph :aRSNode |
					 aMenuMorph "title:'Actions over ',aRSNode model id printString;" addLine; 
						 add: 'Inspect'
						 target: aRSNode
						 selector: #inspect 
						 argument: #(  ).
					 aMenuMorph
						 add: 'Destroy'
						 target: self simulator
						 selector: #scheduleEvent:
						 argument: ( DestructionEvent new drone: aRSNode model ) ]).
			self markOverlayShape: dot.

			rsCanvas add: dot ].
	"dot is a Shape"
	s position translateTo: p
]

{ #category : 'overlays' }
UISimulation >> drawEnergyOverlayFor: d at: p [

	| s pie ratio |
	s := self ensureDroneShapes: d.
	(self  overlayModel  showEnergyBars ) ifTrue:	[s energy ifNil: [
			ratio := d capabilities availablePercentage: #energy.


			pie := RSPieSlice new
				       model: d capabilities energy;
				       alphaAngle: 180;
				       color: Color transparent;
				       "borderColoapabilitiesr: Color transparent;"
				       betaAngle: 180;
				       innerRadius: 5;
				       cornerRadii: 0;
				       externalRadius: 10;
				       position: 50 @ -50;
				       yourself.

			s energy: pie.



			self markOverlayShape: pie.
			rsCanvas add: pie ].
	s energy
		alphaAngle:    180* (1-(d capabilities availablePercentage: #energy));
		translateTo: p - s energy externalRadius]
]

{ #category : 'overlays' }
UISimulation >> drawMissionOverlayFor: m [

	|  poly s |
	s := self undrawMissionOverlayFor: m.
		self overlayModel showMissionPaths ifTrue:[	poly := RSPolygon new
				        points: 	(m   polygon collect:[:p | self pixelForDrone: p]);
				        color: (m getColor);
				        borderWidth: 3; borderColor: (m getBorderColor);
				        yourself.  


			s hull: poly.
			rsCanvas addShape: poly ]
]

{ #category : 'overlays' }
UISimulation >> drawPerceptionOverlayFor: d at: p [

	| dot s |
	s := self ensureDroneShapes: d.
(self  overlayModel showPerceptionRadius) ifTrue:	[s perceptionRange ifNil: [
			dot := RSCircle new
				       radius: (d capabilities perceptionRange) / 2;
				       color: Color transparent;
				       borderColor: (Color lightBlue alpha: 0.4);
				       yourself.

			s perceptionRange: dot.
			self markOverlayShape: dot.
 
			rsCanvas add: dot ].

	s perceptionRange translateTo: p]
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

{ #category : 'canvas' }
UISimulation >> droneShapes [

droneShapes ifNil:[droneShapes := Dictionary new].
^droneShapes
]

{ #category : 'overlay models' }
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

	rsCanvas := RSCanvas new @ RSScrollBarsCanvasInteraction.
	self ensureBattleZoneFromDrones.
	 
	self bbox.
	self computeImageSize.

	self ensureBaseShapes.
	self buildBaseMap.
	self connectCanvasEvents.
	self installSelectionZoomOn: rsCanvas.

	^ rsCanvas
]

{ #category : 'overlays' }
UISimulation >> ensureClusterShapes: c [  
	 ^self clusterShapes at: c ifAbsentPut: [ ClusterShapes newFor: c ].
	 
]

{ #category : 'overlays' }
UISimulation >> ensureDroneShapes: d [  
	 ^self droneShapes at: d ifAbsentPut: [ DroneShapes newFor: d ].
	 
]

{ #category : 'overlays' }
UISimulation >> ensureMissionShapes: m [  
	 ^self clusterShapes at: m ifAbsentPut: [ MissionShapes newFor: m ].
	 
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
                    showAmmoBars: true;
                    showClusterHull: true;
                    yourself ]
            ifFalse: [ Dictionary new ] ]
]

{ #category : 'canvas' }
UISimulation >> fetchBitmapFromWMS [

	| wms bmp operations getmap layers map |
	rsCanvas ifNil: [ ^ self ].
	[ (Smalltalk at: #OWSServiceWMS) new ]
		on: Error
		do: [ ^ self ].
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
	rsCanvas add: bmp
]

{ #category : 'Menus' }
UISimulation >> fitZoom [

	bbox := nil.
	self computeBoundingBox.
	zoomLevel := 1.0.
	self markBaseMapDirty.
	self refreshAll
]

{ #category : 'presenters' }
UISimulation >> forceBoundingBox: points [

	| latMin latMax lonMin lonMax padLat padLon tmp |
	"2. Min / Max"
	latMin := latMax := points first latitude.
	lonMin := lonMax := points first longitude.
	points do: [ :gp |
			latMin := latMin min: gp latitude.
			latMax := latMax max: gp latitude.
			lonMin := lonMin min: gp longitude.
			lonMax := lonMax max: gp longitude ].

	"3. Padding 5% (évite bords collés); si delta nul, impose petite aire."
	latMax = latMin ifTrue: [
			latMax := latMax + 0.05.
			latMin := latMin - 0.05 ].
	lonMax = lonMin ifTrue: [
			lonMax := lonMax + 0.05.
			lonMin := lonMin - 0.05 ].
	padLat := latMax - latMin * 0.05.
	padLon := lonMax - lonMin * 0.25.
	latMax := latMax + padLat.
	latMin := latMin - padLat.
	lonMax := lonMax + padLon.
	lonMin := lonMin - padLon.
	tmp := (self class lonLatToWebMercator: lonMin @ latMax) corner:
		       (self class lonLatToWebMercator: lonMax @ latMin).



	bboxBase = tmp ifTrue: [ bbox ifNotNil: [ ^ self ] ]. "beLazy"
	bboxBase := tmp.
	"5. Applique le zoom"
	self updateZoomedBBox.
	self computeImageSize. "recalcule imageSize dépendant du nouveau bbox"
	self markBaseMapDirty.
	self refreshAll
]

{ #category : 'presenters' }
UISimulation >> forceRawBoundingBox: points [

	| latMin latMax lonMin lonMax     tmp |
	"2. Min / Max"
	latMin := latMax := points first y.
	lonMin := lonMax := points first x.
	points do: [ :gp |
			latMin := latMin min: gp y.
			latMax := latMax max: gp y.
			lonMin := lonMin min: gp x.
			lonMax := lonMax max: gp x ].

	"3. Padding 5% (évite bords collés); si delta nul, impose petite aire."
	 
	tmp := Rectangle origin: lonMin @ latMax corner:
		        lonMax @ latMin.



	bboxBase = tmp ifTrue: [ bbox ifNotNil: [ ^ self ] ]. "beLazy"
	bboxBase := tmp.
	"5. Applique le zoom"
	self updateZoomedBBox.
	self computeImageSize. "recalcule imageSize dépendant du nouveau bbox"
	self markBaseMapDirty.
	self refreshAll
]

{ #category : 'updating status' }
UISimulation >> fullDroneRefresh [
    self computeBoundingBox.
    self markBaseMapDirty.
    self refreshAll.
]

{ #category : 'accessing' }
UISimulation >> generateVideo [

	generateVideo ifNil: [ self generateVideo: false ].
	^ generateVideo
]

{ #category : 'accessing' }
UISimulation >> generateVideo: aBool [

	self dirForVideos ensureCreateDirectory.
	generateVideo := aBool
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
self halt. 
    (Smalltalk includesKey: #Waypoint) ifFalse: [ ^ self ].
    wpClass := Waypoint.
    geo := self physicalLonLatFromPixel:  (self pixelFromCanvasPoint: evt positionFromCamera).
 
    geo ifNil: [ ^ self ].
    wp := wpClass latitude: geo y longitude: geo x altitude: 100.
    pendingWaypoints add: wp.
    self drawTempWaypoint: wp.
    self status: 'WP count: ', pendingWaypoints size printString.

 
]

{ #category : 'presenters' }
UISimulation >> hideDrone: aDrone [
   (self  droneShapes  at: aDrone) hideAll
]

{ #category : 'presenters' }
UISimulation >> hideShapes [
   self  droneShapes  values do:[:a| a hideAll].
   
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

{ #category : 'CSV' }
UISimulation >> importClustersFromCSV: aFileRef [

	| rows groups clusters |
	rows := self readCSVLinesFrom: aFileRef.
	rows isEmpty ifTrue: [ ^ self ].
	groups := Dictionary new.
	(rows reject: [ :a | a first = 'clusterId' ]) do: [ :cols |
			| cid |
			cid := cols first asNumber.
			(groups at: cid ifAbsentPut: [ OrderedCollection new ]) add: cols ].
	clusters := groups keys collect: [ :cid |
			            | lines cluster droneClass |
			            lines := groups at: cid.
			            cluster := DroneCluster new id: cid.
			            lines do: [ :cols |
					            | id lat lon alt d |
					            id := cols second.
					            lat := cols third asNumber.
					            lon := (cols at: 4) asNumber.
					            alt := (cols at: 5 ifAbsent: [ 100 ]) asNumber.
					            d := Drone new
						                 initializeWithId: id
						                 latitude: lat
						                 longitude: lon
						                 altitude: alt.
					            cluster addDrone: d ].
			            (cluster respondsTo: #clusterId:) ifTrue: [
				            cluster clusterId: cid ].
			            cluster ].
	self attachImportedClusters: (clusters reject: #isNil).
	self updateClusterListFromFleet.
	self updateDroneListFromSelectedClusters.
	self computeBoundingBox. "update map"
	self refreshDrones
]

{ #category : 'CSV' }
UISimulation >> importClustersFromCSVDialog [
    | file |
    file := self chooseCSVFileLabel: 'Clusters CSV'.
    file ifNil: [ ^ self ].
    self importClustersFromCSV: file.
]

{ #category : 'presenters' }
UISimulation >> importMenu [
    | m |
    m := SpMenuPresenter new.
    m addItem: [ :it | it name: 'Clusters CSV…'; action: [ self importClustersFromCSVDialog ] ].
    m addItem: [ :it | it name: 'Missions CSV…'; action: [ self importMissionsFromCSVDialog ] ].
    ^ m
]

{ #category : 'CSV' }
UISimulation >> importMissionsFromCSV: aFileRef [

	| rows missionClass p mission |
	rows := self readCSVLinesFrom: aFileRef.
	rows isEmpty ifTrue: [ ^ self ].
	missionClass := Smalltalk at: rows first first asSymbol.

	mission := missionClass new id: rows first second.
	p := OrderedCollection new.
	rows allButFirstDo: [ :cols |
		p add: (Waypoint with: (cols collect: [ :v | v asNumber ])) ].
	mission points: p.
	simulator model addMission: mission.
	missionListPresenter items: missionListPresenter items "force refresh".
	self computeBoundingBox "update map"
]

{ #category : 'CSV' }
UISimulation >> importMissionsFromCSVDialog [
    | file |
    file := self chooseCSVFileLabel: 'Missions CSV'.
    file ifNil: [ ^ self ].
    self importMissionsFromCSV: file.
]

{ #category : 'initializing' }
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
 
	haltOnError := false.
	showAllDrones := true.
	self clusterListPresenter  items: self model allClusters.
	self missionListPresenter  items: self model missions.
	self
		ensureOverlayModel;
		ensureOverlayChecks;
		ensureBaseShapes
]

{ #category : 'initializing' }
UISimulation >> initializePresenters [
	"Build all presenters (no layout here)."

	"Canvas"

	 self ensureCanvas.
	self buildCanvasPresenter.
	self buildStatusLabel.
	self buildScriptPresenter.
	self buildCheckList.
	self buildTimeLabel.



	"Lists and status"
	self
		buildClusterListPresenter;
		buildDroneListPresenter;
		buildMissionListPresenter.


	"Link lists (refresh drones on cluster selection change)"
	clusterListPresenter whenSelectionChangedDo: [
			self updateDroneListFromSelectedClusters.
			self refreshDrones ]
]

{ #category : 'Simulation control' }
UISimulation >> initializeSimulation [

	self isRunning: true.
	self refreshUIDuringSimulation
]

{ #category : 'canvas' }
UISimulation >> installSelectionZoomOn: canvas [
	"Mouse down: création du rectangle"

	canvas
		when: RSKeyDown 
		do: [ :evt | evt keyName=#ESCAPE ifTrue:[selectionRectangle ifNotNil:[  selectionRectangle remove. selectionRectangle := nil . 
				canvas signalUpdate]]]
		for: self.

	canvas
		when: RSMouseClick
		do: [ :evt |
				| selectionStartPoint |
				selectionStartPoint := evt position.
				selectionRectangle ifNotNil: [  selectionRectangle remove. self zoomOn: selectionRectangle. selectionRectangle := nil]
				ifNil:[selectionRectangle := RSBox new
					                      position: selectionStartPoint;
					                      size: 1 @ 1;
					                      color: (Color blue alpha: 0.15);
					                      border: (RSBorder new
							                       color: Color blue;
							                       width: 1);
					                      yourself.

				canvas add: selectionRectangle.].

				canvas signalUpdate ]
		for: self.

 
	canvas
		when: RSMouseMove
		do: [ :evt |
				| endPoint minX minY maxX maxY selectionStartPoint selectionExtent|
				selectionRectangle ifNotNil:[selectionStartPoint := selectionRectangle position -( selectionRectangle extent/2).
				endPoint := evt position   .
				minX := selectionStartPoint x min: endPoint x.
				minY := selectionStartPoint y min: endPoint y.
				maxX := selectionStartPoint x max: endPoint x.
				maxY := selectionStartPoint y max: endPoint y.
				selectionExtent := maxX - minX @ (maxY - minY).
	
				selectionRectangle size: selectionExtent.
							selectionRectangle position: minX @ minY + (selectionExtent /2) .

				canvas signalUpdate] ]
		for: self
]

{ #category : 'presenters' }
UISimulation >> isBaseShape: aShape [
    ^ baseShapes notNil and: [ baseShapes includes: aShape ]

]

{ #category : 'overlays' }
UISimulation >> isDirty: field of: aDrone [

	(self droneShapes at: aDrone) reset: field
]

{ #category : 'presenters' }
UISimulation >> isOverlayShape: aShape [
    ^ overlayShapes notNil and: [ overlayShapes includes: aShape ]
]

{ #category : 'Simulation control' }
UISimulation >> isRunning [

	^ self simulator isRunning
]

{ #category : 'Simulation control' }
UISimulation >> isRunning: aBool [

	^ self simulator isRunning: aBool
]

{ #category : 'Simulation control' }
UISimulation >> jumpDialog: aText do: aBloc [
| presenter n |
	presenter := SpRequestDialog new.
	presenter
		title: 'Simulation';
		label: aText;
		text: '1';
		acceptLabel: 'step ahead';
		cancelLabel: 'Cancel';
		onAccept: [ :dialog | n :=   dialog presenter text  . n isEmpty ifTrue: [ aBloc value: n
 ]];
		openDialog.
    
]

{ #category : 'scripting' }
UISimulation >> loadScript [
self scriptPresenter updateTextFromModel: 'test'
]

{ #category : 'Simulation control' }
UISimulation >> loadSimulationDialog [
    | ref |
    (Smalltalk includesKey: #UIManager)
        ifFalse: [ ^ self ].
    ref := UIManager default
        request: 'Fichier à charger (.fuel)'.
    ref ifNil: [ ^ self ].
    self loadSimulationFrom: ref asFileReference.
]

{ #category : 'Simulation control' }
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

{ #category : 'accessing' }
UISimulation >> missionListPresenter [

	^ missionListPresenter
]

{ #category : 'accessing' }
UISimulation >> missionListPresenter: anObject [
missionListPresenter := anObject
]

{ #category : 'accessing' }
UISimulation >> model [

	^ self simulation
]

{ #category : 'presenters' }
UISimulation >> open [
"    self layout ifNil: ["
        self initializePresenters.
        self layout: self defaultLayout "]".
    ^ (super open)
        withWindowDo: [ :w | w title: ('Drones Simulation— ', ("simulation" nil  ifNil: [ 'No scenario' ] ifNotNil: [ simulation class name ])) ]
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

{ #category : 'presenters' }
UISimulation >> overlayShapes [ 

overlayShapes ifNil:[overlayShapes := IdentityDictionary new]. "indexed by drone"
^overlayShapes
]

{ #category : 'accessing' }
UISimulation >> pendingWaypoints [

	^ pendingWaypoints
]

{ #category : 'accessing' }
UISimulation >> pendingWaypoints: anObject [

	pendingWaypoints := anObject
]

{ #category : 'canvas' }
UISimulation >> physicalLonLatFromPixel: pixel [
    "Approx inverse WebMercator (lat reconstruction simplifiée)."
    | xMin yMin xMax yMax lon lat |
    self bbox ifNil: [ ^ nil ].
    xMin := bbox origin x. yMin := bbox origin y.
    xMax := bbox corner x. yMax := bbox corner y.
    lon :=  (xMax - xMin) * (pixel x / self imageSize x) + xMin.
    lat := yMax - ((yMax - yMin) * (pixel y / self imageSize y)).
    
    ^self class webMercatorToLongitureLatitude: lon @ lat.
]

{ #category : 'canvas' }
UISimulation >> pixelForCanvasPoint: pixelPoint [
    | w h |
    w := self imageSize x asFloat.
    h := self imageSize y asFloat.
    "Roassal: on centre => x' = x - w/2 ; y' = (h/2) - y (inversion verticale)."
    ^ (pixelPoint x - (w / 2)) @ ((h / 2) - pixelPoint y)
]

{ #category : 'canvas' }
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

{ #category : 'canvas' }
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

{ #category : 'canvas' }
UISimulation >> pixelFromCanvasPoint: pixelPoint [
    | w h p |
    w := self imageSize x asFloat.
    h := self imageSize y asFloat.
    "Roassal: on centre => x' = x - w/2 ; y' = (h/2) - y (inversion verticale)."
  "  ^ pixelPoint x +(h/2) @ ( (h/2)- pixelPoint y)"

 
p :=  pixelPoint x +(h/2) @ ( (h/2)+ pixelPoint y).
 
^p
]

{ #category : 'zoom animation' }
UISimulation >> postZoomRefresh [

	self resetDroneShapes.
	self markBaseMapDirty.
	self refreshAll
]

{ #category : 'CSV' }
UISimulation >> readCSVLinesFrom: aFileRef [
    | rows |
    (Smalltalk includesKey: #NeoCSVReader) ifTrue: [ ^ self readCSVWithNeoFrom: aFileRef ].
    rows := OrderedCollection new.
    aFileRef readStreamDo: [ :str |
        [ str atEnd ] whileFalse: [
            | line cols |
            line := str nextLine.
            (line isEmpty or: [ line first = $# ])
                ifTrue: [ "skip comment/empty" ]
                ifFalse: [
                    cols := line findTokens: ','.
                    rows add: cols ] ] ].
    ^ rows
]

{ #category : 'CSV' }
UISimulation >> readCSVWithNeoFrom: aFileRef [
    | allLines headerLine headerTokens reader stream rows fieldAdder |
    "1) Lire toutes les lignes (simple) pour détecter un header sans utiliser #peek."
     allLines := aFileRef readStream contents lines.
    "Filtrer commentaires (#...) et vides pour trouver une éventuelle première ligne d'en-tête."
    headerLine := allLines
        detect: [ :ln | ln notEmpty and: [ ln first ~= $# ] ]
        ifNone: [ nil ].
    headerTokens := headerLine
        ifNil: [ #() ]
        ifNotNil: [ headerLine findTokens: ',' ].

    "2) Recréer un stream frais pour NeoCSV (car on a déjà consommé le contenu)."
    stream := aFileRef readStream.

    "3) Configurer le reader."
    reader := NeoCSVReader on: stream.
    reader separator: $,.

    "Compat: certaines versions ont addFieldNamed:, d'autres addField."
    fieldAdder := (reader respondsTo: #addFieldNamed:)
        ifTrue: [[ :name | reader addFieldNamed: name ]]
        ifFalse: [[ :name | reader addField ]].

    headerTokens isEmpty
        ifTrue: [
            "Pas d’en‑tête détectée: on ne connaît pas le nombre de colonnes.
            Heuristique: on lit la première ligne brute pour deviner."
            | firstData colsCount |
            firstData := stream nextLine.
            firstData ifNil: [ ^ OrderedCollection new ].
            (firstData isEmpty or: [ firstData first = $# ])
                ifTrue: [ ^ OrderedCollection new ].
            colsCount := (firstData findTokens: ',') size.
            1 to: colsCount do: [ :i | fieldAdder value: ('col', i asString) ].
            "Recréer un nouveau stream incluant à nouveau firstData (on repart depuis zéro)."
            stream close.
            stream := aFileRef readStream.
            reader := NeoCSVReader on: stream.
            reader separator: $,.
            1 to: colsCount do: [ :i | (reader respondsTo: #addFieldNamed:)
                    ifTrue: [ reader addFieldNamed: ('col', i asString) ]
                    ifFalse: [ reader addField ] ] ]
        ifFalse: [
            headerTokens do: [ :name | fieldAdder value: name ].
            (reader respondsTo: #skipHeader) ifTrue: [ reader skipHeader ] ].

    "4) Lecture de toutes les lignes restantes."
    rows := OrderedCollection new.
    [ reader atEnd ] whileFalse: [
        | rec normalized |
        rec := reader next.
        "NeoCSV peut rendre un Array d’associations (si mapping), ou déjà des valeurs.
        On transforme en Array simple de Strings."
        rec isArray
            ifTrue: [
                (rec isEmpty or: [ rec first isAssociation ])
                    ifTrue: [ 
                        normalized := rec collect: [ :assoc |
                            assoc isAssociation
                                ifTrue: [ assoc value asString ]
                                ifFalse: [ assoc asString ] ] ]
                    ifFalse: [ normalized := rec collect: [ :v | v asString ] ] ]
            ifFalse: [
                normalized := { rec asString } ].
        "Filtrer éventuelle ligne vide / commentaire."
        (normalized allSatisfy: [ :v | v isEmpty ]) ifFalse: [
            (normalized first beginsWith: '#') ifFalse: [ rows add: normalized ] ] ].

    ^ rows
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
	self resetDroneShapes.
	self refreshOverlays.
	rsCanvas signalUpdate
]

{ #category : 'updating status' }
UISimulation >> refreshDrones [
	"Force uniquement la partie drones (icônes + overlays dépendants)."

	rsCanvas ifNil: [ ^ self ].
	"self removeOverlayShapes."
	self hideShapes.
	self updateShapes.
	self showShapes.

	rsCanvas signalUpdate
]

{ #category : 'overlays' }
UISimulation >> refreshOverlays [
    rsCanvas ifNil: [ ^ self ].
   " self removeOverlayShapes.
  
    self drawDroneIcons.          
    self drawClusterHullOverlay.
    self drawPerceptionOverlay.
    self drawMissionOverlay.
    self drawEnergyOverlay.
    self drawAmmoOverlay. rsCanvas signalUpdate."
self updateShapes 
]

{ #category : 'Simulation control' }
UISimulation >> refreshUIDuringSimulation [
	"Application UI courte et un seul refresh"
 
	self simulator currentTime = self currentTime ifFalse: [
			self currentTime: self simulator currentTime.
			UIManager default defer: [
					self simulator model hasChanged.
					self saveFrames ] ]
]

{ #category : 'presenters' }
UISimulation >> removeOverlayShapes [
    self clearOverlayShapes.
]

{ #category : 'accessing' }
UISimulation >> resetDroneShapes [
	"eg. Change zoom requires redesigning shapes"

	droneShapes := nil
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

{ #category : 'scripting' }
UISimulation >> runScript [

(OpalCompiler new)
    source: self scriptPresenter selectedText;
    receiver: self simulator;
    evaluate.
]

{ #category : 'Simulation control' }
UISimulation >> runSimulationLoop [

	| worker |
	self initializeSimulation.

	worker := [
		          [ self isRunning ] whileTrue: [ "1) Calcul hors UI (ne touche pas aux shapes ici)"
				          self simulator step. "=> met à jour le modèle (positions/états), pas le canvas"

				          "2) Application UI courte et un seul refresh"
				          self refreshUIDuringSimulation.

				          (Delay forMilliseconds: 10) wait
				          "self updateRunningState" ] ] forkAt:
		          Processor userBackgroundPriority
]

{ #category : 'Simulation control' }
UISimulation >> runSimulationLoopUntilCondition: aConditionText [

	| worker aCondition |
	aCondition := OpalCompiler new
		              source: aConditionText;
		              receiver: self simulator;
		              yourself.
	self initializeSimulation.
	worker := [
		          [ self isRunning & aCondition evaluate not ] whileTrue: [ "1) Calcul hors UI (ne touche pas aux shapes ici)"
				          self simulator step. "=> met à jour le modèle (positions/états), pas le canvas"

				          "2) Application UI courte et un seul refresh"
				          self refreshUIDuringSimulation.
				          (Delay forMilliseconds: 10) wait
				          "self updateRunningState" ].
		          self isRunning: false ] forkAt:
		          Processor userBackgroundPriority
]

{ #category : 'Simulation control' }
UISimulation >> runSimulationLoopUntilTimestamp: aTimestampText [

	| worker aTimestamp |
	self initializeSimulation.
	aTimestamp := aTimestampText asNumber.
	worker := [
		          [
		          self isRunning
		          & (self simulator hasCompleted: aTimestamp) not ]
			          whileTrue: [ "1) Calcul hors UI (ne touche pas aux shapes ici)"
					          self simulator step. "=> met à jour le modèle (positions/états), pas le canvas"

					          "2) Application UI courte et un seul refresh"
					          self refreshUIDuringSimulation.

					          (Delay forMilliseconds: 10) wait
					          "self updateRunningState" ].
		          self isRunning: false ] forkAt:
		          Processor userBackgroundPriority
]

{ #category : 'Simulation control' }
UISimulation >> runSimulationSteps: nSteps [

	| worker |
	self initializeSimulation.
	worker := [
		          [
			          1 to: nSteps asNumber do: [ :i |
					          self isRunning ifFalse: [ ^ self ].

					          "1) Calcul hors UI (ne touche pas aux shapes ici)"
					          self simulator step. "=> met à jour le modèle (positions/états), pas le canvas"

					          "2) Application UI courte et un seul refresh"
					          self refreshUIDuringSimulation.
					          (Delay forMilliseconds: 20) wait.
					          self isRunning ifFalse: [ ^ self ] ] ] ensure: [
			          self isRunning: false ] ] forkAt:
		          Processor userBackgroundPriority
]

{ #category : 'Simulation control' }
UISimulation >> saveFrames [

	self generateVideo ifTrue: [Transcript show: self simulator currentTime printString;cr.
			PNGReadWriter
				putForm: rsCanvas morph imageForm
				onFileNamed: (self dirForVideos
					 /
						 ('frame-'
						  , (self simulator currentTime printPaddedWith: $0 to: 5)
						  , '.png')) fullName ]
]

{ #category : 'scripting' }
UISimulation >> saveScript [

]

{ #category : 'Simulation control' }
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

{ #category : 'Simulation control' }
UISimulation >> saveSimulationTo: aFileRef [
    (Smalltalk includesKey: #FLSerializer)
        ifFalse: [ ^ Transcript show: 'Fuel non chargé'; cr ].
    [ FLSerializer serialize: simulation toFileNamed: aFileRef fullName.
      Transcript show: 'Simulation sauvegardée: ', aFileRef fullName; cr ]
        on: Error do: [ :ex | Transcript show: 'Save error: ', ex messageText; cr ].
]

{ #category : 'Simulation control' }
UISimulation >> saveVideo [
 
	LibC system: 'cd ' , self dirForVideos fullName
		,
		' && ffmpeg -framerate 30 -i frame-%05d.png -vf ''scale=ceil(iw/2)*2:ceil(ih/2)*2'' -c:v libx264 -pix_fmt yuv420p video.mp4'
]

{ #category : 'presenters' }
UISimulation >> scriptPresenter [ 

	 
	^ scriptPresenter 
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

{ #category : 'waypoints' }
UISimulation >> setOverlayChecksFocus [
	"Construit l'ordre de focus en incluant d'autres champs si présents.
    Ajoute simplement leurs noms dans la liste names."

	| names candidates |
	names := #( dronesAllButton dronesSelectedButton checkPerception
	            checkMissions clusterListPresenter missionListPresenter ).
	candidates := OrderedCollection new.
	names do: [ :sym |
			(self class allInstVarNames includes: sym asString) ifTrue: [
					| v |
					v := self instVarNamed: sym asString.
					v ifNotNil: [ candidates add: v ] ] ].
	candidates do: [ :p |
		(p respondsTo: #takeKeyboardFocus) ifTrue: [ self focusOrder add: p ] ]
]

{ #category : 'overlay models' }
UISimulation >> shape: aShape hasAttribute: key equals: expected [
    (aShape respondsTo: #attributeAt:ifAbsent:)
        ifTrue: [ ^ (aShape attributeAt: key ifAbsent: [ ^ false ]) = expected ].
    ^ false
]

{ #category : 'accessing' }
UISimulation >> showAllDrones [
    showAllDrones ifNil:[showAllDrones := true].
 ^ showAllDrones
]

{ #category : 'accessing' }
UISimulation >> showAllDrones: aBoolean [
    showAllDrones := aBoolean asBoolean.
    self updateDroneListFromSelectedClusters.
    self refreshDrones
]

{ #category : 'presenters' }
UISimulation >> showShapes [

"Shows either all drone or selected ones"
"keep only selected shapes"
	self allDrones do: [ :aDrone |
			(droneShapes at: aDrone)  showFollowing: self overlayModel ] 
]

{ #category : 'accessing' }
UISimulation >> simulation [

	^ simulation
]

{ #category : 'accessing' }
UISimulation >> simulation: aSim [
    simulation := aSim.
    ^ self.
]

{ #category : 'Simulation control' }
UISimulation >> simulationMenuItem: aText do: aBloc [
| presenter n |
	presenter := SpRequestDialog new.
	presenter
		title: 'Simulation';
		label: aText;
		text: '1';
		acceptLabel: 'step ahead';
		cancelLabel: 'Cancel';
		onAccept: [ :dialog |   n :=   dialog presenter text  . n isEmpty ifFalse: [ aBloc value: n
 ]];
		openDialog.
    
]

{ #category : 'Simulation control' }
UISimulation >> simulationStepOnce [
    (simulation respondsTo: #step) ifTrue: [
        haltOnError
            ifTrue: [ simulation step ]   "laisse remonter l'erreur"
            ifFalse: [
                [ simulation step ] on: Error do: [ :ex |
                    Transcript show: 'Step error: ', ex messageText; cr ] ] ].
    self refreshDrones.
    self updateTimeLabel.

]

{ #category : 'Simulation control' }
UISimulation >> simulator [

	^ simulator
]

{ #category : 'Simulation control' }
UISimulation >> simulator: aValue [

	simulator := aValue
]

{ #category : 'load and saving' }
UISimulation >> snapshot [ 
 self   window adapter widget  imageForm writePNGFileNamed: 'UISimulation.png'
]

{ #category : 'waypoints' }
UISimulation >> startOrStopHandlingWaypoints [
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

{ #category : 'presenters' }
UISimulation >> statusLabelPresenter [

	^ statusLabelPresenter
]

{ #category : 'presenters' }
UISimulation >> statusLabelPresenter: anObject [

	statusLabelPresenter := anObject
]

{ #category : 'Simulation control' }
UISimulation >> stopSimulationLoop [
	 
	self isRunning: false.
  
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

{ #category : 'overlays' }
UISimulation >> undrawClusterOverlayFor: c [

	| s |
	s := self ensureClusterShapes: c.

	s hull ifNotNil: [
			(rsCanvas shapes includes: s hull) ifTrue: [
				rsCanvas removeShape: s hull ] ].
	^ s
]

{ #category : 'overlays' }
UISimulation >> undrawMissionOverlayFor: m [

	| s |
	s := self ensureMissionShapes: m.

	s hull ifNotNil: [
			(rsCanvas shapes includes: s hull) ifTrue: [
				rsCanvas removeShape: s hull ] ].
	^ s
]

{ #category : 'CSV' }
UISimulation >> updateClusterListFromFleet [
	| clusters |
	clusterListPresenter ifNil: [ ^ self ].

	clusters := self simulation allFleets first clusters.
	
clusterListPresenter items: clusters
]

{ #category : 'debugging' }
UISimulation >> updateDroneListFromSelectedClusters [

	| drones |
	droneListPresenter ifNil: [ ^ self ].

	drones := self allDrones.
	droneListPresenter items: drones
]

{ #category : 'presenters' }
UISimulation >> updateDronesModeLabel [

	dronesModeLabel label: (String streamContents: [ :s |
				 {
					 dronesAllButton.
					 dronesSelectedButton }
					 do: [ :btn |
							 s
								 << btn label;
								 << ' : ';
								 << (btn state
										  ifTrue: [ 'V' ]
										  ifFalse: [ 'X' ]) ]
					 separatedBy: [ s << ' - ' ] ])
]

{ #category : 'model - updating' }
UISimulation >> updateFrom: aSimulationState [

self refreshDrones; updateTimeLabel
]

{ #category : 'Simulation control' }
UISimulation >> updateRunningState [

	isRunning := isRunning & self simulator isRunning
]

{ #category : 'overlays' }
UISimulation >> updateShapes [

	| m |
	self allDrones do: [ :d |
			| p |
			p := self pixelForDrone: d.
			self drawDroneIconsFor: d at: p.
			self drawPerceptionOverlayFor: d at: p.

			self drawEnergyOverlayFor: d at: p.
			self drawAmmoOverlayFor: d at: p ].

	self clustersFromSimulation do: [ :c |
		self undrawClusterOverlayFor: c ].
	self allClusters do: [ :c | self drawClusterOverlayFor: c ].
	self missionListPresenter ifNotNil: [ "remove allMissions"
			self missionListPresenter items do: [ :aMission |
				self undrawMissionOverlayFor: aMission ].
			m := self missionListPresenter selectedItem.
			m ifNotNil: [ "draw selected mission on demand"
				self drawMissionOverlayFor: m ] ]
]

{ #category : 'overlays' }
UISimulation >> updateTimeLabel [

	| t |
	t := self simulator currentTime.
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

{ #category : 'presenters' }
UISimulation >> waypointsMenu [
    | m |
    m := SpMenuPresenter new.
    m addItem: [ :it | it name: 'Capture'; action: [ self startWaypointCapture ] ].
    m addItem: [ :it | it name: 'Commit'; action: [ self commitPendingWaypoints ] ].
  m addItem: [ :it | it name: 'Clear'; action: [ self clearPendingWaypoints ] ].
    ^ m
]

{ #category : 'presenters-building' }
UISimulation >> wrapLayout: aLayout [
	"Encapsule un SpBoxLayout dans un presenter."

	| p |
	p := self newPresenter.
	p layout: aLayout.
	^ p
]

{ #category : 'zoom animation' }
UISimulation >> zoomIn [
    self zoomLevel: zoomLevel * 1.4.

]

{ #category : 'presenters' }
UISimulation >> zoomLevel [

	^ zoomLevel
]

{ #category : 'zoom animation' }
UISimulation >> zoomLevel: aNumber [

	zoomLevel := (aNumber asFloat max: 0.1) min: 50.
	self updateZoomedBBox.
	self postZoomRefresh 
]

{ #category : 'zoom animation' }
UISimulation >> zoomMenu [
    | m |
    m := SpMenuPresenter new.
    m addItem: [ :it | it name: 'Fit'; action: [ self fitZoom ] ].
    m addItem: [ :it | it name: 'Zoom +'; action: [ self zoomIn ] ].
    m addItem: [ :it | it name: 'Zoom -'; action: [ self zoomOut ] ].
    ^ m
]

{ #category : 'zoom animation' }
UISimulation >> zoomOn: aRsBox [

	self forceBoundingBox: {
			(self class
				 physicalLonLatFromPixel:  
				 (self pixelFromCanvasPoint: aRsBox encompassingRectangle origin)
				 inBbox: self boundingBox
				 width: self imageSize x
				 height: self imageSize y).
			(self class
				 physicalLonLatFromPixel:  
				 (self pixelFromCanvasPoint: aRsBox encompassingRectangle corner)
				 inBbox: self boundingBox
				 width: self imageSize x
				 height: self imageSize y) }
]

{ #category : 'zoom animation' }
UISimulation >> zoomOut [
    self zoomLevel: zoomLevel / 1.4.
]
