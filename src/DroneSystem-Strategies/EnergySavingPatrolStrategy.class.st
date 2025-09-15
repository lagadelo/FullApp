Class {
	#name : 'EnergySavingPatrolStrategy',
	#superclass : 'Object',
	#instVars : [
		'activeRatio',
		'cycleLength',
		'lastAppliedAt'
	],
	#category : 'DroneSystem-Strategies',
	#package : 'DroneSystem-Strategies'
}

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> activeRatio [

	^ activeRatio
]

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> activeRatio: anObject [

	activeRatio := anObject
]

{ #category : 'initialization' }
EnergySavingPatrolStrategy >> applyTo: aSimulation [
    | allies alliesList t activeCount |
    alliesList := aSimulation allAlliedDrones.
    alliesList isEmpty ifTrue: [ ^ self ].
    t := aSimulation time.
    (lastAppliedAt notNil and: [ (t - lastAppliedAt) < cycleLength ]) ifTrue: [ ^ self ].
    lastAppliedAt := t.
    activeCount := (alliesList size * activeRatio) asInteger max: 1.
    alliesList withIndexDo: [:d :i |
        (i <= activeCount)
            ifTrue: [ d setBehavior: (PatrolBehavior new initializeWithWaypoints: { { d latitude . d longitude . d altitude } }) ]
            ifFalse: [ d setBehavior: (StaticPositionBehavior new initializeWithLatitude: d latitude longitude: d longitude altitude: d altitude) ]
    ].
    Transcript show: 'EnergySavingPatrolStrategy applied at time ', t asString; cr.
    ^ self.

]

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> cycleLength [

	^ cycleLength
]

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> cycleLength: anObject [

	cycleLength := anObject
]

{ #category : 'as yet unclassified' }
EnergySavingPatrolStrategy >> executeFor: aDrone in: aSimulation [
    "Déplacer le drone vers l’allié le plus proche qui est en difficulté (par ex. attaqué ou faible en énergie)."
    | allyToHelp |
    allyToHelp := aSimulation allAlliedDrones
        detect: [:ally | ally ~~ aDrone and: [ ally isInDanger ]]
        ifNone: [ nil ].

    allyToHelp ifNotNil: [
        aDrone moveToward: allyToHelp position.
        aDrone consumeFuel: 2 ].

]

{ #category : 'initialization' }
EnergySavingPatrolStrategy >> initializeWithActiveRatio: ratio cycleLength: cycles [
    activeRatio := ratio. cycleLength := cycles. lastAppliedAt := nil. ^ self.
]

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> lastAppliedAt [

	^ lastAppliedAt
]

{ #category : 'accessing' }
EnergySavingPatrolStrategy >> lastAppliedAt: anObject [

	lastAppliedAt := anObject
]
