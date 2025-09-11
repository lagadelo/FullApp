Class {
	#name : 'DroneStrategy',
	#superclass : 'Object',
	#category : 'DroneSystem-Strategies',
	#package : 'DroneSystem-Strategies'
}

{ #category : 'operations' }
DroneStrategy >> applyTo: aSimulation [
    self subclassResponsibility.

]
