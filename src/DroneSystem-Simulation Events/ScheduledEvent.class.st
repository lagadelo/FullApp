Class {
	#name : 'ScheduledEvent',
	#superclass : 'Object',
	#instVars : [
		'timestamp',
		'simulationState',
		'id',
		'duration',
		'executed',
		'model'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
ScheduledEvent class >> model: aModel [

^self new model: aModel; yourself
]

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

" Should refactor - which events have a real duration?"
^ duration ifNil:[^duration := 0]    ifNotNil:[duration]
]

{ #category : 'accessing' }
ScheduledEvent >> duration: anObject [

	duration := anObject
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> endTime [ 
^self timestamp + self duration 
 
]

{ #category : 'as yet unclassified' }
ScheduledEvent >> endTimestamp [
 
^self timestamp + self duration
]

{ #category : 'executing' }
ScheduledEvent >> executeOn: aSimulator [

    self subclassResponsibility.

]

{ #category : 'testing' }
ScheduledEvent >> hasDuration [
    ^ self duration > 0.
]

{ #category : 'testing' }
ScheduledEvent >> hasExecuted [
    ^ executed = true.

]

{ #category : 'accessing' }
ScheduledEvent >> id [

	^ id
]

{ #category : 'accessing' }
ScheduledEvent >> id: anObject [

	id := anObject
]

{ #category : 'initialization' }
ScheduledEvent >> initialize [ 
executed  := false
]

{ #category : 'executing' }
ScheduledEvent >> markAsExecuted [
    executed := true
]

{ #category : 'accessing' }
ScheduledEvent >> model [

	^ model
]

{ #category : 'accessing' }
ScheduledEvent >> model:anObject [

	 model := anObject
]

{ #category : 'printing' }
ScheduledEvent >> printOn:aStream [
aStream nextPutAll: self className ,' ', self timestamp printing,' for ',self id printString;cr
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
