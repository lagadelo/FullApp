Class {
	#name : 'AdaptiveEnergyStrategy',
	#superclass : 'Object',
	#traits : 'TDroneStrategy',
	#classTraits : 'TDroneStrategy classTrait',
	#category : 'DroneSystem-Heuristics',
	#package : 'DroneSystem-Heuristics'
}

{ #category : 'execution' }
AdaptiveEnergyStrategy >> executeOn: aSimulation [
    | critical |
    critical := aSimulation clusters collect: [:c | c clusterCenter ].
    aSimulation allies do: [:drone |
        | target |
        target := critical detectMin: [:center |
            (drone distanceToLatitude: center y longitude: center x altitude: 0) ].
        drone setBehavior: (StaticPositionBehavior new
            initializeWithLatitude: target y longitude: target x altitude: 100) ].


]
