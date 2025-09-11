Class {
	#name : 'DroneHeuristicUI',
	#superclass : 'Object',
	#instVars : [
		'alliesField',
		'hostilesField',
		'stepsField'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
DroneHeuristicUI class >> open [
    ^ self new open.

]

{ #category : 'instance creation' }
DroneHeuristicUI >> open [
    | builder window runButton |
    builder := SpBoxLayout newVertical.

    builder
        add: (SpLabel new label: 'Allied drones:');
        add: (alliesField := SpTextInputField new text: '10').

    builder
        add: (SpLabel new label: 'Hostile drones:');
        add: (hostilesField := SpTextInputField new text: '5').

    builder
        add: (SpLabel new label: 'Simulation steps:');
        add: (stepsField := SpTextInputField new text: '200').

    runButton := SpButton new
        label: 'Run Simulation';
        action: [ self runSimulation ].

    builder add: runButton.

    window := SpWindow new.
    window title: 'Drone Heuristic Simulator'.
    window add: builder.
    window open
]

{ #category : 'instance creation' }
DroneHeuristicUI >> runSimulation [
    | allies hostiles steps results |
    allies := alliesField text asInteger.
    hostiles := hostilesField text asInteger.
    steps := stepsField text asInteger.

    results := DroneHeuristicDemo
        runWithAllies: allies
        hostiles: hostiles
        steps: steps.

    UIManager default inform: 
        'Simulation finished. Results exported to strategies.csv'.
]
