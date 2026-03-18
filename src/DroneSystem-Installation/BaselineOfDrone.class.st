Class {
	#name : 'BaselineOfDrone',
	#superclass : 'BaselineOf',
	#category : 'DroneSystem-Installation',
	#package : 'DroneSystem-Installation'
}

{ #category : 'baselines' }
BaselineOfDrone >> baseline: spec [

    <baseline>

    spec for: #common do: [

        spec
            baseline: 'XMLParser'
            with: [ spec repository: 'github://pharo-contributions/XML-XMLParser/src' ].

        spec
            baseline: 'OWS'
            with: [ spec repository: 'github://ThalesGroup/PharoOWS:main/src' ].

        spec
            baseline: 'NeoCSV'
            with: [ spec repository: 'github://svenvc/NeoCSV/src' ].

        spec repository: 'github://lagadelo/FullApp/src'.

        spec package: 'DroneSystem-Core'.
        spec package: 'DroneSystem-Missions'.
        spec package: 'DroneSystem-Simulation'.
        spec package: 'DroneSystem-Demo'.
        spec package: 'DroneSystem-Eval'.
        spec package: 'DroneSystem-Examples'.
        spec package: 'DroneSystem-Heuristics'.
        spec package: 'DroneSystem-Simulation Events'.
        spec package: 'DroneSystem-Simulation Strategy'.
        spec package: 'DroneSystem-UI'.
        spec package: 'DroneSystem-Utils'.
        spec package: 'DroneSystem-Verification'.
        spec package: 'DroneSystem-Visualization'
    ]
]
