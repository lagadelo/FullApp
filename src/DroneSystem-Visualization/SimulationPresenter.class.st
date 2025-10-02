Class {
	#name : 'SimulationPresenter',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'runningProcess',
		'timeText',
		'dronePresenter',
		'missionPresenter'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'instance creation' }
SimulationPresenter class >> openOn: aSimulator [

self new simulator: aSimulator; openWithSpec.
]

{ #category : 'initialization' }
SimulationPresenter >> buildWith: builder [
    <spec: #default>

    | canvas buttons timeLabel missionsPresenter clustersPresenter dronesList |

    "Canvas à gauche"
    canvas := builder canvas.
    canvas width: 400; height: 600.

    "Affichage du temps"
    timeLabel := builder label.
    timeLabel label: 'Time: 00:00:00'.

    "Boutons"
    buttons := builder newRow.
    buttons button
        label: 'Start';
        icon: (self iconNamed: #smallDoIt);
        action: [ self startSimulation ].
    buttons button
        label: 'Halt';
        icon: (self iconNamed: #pause);
        action: [ self haltSimulation ].
    buttons button
        label: 'Stop';
        icon: (self iconNamed: #smallStop);
        action: [ self stopSimulation ].

    "Instanciation des présentateurs"
    missionsPresenter := MissionPresenter new.
    clustersPresenter := ClusterPresenter new.
    dronesList := DroneListPresenter new.

    "Organisation principale"
    builder
        newRow: [
            builder
                newColumn: [
                    canvas.
                ];
                newColumn: [
                    "Zone fixe : boutons + temps"
                    builder newRow: [
                        buttons.
                        builder add: timeLabel.
                    ].
                    "Zone scrollable : missions, clusters, drones"
                    builder newColumn: [
                        builder add: missionsPresenter.
                        builder add: clustersPresenter.
                        builder add: dronesList.
                    ] scroller.
                ].
        ].

]

{ #category : 'initialization' }
SimulationPresenter >> doRun [
    runningProcess ifNotNil: [ runningProcess terminate ].
    runningProcess := [
        [ simulator hasEvents and: [ simulator currentTime <= 100 ] ] whileTrue: [
            simulator step.
            self updateTime.
            (Delay forMilliseconds: 100) wait.
        ].
    ] fork.
]

{ #category : 'initialization' }
SimulationPresenter >> doStep [
    simulator step.
    self updateTime.
]

{ #category : 'initialization' }
SimulationPresenter >> initializeWidgets [
    timeText := ValueHolder with: 'Time: 0'.
    dronePresenter := DroneListPresenter new.
    missionPresenter := MissionPresenter new.
]

{ #category : 'initialization' }
SimulationPresenter >> simulator: aSim [
    simulator := aSim.
    dronePresenter simulator: simulator.
    missionPresenter simulator: simulator.
]

{ #category : 'initialization' }
SimulationPresenter >> updateTime [
    timeText contents: 'Time: ', simulator currentTime printString.

]
