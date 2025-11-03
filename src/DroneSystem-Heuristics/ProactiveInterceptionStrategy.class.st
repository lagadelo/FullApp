Class {
	#name : 'ProactiveInterceptionStrategy',
	#superclass : 'Object',
	#category : 'DroneSystem-Heuristics',
	#package : 'DroneSystem-Heuristics'
}

{ #category : 'execution' }
ProactiveInterceptionStrategy >> executeOn: aSimulation [
    | hostiles allies |
    hostiles := aSimulation hostiles.
    allies := aSimulation allies.
    hostiles do: [:enemy |
        (allies select: [:d | d canPerceiveDrone: enemy]) do: [:drone |
            drone setBehavior: (GoToHelpBehavior new
                initializeWithPosition: { enemy latitude. enemy longitude. enemy altitude }) ] ].
]
