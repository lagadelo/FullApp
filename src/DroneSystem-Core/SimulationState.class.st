Class {
	#name : 'SimulationState',
	#superclass : 'Object',
	#instVars : [
		'time',
		'allFleets',
		'missions',
		'eventLog',
		'missionHistory',
		'reactionLog',
		'engagementMode',
		'steps',
		'verificationFunctions',
		'observers'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'facilities' }
SimulationState >> entitiesInPerceptionRangeOf: aDrone [
    ^ self allDrones select: [:e |
        (e position distanceTo: aDrone position) <= aDrone perceptionRange
    ].

]

{ #category : 'event processing' }
SimulationState >> updateDrone: aDrone with:consummable value: aValue [
     aDrone consumables at: consummable put:    aValue.

]

{ #category : 'event processing' }
SimulationState >> updateDrone: aDrone withPosition: aPosition [
aDrone position: aPosition.
^nil
]
