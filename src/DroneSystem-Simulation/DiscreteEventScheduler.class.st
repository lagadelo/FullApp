Class {
	#name : 'DiscreteEventScheduler',
	#superclass : 'Object',
	#instVars : [
		'eventQueue'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'initialization' }
DiscreteEventScheduler >> hasEvents [
    ^ eventQueue notEmpty.

]

{ #category : 'initialization' }
DiscreteEventScheduler >> initialize [
    eventQueue := SortedCollection sortBlock: [:e1 :e2 | e1 timestamp < e2 timestamp].

]

{ #category : 'initialization' }
DiscreteEventScheduler >> nextEvent [
    ^ eventQueue ifNotEmpty: [ eventQueue removeFirst ].

]

{ #category : 'initialization' }
DiscreteEventScheduler >> scheduleEvent: anEvent [
    eventQueue add: anEvent.

]
