Class {
	#name : 'TimingStrategy',
	#superclass : 'Object',
	#instVars : [
		'strategyType',
		'missionDuration',
		'parameters'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'computing' }
TimingStrategy >> computeTimeStepForEvent: eventIndex outOf: totalEvents [
	| timeStep |
	strategyType = #uniform ifTrue: [
		timeStep := (missionDuration / totalEvents) * eventIndex.
	] ifFalse: [
		strategyType = #concentrated ifTrue: [
			| phase intensity |
			phase := parameters at: #phase ifAbsent: [ #beginning ].
			intensity := 0.3.
			phase = #beginning ifTrue: [ timeStep := missionDuration * intensity * (eventIndex / totalEvents) ].
			phase = #middle ifTrue: [ timeStep := missionDuration * (0.35 + (intensity * (eventIndex / totalEvents))) ].
			phase = #end ifTrue: [ timeStep := missionDuration * (0.7 + (intensity * (eventIndex / totalEvents))) ].
		] ifFalse: [
			timeStep := eventIndex * 100.
		]
	].
	^ timeStep asInteger
]

{ #category : 'accessing' }
TimingStrategy >> concentrated: phase [
	"phase = #beginning, #middle, #end"
	strategyType := #concentrated.
	parameters at: #phase put: phase.
	^ self
]

{ #category : 'initialization' }
TimingStrategy >> initialize [
	super initialize.
	strategyType := #uniform.
	missionDuration := 1000.
	parameters := Dictionary new
]

{ #category : 'accessing' }
TimingStrategy >> missionDuration: aDuration [
	missionDuration := aDuration.
	^ self
]

{ #category : 'accessing' }
TimingStrategy >> phased: phaseList [
	"phaseList = #(#approach #engage #retreat)"
	strategyType := #phased.
	parameters at: #phases put: phaseList.
	^ self
]

{ #category : 'printing' }
TimingStrategy >> printOn: aStream [
	aStream nextPutAll: 'TimingStrategy('; nextPutAll: strategyType asString; nextPut: $)
]

{ #category : 'accessing' }
TimingStrategy >> uniform [
	strategyType := #uniform.
	^ self
]
