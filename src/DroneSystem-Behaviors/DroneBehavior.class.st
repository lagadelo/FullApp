Class {
	#name : 'DroneBehavior',
	#superclass : 'Object',
	#category : 'DroneSystem-Behaviors',
	#package : 'DroneSystem-Behaviors'
}

{ #category : 'as yet unclassified' }
DroneBehavior >> executeFor: aDrone atTime: aTime [
    self subclassResponsibility.
]
