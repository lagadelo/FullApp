Class {
	#name : 'DiscreteEventScheduler',
	#superclass : 'Object',
	#instVars : [
		'eventQueue',
		'eventGraph'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'accessing' }
DiscreteEventScheduler >> eventGraph [

	^ eventGraph
]

{ #category : 'accessing' }
DiscreteEventScheduler >> eventGraph: anObject [

	eventGraph := anObject
]

{ #category : 'accessing' }
DiscreteEventScheduler >> eventQueue [

	^ eventQueue
]

{ #category : 'accessing' }
DiscreteEventScheduler >> eventQueue: anObject [

	eventQueue := anObject
]

{ #category : 'initialization' }
DiscreteEventScheduler >> hasEvents [
    ^ eventQueue notEmpty.

]

{ #category : 'initialization' }
DiscreteEventScheduler >> initialize [
    eventQueue := SortedCollection sortBlock: [:e1 :e2 | e1 timestamp < e2 timestamp].
	 eventGraph := EventDependencyGraph new.
]

{ #category : 'add-remove' }
DiscreteEventScheduler >> markAsExecuted: anEvent [

"cascade timestamp updates to dependencies"
^self eventGraph markAsExecuted: anEvent
]

{ #category : 'initialization' }
DiscreteEventScheduler >> nextEvent [
    ^ eventQueue ifNotEmpty: [ eventQueue removeFirst ].

]

{ #category : 'initialization' }
DiscreteEventScheduler >> potentialNextEvent [
    ^ eventQueue ifNotEmpty: [ eventQueue first ].

]

{ #category : 'initialization' }
DiscreteEventScheduler >> removeAllEventsFor:target after: aTimestamp [
    eventQueue removeAll: (eventQueue select:[:anEvent| anEvent drone = target ])

]

{ #category : 'initialization' }
DiscreteEventScheduler >> scheduleEvent: anEvent [
    eventQueue add: anEvent.

]

{ #category : 'initialization' }
DiscreteEventScheduler >> synchonizeAllEvents: kindOfEvent after: aTimestamp [

	(eventQueue select: [ :anEvent |
		 anEvent endTimestamp >= aTimestamp
		 & (anEvent isKindOf: kindOfEvent) ]) do: [ :anEvent |
		anEvent synchronizeAt: aTimestamp ]
]
