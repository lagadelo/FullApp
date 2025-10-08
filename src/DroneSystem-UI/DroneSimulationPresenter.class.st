Class {
	#name : 'DroneSimulationPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'simulation',
		'mapPresenter',
		'missionsPresenter',
		'waypointsPresenter',
		'clustersPresenter',
		'overlayPresenter',
		'strategyCombo',
		'applyStrategyButton',
		'logPresenter',
		'logModel',
		'overlayModel',
		'strategyRegistry',
		'missionClassCombo',
		'applyMissionButton',
		'wpStartButton',
		'wpCommitButton',
		'wpCancelButton',
		'capturedWaypoints',
		'autoCloseCB',
		'autoClosePolygons'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
DroneSimulationPresenter >> applyMissionButton [

	^ applyMissionButton
]

{ #category : 'accessing' }
DroneSimulationPresenter >> applyMissionButton: anObject [

	applyMissionButton := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> applyNewMission [
    | oldMission newMission cluster evt |
    oldMission := missionsPresenter selectedItem ifNil: [ ^ self logText: 'Sélectionner une mission.' ].
    cluster := (oldMission respondsTo: #cluster)
        ifTrue: [ oldMission cluster ]
        ifFalse: [ nil ].
    cluster ifNil: [ ^ self logText: 'Mission sans cluster.' ].
    newMission := self buildNewMissionFromSelection ifNil: [ ^ self logText: 'Création annulée.' ].
    (newMission respondsTo: #assignToCluster:) ifTrue: [ newMission assignToCluster: cluster ].
    (simulation respondsTo: #replaceMission:with:) ifTrue: [
        simulation replaceMission: oldMission with: newMission ].
    evt := (Smalltalk at: #MissionChangeEvent ifAbsent: [ nil ]) ifNotNil: [
        (Smalltalk at: #MissionChangeEvent) new
            oldMission: oldMission;
            newMission: newMission;
            cluster: cluster;
            yourself ].
    (simulation respondsTo: #scheduleEvent:at:) ifTrue: [
        evt ifNotNil: [
            simulation scheduleEvent: evt at: (simulation respondsTo: #currentTime
                ifTrue: [ simulation currentTime ]
                ifFalse: [ 0 ]) ] ].
    self logText: ('Mission changée: ', oldMission class name, ' → ', newMission class name).
    self refreshMissions
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> applySelectedStrategy [
    | mission strategyClass strategyInstance |
    mission := missionsPresenter selectedItem ifNil: [ ^ self logText: 'Aucune mission.' ].
    strategyClass := strategyCombo selectedItem ifNil: [ ^ self logText: 'Aucune stratégie.' ].
    strategyInstance := strategyClass new.
    (mission respondsTo: #strategy:) ifTrue: [ mission strategy: strategyInstance ].
    self logText: ('Stratégie ', strategyClass name, ' appliquée à ', mission class name).
    missionsPresenter refresh

]

{ #category : 'accessing' }
DroneSimulationPresenter >> applyStrategyButton [

	^ applyStrategyButton
]

{ #category : 'accessing' }
DroneSimulationPresenter >> applyStrategyButton: anObject [

	applyStrategyButton := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> autoCloseCB [

	^ autoCloseCB
]

{ #category : 'accessing' }
DroneSimulationPresenter >> autoCloseCB: anObject [

	autoCloseCB := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> autoClosePolygons [

	^ autoClosePolygons
]

{ #category : 'accessing' }
DroneSimulationPresenter >> autoClosePolygons: anObject [

	autoClosePolygons := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> availableMissionClasses [
    ^ {
        (Smalltalk at: #SurveillanceMission ifAbsent: [ nil ]).
        (Smalltalk at: #StrikeMission ifAbsent: [ nil ]).
        (Smalltalk at: #SecurizationMission ifAbsent: [ nil ]).
        (Smalltalk at: #MixedMission ifAbsent: [ nil ]).
        (Smalltalk at: #ZoneBasedMission ifAbsent: [ nil ])
    } reject: [ :c | c isNil ]
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> buildNewMissionFromSelection [
    | cls wps |
    cls := missionClassCombo selectedItem ifNil: [ ^ nil ].
    wps := capturedWaypoints isEmpty
        ifTrue: [ self defaultSurveillanceWaypoints ]
        ifFalse: [ capturedWaypoints ].
    (self missionClassRequiresClosure: cls)
        ifTrue: [ wps := self ensuredClosedLoopFor: wps autoClose: autoClosePolygons ].
    (cls = (Smalltalk at: #SurveillanceMission ifAbsent: [ nil ])
        or: [ cls = (Smalltalk at: #SecurizationMission ifAbsent: [ nil ]) ]) ifTrue: [
        ^ cls new waypoints: wps; yourself ].
    cls = (Smalltalk at: #MixedMission ifAbsent: [ nil ]) ifTrue: [
        ^ cls new
            missions: {
                (Smalltalk at: #SurveillanceMission) new waypoints: wps; yourself.
                (Smalltalk at: #StrikeMission) new targets: (self defaultStrikeTargets); yourself };
            yourself ].
    cls = (Smalltalk at: #StrikeMission ifAbsent: [ nil ]) ifTrue: [
        ^ cls new targets: (self defaultStrikeTargets); yourself ].
    ^ cls new
]

{ #category : 'accessing' }
DroneSimulationPresenter >> capturedWaypoints [

	^ capturedWaypoints
]

{ #category : 'accessing' }
DroneSimulationPresenter >> capturedWaypoints: anObject [

	capturedWaypoints := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> clusterSelectionChanged [
    | node |
    node := clustersPresenter selectedItem.
    node ifNil: [ ^ self ].
    overlayModel autoFocusSelection ifTrue: [
        (mapPresenter respondsTo: #centerOn:) ifTrue: [
            mapPresenter centerOn: node domainObject ] ]
]

{ #category : 'accessing' }
DroneSimulationPresenter >> clustersPresenter [

	^ clustersPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> clustersPresenter: anObject [

	clustersPresenter := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> commitWaypointCapture [
    mapPresenter commitPendingWaypoints
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> defaultLayout [
    ^ SpBoxLayout newVertical
        add: (SpBoxLayout newHorizontal
            add: (SpBoxLayout newVertical
                add: (SpLabelPresenter text: 'Missions');
                add: missionsPresenter expand: true;
                add: (SpLabelPresenter text: 'Nouvelle mission');
                add: missionClassCombo;
                add: applyMissionButton;
                add: (SpLabelPresenter text: 'Waypoints');
                add: waypointsPresenter expand: true;
                add: (SpBoxLayout newHorizontal
                    add: wpStartButton;
                    add: wpCommitButton;
                    add: wpCancelButton;
                    yourself);
                add: autoCloseCB;
                add: (SpLabelPresenter text: 'Stratégie');
                add: strategyCombo;
                add: applyStrategyButton;
                space: 4) width: 300;
            add: (SpBoxLayout newVertical
                add: mapPresenter expand: true;
                add: overlayPresenter;
                yourself) expand: true;
            add: (SpBoxLayout newVertical
                add: (SpLabelPresenter text: 'Clusters / Drones');
                add: clustersPresenter expand: true;
                yourself) width: 250;
            yourself) expand: true;
        add: (SpBoxLayout newVertical
            add: (SpLabelPresenter text: 'Log évènements');
            add: logPresenter expand: true;
            yourself) height: 160;
        yourself
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> defaultStrikeTargets [
    ^ {
        (Smalltalk at: #GeoPoint) latitude: 48.90 longitude: 2.40 altitude: 1000.
        (Smalltalk at: #GeoPoint) latitude: 48.91 longitude: 2.41 altitude: 1000.
    }
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> defaultSurveillanceWaypoints [
    ^ {
        (Smalltalk at: #Waypoint) latitude: 48.85 longitude: 2.35 altitude: 1000.
        (Smalltalk at: #Waypoint) latitude: 48.86 longitude: 2.36 altitude: 1000.
        (Smalltalk at: #Waypoint) latitude: 48.87 longitude: 2.35 altitude: 1000.
    }
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> ensuredClosedLoopFor: waypointCollection autoClose: shouldClose [
    | wps |
    wps := waypointCollection asOrderedCollection.
    (shouldClose and: [ self needsClosure: wps ]) ifTrue: [ wps add: wps first ].
    ^ wps asArray
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> initialize [
    super initialize.
    overlayModel := DroneOverlayModel new.
    logModel := DroneEventLogModel new maxSize: 500.
    strategyRegistry := DroneStrategyRegistry new.
    capturedWaypoints := #().
    autoClosePolygons := true.
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> initializePresenters [
    mapPresenter := (Smalltalk at: #DroneMapWithOSWView) new
        overlayModel: overlayModel;
        onWaypointsCommitted: [ :wps | self waypointsCaptured: wps ];
        yourself.
    missionsPresenter := SpTablePresenter new
        addColumn: (SpStringTableColumn title: 'Mission' evaluated: [ :m | m class name ]);
        addColumn: (SpStringTableColumn title: 'Stratégie' evaluated: [ :m | m strategy ifNil: [ '-' ] ifNotNil: [ m strategy class name ] ]);
        whenSelectionChangedDo: [ self updateWaypoints ];
        yourself.
    waypointsPresenter := SpTablePresenter new
        addColumn: (SpStringTableColumn title: 'Lat' evaluated: [ :wp | (wp latitude ifNil: [ '-' ]) printString ]);
        addColumn: (SpStringTableColumn title: 'Lon' evaluated: [ :wp | (wp longitude ifNil: [ '-' ]) printString ]);
        addColumn: (SpStringTableColumn title: 'Alt' evaluated: [ :wp | (wp altitude ifNil: [ '-' ]) printString ]);
        yourself.
    clustersPresenter := SpTreePresenter new
        displayBlock: [ :node | node label ];
        childrenBlock: [ :node | node children ];
        whenSelectionChangedDo: [ self clusterSelectionChanged ];
        yourself.
    overlayPresenter := DroneOverlaySettingsPresenter new
        model: overlayModel;
        onChange: [ self overlaysChanged ];
        yourself.
    strategyCombo := SpDropListPresenter new
        items: strategyRegistry availableStrategyClasses;
        displayBlock: [ :cls | cls name ];
        yourself.
    applyStrategyButton := SpButtonPresenter new
        label: 'Appliquer stratégie';
        action: [ self applySelectedStrategy ];
        yourself.
    missionClassCombo := SpDropListPresenter new
        items: self availableMissionClasses;
        displayBlock: [ :cls | cls name ];
        yourself.
    applyMissionButton := SpButtonPresenter new
        label: 'Appliquer mission';
        action: [ self applyNewMission ];
        yourself.
    wpStartButton := SpButtonPresenter new
        label: 'Saisie WP';
        action: [ self startWaypointCapture ];
        yourself.
    wpCommitButton := SpButtonPresenter new
        label: 'Valider WP';
        action: [ self commitWaypointCapture ];
        yourself.
    wpCancelButton := SpButtonPresenter new
        label: 'Annuler WP';
        action: [ self cancelWaypointCapture ];
        yourself.
    autoCloseCB := SpCheckBoxPresenter new
        label: 'Boucler zone';
        state: autoClosePolygons;
        whenChangedDo: [ :val | autoClosePolygons := val ];
        yourself.
    logPresenter := SpListPresenter new
        items: logModel entries;
        yourself
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> logEvent: evt [
    logModel addEvent: evt.
    logPresenter items: logModel entries; scrollToEnd
]

{ #category : 'accessing' }
DroneSimulationPresenter >> logModel [

	^ logModel
]

{ #category : 'accessing' }
DroneSimulationPresenter >> logModel: anObject [

	logModel := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> logPresenter [

	^ logPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> logPresenter: anObject [

	logPresenter := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> logText: aString [
    logModel addString: aString.
    logPresenter items: logModel entries; scrollToEnd
]

{ #category : 'accessing' }
DroneSimulationPresenter >> mapPresenter [

	^ mapPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> mapPresenter: anObject [

	mapPresenter := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> missionClassCombo [

	^ missionClassCombo
]

{ #category : 'accessing' }
DroneSimulationPresenter >> missionClassCombo: anObject [

	missionClassCombo := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> missionClassRequiresClosure: aClass [
    aClass isNil ifTrue: [ ^ false ].
    ((aClass name includesSubstring: 'Barrier')
        or: [ aClass name includesSubstring: 'Strike' ]) ifTrue: [ ^ false ].
    ^ #(SurveillanceMission SecurizationMission MixedMission ZoneBasedMission)
        includes: aClass name asSymbol
]

{ #category : 'accessing' }
DroneSimulationPresenter >> missionsPresenter [

	^ missionsPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> missionsPresenter: anObject [

	missionsPresenter := anObject
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> needsClosure: wps [
    wps size < 2 ifTrue: [ ^ false ].
    ^ ((wps first latitude - wps last latitude) abs > 0.00001)
        or: [ (wps first longitude - wps last longitude) abs > 0.00001 ]
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> open [
    self openWithSpec
]

{ #category : 'accessing' }
DroneSimulationPresenter >> overlayModel [

	^ overlayModel
]

{ #category : 'accessing' }
DroneSimulationPresenter >> overlayModel: anObject [

	overlayModel := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> overlayPresenter [

	^ overlayPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> overlayPresenter: anObject [

	overlayPresenter := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> populateModels [
    (missionsPresenter notNil and: [ simulation notNil ]) ifTrue: [
        (missionsPresenter respondsTo: #items:) ifTrue: [ missionsPresenter items: simulation missions ] ].
    (clustersPresenter notNil and: [ simulation notNil ]) ifTrue: [
        clustersPresenter rootItems: (simulation clusters collect: [ :c | DroneClusterTreeNode fromCluster: c ]) ].
    mapPresenter ifNotNil: [ mapPresenter simulation: simulation ]

]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> refreshMissions [
    missionsPresenter items: simulation missions.
    waypointsPresenter items: #()
]

{ #category : 'accessing' }
DroneSimulationPresenter >> simulation [

	^ simulation
]

{ #category : 'accessing' }
DroneSimulationPresenter >> simulation: aSimulation [
    simulation := aSimulation.
    self populateModels.
    self subscribeToSimulation
]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> startWaypointCapture [
    mapPresenter enableWaypointInput.
    self logText: 'Mode saisie waypoints actif.'
]

{ #category : 'accessing' }
DroneSimulationPresenter >> strategyCombo [

	^ strategyCombo
]

{ #category : 'accessing' }
DroneSimulationPresenter >> strategyCombo: anObject [

	strategyCombo := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> strategyRegistry [

	^ strategyRegistry
]

{ #category : 'accessing' }
DroneSimulationPresenter >> strategyRegistry: anObject [

	strategyRegistry := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> subscribeToSimulation [
    (simulation respondsTo: #announcer) ifFalse: [ ^ self ].
    simulation announcer
        when: (Smalltalk at: #MissionChangeEvent ifAbsent: [ Object ]) do: [ :evt | self logEvent: evt ];
        when: (Smalltalk at: #DetectionEvent ifAbsent: [ Object ]) do: [ :evt | self logEvent: evt ];
        when: (Smalltalk at: #InterceptEvent ifAbsent: [ Object ]) do: [ :evt | self logEvent: evt ]

]

{ #category : 'initialization-release' }
DroneSimulationPresenter >> updateWaypoints [
    | mission |
    mission := missionsPresenter selectedItem.
    waypointsPresenter items: (mission
        ifNil: [ #() ]
        ifNotNil: [
            (mission respondsTo: #waypoints)
                ifTrue: [ mission waypoints ]
                ifFalse: [ #() ] ])
]

{ #category : 'accessing' }
DroneSimulationPresenter >> waypointsPresenter [

	^ waypointsPresenter
]

{ #category : 'accessing' }
DroneSimulationPresenter >> waypointsPresenter: anObject [

	waypointsPresenter := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpCancelButton [

	^ wpCancelButton
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpCancelButton: anObject [

	wpCancelButton := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpCommitButton [

	^ wpCommitButton
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpCommitButton: anObject [

	wpCommitButton := anObject
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpStartButton [

	^ wpStartButton
]

{ #category : 'accessing' }
DroneSimulationPresenter >> wpStartButton: anObject [

	wpStartButton := anObject
]
