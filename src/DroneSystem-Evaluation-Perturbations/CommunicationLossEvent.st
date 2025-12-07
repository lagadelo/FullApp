Class {
	#name : 'CommunicationLossEvent',
	#superclass : 'PerturbationEvent',
	#instVars : [
		'duration'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'initialization' }
CommunicationLossEvent >> initialize [
	super initialize.
	eventType := #commLoss.
	duration := 10
]

{ #category : 'accessing' }
CommunicationLossEvent >> duration: aNumber [
	duration := aNumber.
	^ self
]

{ #category : 'accessing' }
CommunicationLossEvent >> duration [
	^ duration
]

{ #category : 'printing' }
CommunicationLossEvent >> printOn: aStream [
	aStream nextPutAll: 'COMM_LOSS(drone:'; 
		nextPutAll: droneId asString; 
		nextPutAll: ', duration:'; 
		nextPutAll: duration asString;
		nextPutAll: ', @t='; 
		nextPutAll: timeStep asString; nextPut: $)
]
