Class {
	#name : 'CodeVersion',
	#superclass : 'Object',
	#instVars : [
		'versionId',
		'timestamp',
		'strategyName',
		'methodBlock',
		'droneIds',
		'previousVersion',
		'description'
	],
	#category : 'DroneSystem-Evaluation-CodeReload',
	#package : 'DroneSystem-Evaluation-CodeReload'
}

{ #category : 'initialization' }
CodeVersion >> initialize [
	super initialize.
	versionId := 0.
	timestamp := DateAndTime now.
	strategyName := #nextWayPointFor:.
	methodBlock := nil.
	droneIds := Set new.
	previousVersion := nil.
	description := ''
]

{ #category : 'accessing' }
CodeVersion >> versionId: anInteger [
	versionId := anInteger.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> strategyName: aSymbol [
	strategyName := aSymbol.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> methodBlock: aBlock [
	methodBlock := aBlock.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> forDroneIds: aCollection [
	droneIds addAll: aCollection.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> forAllDrones [
	droneIds := #all.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> description: aString [
	description := aString.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> linkedToPrevious: aCodeVersion [
	previousVersion := aCodeVersion.
	^ self
]

{ #category : 'accessing' }
CodeVersion >> previousVersion [
	^ previousVersion
]

{ #category : 'accessing' }
CodeVersion >> droneIds [
	^ droneIds
]

{ #category : 'accessing' }
CodeVersion >> methodBlock [
	^ methodBlock
]

{ #category : 'printing' }
CodeVersion >> printOn: aStream [
	aStream nextPutAll: 'CodeVersion(id:'; 
		nextPutAll: versionId asString;
		nextPutAll: ', strategy:'; 
		nextPutAll: strategyName asString;
		nextPutAll: ', @'; 
		nextPutAll: timestamp asString; nextPut: $)
]
