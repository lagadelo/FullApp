Class {
	#name : 'ABTestingDeployment',
	#superclass : 'Object',
	#instVars : [
		'strategyA',
		'strategyB',
		'groupADroneIds',
		'groupBDroneIds',
		'reloader'
	],
	#category : 'DroneSystem-Evaluation-CodeReload',
	#package : 'DroneSystem-Evaluation-CodeReload'
}

{ #category : 'deployment' }
ABTestingDeployment >> deploy [
	reloader notNil ifTrue: [
		reloader deployStrategy: strategyA 
			forDroneIds: groupADroneIds 
			named: #nextWayPointFor:.
		reloader deployStrategy: strategyB 
			forDroneIds: groupBDroneIds 
			named: #nextWayPointFor:
	].
	^ self
]

{ #category : 'accessing' }
ABTestingDeployment >> groupADrones: idCollection [
	groupADroneIds addAll: idCollection.
	^ self
]

{ #category : 'accessing' }
ABTestingDeployment >> groupBDrones: idCollection [
	groupBDroneIds addAll: idCollection.
	^ self
]

{ #category : 'initialization' }
ABTestingDeployment >> initialize [
	super initialize.
	strategyA := nil.
	strategyB := nil.
	groupADroneIds := Set new.
	groupBDroneIds := Set new.
	reloader := nil
]

{ #category : 'printing' }
ABTestingDeployment >> printOn: aStream [
	aStream nextPutAll: 'ABTestingDeployment(group_a:';
		nextPutAll: groupADroneIds size asString;
		nextPutAll: ', group_b:';
		nextPutAll: groupBDroneIds size asString; nextPut: $)
]

{ #category : 'accessing' }
ABTestingDeployment >> reloader: aReloader [
	reloader := aReloader.
	^ self
]

{ #category : 'accessing' }
ABTestingDeployment >> strategyA: aBlock [
	strategyA := aBlock.
	^ self
]

{ #category : 'accessing' }
ABTestingDeployment >> strategyB: aBlock [
	strategyB := aBlock.
	^ self
]
