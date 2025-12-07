Class {
	#name : 'DroneDestructionEvent',
	#superclass : 'PerturbationEvent',
	#instVars : [
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'initialization' }
DroneDestructionEvent >> initialize [
	super initialize.
	eventType := #destruction
]

{ #category : 'printing' }
DroneDestructionEvent >> printOn: aStream [
	aStream nextPutAll: 'DESTROY(drone:'; 
		nextPutAll: droneId asString; 
		nextPutAll: ', @t='; 
		nextPutAll: timeStep asString; nextPut: $)
]
