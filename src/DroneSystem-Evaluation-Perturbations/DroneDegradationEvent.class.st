Class {
	#name : 'DroneDegradationEvent',
	#superclass : 'PerturbationEvent',
	#instVars : [
		'degradationRate'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'accessing' }
DroneDegradationEvent >> degradationRate [
	^ degradationRate
]

{ #category : 'accessing' }
DroneDegradationEvent >> degradationRate: aFloat [
	degradationRate := aFloat.
	^ self
]

{ #category : 'initialization' }
DroneDegradationEvent >> initialize [
	super initialize.
	eventType := #degradation.
	degradationRate := 0.1
]

{ #category : 'printing' }
DroneDegradationEvent >> printOn: aStream [
	aStream nextPutAll: 'DEGRADE(drone:'; 
		nextPutAll: droneId asString; 
		nextPutAll: ', rate:'; 
		nextPutAll: degradationRate asString;
		nextPutAll: ', @t='; 
		nextPutAll: timeStep asString; nextPut: $)
]
