Trait {
	#name : 'TDroneStrategy',
	#category : 'DroneSystem-Heuristics',
	#package : 'DroneSystem-Heuristics'
}

{ #category : 'execution' }
TDroneStrategy >> executeOn: aSimulation [
    | rand |
    rand := Random new.
    aSimulation allies do: [:drone |
        (rand next < 0.5)
            ifTrue: [ drone setBehavior: (PatrolBehavior new
                initializeWithWaypoints: { { 48.85. 2.35. 100 }. { 50.11. 8.68. 100 } }) ]
            ifFalse: [ drone setBehavior: (StaticPositionBehavior new
                initializeWithLatitude: 52.52 longitude: 13.40 altitude: 120) ] ].


]
