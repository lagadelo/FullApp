Class {
	#name : 'ScheduledEvent',
	#superclass : 'Object',
	#instVars : [
		'timestamp',
		'simulationState',
		'id',
		'duration'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
ScheduledEvent >> affectedEntities [
    ^ Set new. "Par défaut, aucun effet — doit être redéfini"
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> affectsEntity: anEntity [
    ^ (self affectedEntities includes: anEntity)
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> affectsSameEntitiesAs: anotherEvent [
    ^ self affectedEntities = anotherEvent affectedEntities
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> duration [ 
^0
]

{ #category : 'accessing' }
ScheduledEvent >> duration: anObject [

	duration := anObject
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> endTimestamp [
 
^self timestamp + self duration
]

{ #category : 'executing' }
ScheduledEvent >> execute [
    self subclassResponsibility.

]

{ #category : 'executing' }
ScheduledEvent >> executeOn: aSimulator [

    self subclassResponsibility.

]

{ #category : 'testing' }
ScheduledEvent >> hasDuration [
    ^ self duration > 0.
]

{ #category : 'accessing' }
ScheduledEvent >> id [

	^ id
]

{ #category : 'accessing' }
ScheduledEvent >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
ScheduledEvent >> simulationState [

	^ simulationState
]

{ #category : 'accessing' }
ScheduledEvent >> simulationState: anObject [

	simulationState := anObject
]

{ #category : 'accessing' }
ScheduledEvent >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
ScheduledEvent >> timestamp: anObject [

	timestamp := anObject
]
