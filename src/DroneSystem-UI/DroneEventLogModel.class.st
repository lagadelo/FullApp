Class {
	#name : 'DroneEventLogModel',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'maxSize'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'initialization' }
DroneEventLogModel >> addEvent: evt [
    self addString: ((evt respondsTo: #summaryString)
        ifTrue: [ evt summaryString ]
        ifFalse: [ evt printString ])
]

{ #category : 'initialization' }
DroneEventLogModel >> addString: aString [
    entries add: (String streamContents: [ :s |
        s nextPutAll: (DateAndTime now printString).
        s nextPutAll: ' | '.
        s nextPutAll: aString ]).
    (entries size > maxSize) ifTrue: [ entries removeFirst ]
]

{ #category : 'initialization' }
DroneEventLogModel >> entries [
    ^ entries copy
]

{ #category : 'accessing' }
DroneEventLogModel >> entries: anObject [

	entries := anObject
]

{ #category : 'initialization' }
DroneEventLogModel >> initialize [
    entries := OrderedCollection new.
    maxSize := 300.
]

{ #category : 'accessing' }
DroneEventLogModel >> maxSize [

	^ maxSize
]

{ #category : 'initialization' }
DroneEventLogModel >> maxSize: anInteger [
    maxSize := anInteger
]
