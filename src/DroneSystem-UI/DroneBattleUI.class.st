Class {
	#name : 'DroneBattleUI',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'mapMorph',
		'timeSlider',
		'fleetSelector',
		'infoText',
		'currentStep',
		'autoplayProcess'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
DroneBattleUI class >> openOn: aSimulationState [
    ^ (self new simulator: aSimulationState) open
]

{ #category : 'accessing' }
DroneBattleUI >> autoplayProcess [

	^ autoplayProcess
]

{ #category : 'accessing' }
DroneBattleUI >> autoplayProcess: anObject [

	autoplayProcess := anObject
]

{ #category : 'initialization' }
DroneBattleUI >> buildSpiderChartFor: aCluster [
    | metrics labels maxValue center points polygon radarView |

    "=== Définition des métriques ==="
    labels := #('Coverage' 'Energy' 'Speed' 'Communication').
    metrics := {
        aCluster coverage size.          "nombre de points de couverture"
        aCluster drones sum: [:d | d d fuel]. "somme énergie"
        (aCluster drones average: [:d | d speed]) ifNil: [0].
        (aCluster capabilities size).    "exemple: nombre de capacités"
    }.

    "=== Normalisation ==="
    maxValue := (metrics max max: 1). "évite division par zéro"
    metrics := metrics collect: [:v | v asFloat / maxValue].

    "=== Préparer le radar ==="
    radarView := RTView new.
    center := 150@150.
    points := OrderedCollection new.

    labels withIndexDo: [:lbl :i |
        | angle r end lblShape |
        angle := (2 * Float pi / labels size) * (i - 1).
        r := (metrics at: i) * 100.
        end := center + (r * (angle cos)) @ (r * (angle sin)).
        points add: end.

        "dessiner l’axe"
        radarView add: (RTLine from: center to: (center + (100 * angle cos) @ (100 * angle sin))).
        "dessiner le label"
        lblShape := RSLabel new text: lbl.
        radarView add: lblShape elementOn: nil.
        lblShape translateTo: (center + (120 * angle cos) @ (120 * angle sin)).
    ].

    "=== Polygone du radar ==="
    polygon := RSPolygon new points: points.
    polygon color: (Color blue alpha: 0.3).
    radarView add: polygon.

    "=== Points ==="
    points do: [:p |
        radarView add: (RTBox new size: 5@5; color: Color red; elementOn: nil) translateTo: p.
    ].

    ^ radarView canvas

]

{ #category : 'initialization' }
DroneBattleUI >> buildUI [
    | rootLayout leftPanel rightPanel fleetSelector infoText spiderChart saveButton updateButton autoButton speedSlider currentFleet currentSpider timeLabel autoProcess running stepDelay simulationState |

    rootLayout := SpBoxLayout newHorizontal.

    "État de l’auto-simulation"
    running := false.
    autoProcess := nil.
    stepDelay := 1.0.  "délai initial en secondes"

    "Panneau gauche : sélection et boutons"
    leftPanel := SpBoxLayout newVertical.
    fleetSelector := SpDropList new.
    fleetSelector items: (simulationState allFleets collect: [:f | f name]).
    fleetSelector selectIndex: 1. "sélection par défaut"

    saveButton := SpButton new label: 'Sauver état'.
    saveButton action: [ self saveSimulationState ].

    updateButton := SpButton new label: 'Mettre à jour'.
    updateButton action: [
        self stepAndRefreshUIWith: fleetSelector
            rightPanel: rightPanel
            currentSpider: currentSpider
            infoText: infoText
            timeLabel: timeLabel
    ].

    autoButton := SpButton new label: 'Démarrer Auto'.
    autoButton action: [
        running
            ifTrue: [
                "Arrêter"
                running := false.
                autoProcess ifNotNil: [ autoProcess terminate ].
                autoProcess := nil.
                autoButton label: 'Démarrer Auto' ]
            ifFalse: [
                "Démarrer"
                running := true.
                autoButton label: 'Stop Auto'.
                autoProcess := [
                    [ running ] whileTrue: [
                        [ self stepAndRefreshUIWith: fleetSelector
                              rightPanel: rightPanel
                              currentSpider: currentSpider
                              infoText: infoText
                              timeLabel: timeLabel ]
                            on: Error do: [ :ex | ex traceCr ].
                        (Delay forSeconds: stepDelay) wait
                    ]
                ] forkAt: Processor userBackgroundPriority ].
    ].

    "Slider de vitesse (0.1s à 5s)"
    speedSlider := SpSlider new.
    speedSlider min: 1;  "valeur brute minimale"
                max: 50; "valeur brute maximale"
                value: 10. "valeur initiale (→ 1.0s)"
    speedSlider whenValueChangedDo: [:val |
        stepDelay := val asFloat / 10.0.
    ].

    leftPanel
        add: fleetSelector;
        add: updateButton;
        add: autoButton;
        add: (SpLabel new label: 'Vitesse (0.1s - 5s)');
        add: speedSlider;
        add: saveButton.

    "Panneau droit : Spider chart + infos"
    rightPanel := SpBoxLayout newVertical.

    currentFleet := simulationState allFleets first.
    currentSpider := self buildSpiderChartFor: currentFleet.

    infoText := SpText new.
    infoText text: 'Mission: ', (currentFleet currentMission ifNil: ['aucune']) asString.

    timeLabel := SpLabel new.
    timeLabel text: 'Temps: 0'.

    rightPanel
        add: timeLabel;
        add: currentSpider;
        add: infoText.

    "Assembler tout"
    rootLayout
        add: leftPanel;
        add: rightPanel.

    ^ rootLayout

]

{ #category : 'accessing' }
DroneBattleUI >> currentStep [

	^ currentStep
]

{ #category : 'accessing' }
DroneBattleUI >> currentStep: anObject [

	currentStep := anObject
]

{ #category : 'initialization' }
DroneBattleUI >> exportCSV [
    simulator exportResultsToCSV: 'results.csv'.
    UIManager default inform: 'CSV exporté en results.csv'
]

{ #category : 'accessing' }
DroneBattleUI >> fleetSelector [

	^ fleetSelector
]

{ #category : 'accessing' }
DroneBattleUI >> fleetSelector: anObject [

	fleetSelector := anObject
]

{ #category : 'accessing' }
DroneBattleUI >> infoText [

	^ infoText
]

{ #category : 'accessing' }
DroneBattleUI >> infoText: anObject [

	infoText := anObject
]

{ #category : 'initialization' }
DroneBattleUI >> initializeWithSimulator: aSimulator [
    simulator := aSimulator.
    currentStep := 0.
    self buildUI.
    ^ self.

]

{ #category : 'accessing' }
DroneBattleUI >> mapMorph [

	^ mapMorph
]

{ #category : 'accessing' }
DroneBattleUI >> mapMorph: anObject [

	mapMorph := anObject
]

{ #category : 'accessing' }
DroneBattleUI >> refreshUI [
    "Met à jour l’interface graphique en fonction de currentStep et du fleetSelector"
    | stepData selectedFleetName fleets drones missionText |

    simulator ifNil: [ ^ self ].  "Pas de simulation = rien à afficher"

    "1. Récupérer l’état de la simulation au step courant"
    stepData := simulator stepAt: currentStep ifAbsent: [ ^ self ].

    "2. Déterminer quelle flotte est sélectionnée"
    selectedFleetName := fleetSelector selectedItem.
    fleets := simulator allFleets.
    (selectedFleetName notNil and: [ selectedFleetName ~= 'Toutes' ]) ifTrue: [
        fleets := fleets select: [:f | f name = selectedFleetName ] ].

    "3. Extraire les drones visibles"
    drones := fleets collectMany: [:f | f drones ].

    "4. Rafraîchir la carte"
    mapMorph removeAll.
    drones do: [:d |
        | shape |
        shape := RSCircle new
            size: 8;
            color: (d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]);
            position: (d longitude @ d latitude).
        mapMorph add: shape
    ].
    mapMorph signalUpdate.

    "5. Mettre à jour la zone d’info"
    missionText := String streamContents: [:s |
        fleets do: [:f |
            s
                nextPutAll: 'Flotte: '; nextPutAll: f name; cr;
                nextPutAll: 'Mission: ';
                nextPutAll: (f currentMission ifNil: [ 'Aucune' ] ifNotNil: [ f currentMission missionType asString ]);
                cr; cr ] ].
    infoText text: missionText.

]

{ #category : 'initialization' }
DroneBattleUI >> refreshView [
    | state visibleFleets |
    state := simulator stateAtStep: currentStep.  "Accès snapshot simulation"
    mapMorph removeAllMarkers.

    visibleFleets := fleetSelector selectedItem = 'Allies'
        ifTrue: [ state alliedFleets ]
        ifFalse: [ fleetSelector selectedItem = 'Hostiles'
            ifTrue: [ state hostileFleets ]
            ifFalse: [ state allFleets ] ].

    visibleFleets do: [:fleet |
        fleet drones do: [:d |
            | marker color |
            color := d isHostile ifTrue: [ Color red ] ifFalse: [ Color green ].
            marker := OWSMarker new
                position: (OWSLatLon latitude: d latitude longitude: d longitude);
                label: d uniqueId;
                color: color;
                onClick: [ self showDroneInfo: d ].
            mapMorph addMarker: marker ].
    ].

    self updateMissionInfo: visibleFleets.
]

{ #category : 'initialization' }
DroneBattleUI >> saveResults [
    simulator saveResultsToFile: 'results.json'.
    UIManager default inform: 'Résultats sauvegardés en results.json'.

]

{ #category : 'initialization' }
DroneBattleUI >> screenshot [
    mapMorph exportToPNG: 'map.png'.
    UIManager default inform: 'Capture enregistrée en map.png'.
]

{ #category : 'initialization' }
DroneBattleUI >> showDroneInfo: aDrone [
    UIManager default inform: 
        'Drone ' , aDrone uniqueId , String cr ,
        'Lat: ' , aDrone latitude asString , String cr ,
        'Lon: ' , aDrone longitude asString , String cr ,
        'Alt: ' , aDrone altitude asString , String cr ,
        'Energy: ' , aDrone fuel asString , String cr ,
        'Status: ' , (aDrone isDestroyed ifTrue: ['Destroyed'] ifFalse: ['Active']).

]

{ #category : 'accessing' }
DroneBattleUI >> simulator [

	^ simulator
]

{ #category : 'accessing' }
DroneBattleUI >> simulator: anObject [

	simulator := anObject
]

{ #category : 'autoplay' }
DroneBattleUI >> startAutoplay [
    self stopAutoplay.  "assure qu'on n'a pas déjà un process en cours"
    autoplayProcess := [
        [ currentStep < timeSlider max ] whileTrue: [
            (Delay forMilliseconds: 500) wait.
            currentStep := currentStep + 1.
            [ self updateTimeTo: currentStep ] on: Error do: [ :ex | ex return ].
        ].
        autoplayProcess := nil
    ] forkAt: Processor userBackgroundPriority.

]

{ #category : 'autoplay' }
DroneBattleUI >> stopAutoplay [
    autoplayProcess ifNotNil: [
        autoplayProcess terminate.
        autoplayProcess := nil ].
]

{ #category : 'accessing' }
DroneBattleUI >> timeSlider [

	^ timeSlider
]

{ #category : 'accessing' }
DroneBattleUI >> timeSlider: anObject [

	timeSlider := anObject
]

{ #category : 'autoplay' }
DroneBattleUI >> toggleAutoplay [

	autoplayProcess
		ifNil: [ self startAutoplay ]
		ifNotNil: [ self stopAutoplay ]
]

{ #category : 'initialization' }
DroneBattleUI >> updateMissionInfo: fleets [
    | missionsText |
    missionsText := String streamContents: [:s |
        fleets do: [:f |
            f currentMission ifNotNil: [:m |
                s nextPutAll: f name , ' → ' , m missionType asString, Character cr asSting,
 'Zone: ' , (m zoneParameters printString), Character cr asSting, Character cr asSting ] ] ].
    infoText text: missionsText isEmpty ifTrue: [ 'Pas de mission active' ] ifFalse: [ missionsText ].
]

{ #category : 'initialization' }
DroneBattleUI >> updateTimeTo: step [
    currentStep := step.
    self refreshView.
]
