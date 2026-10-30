Class {
	#name : 'MacroSimulatorPerceptionObservation',
	#superclass : 'Object',
	#instVars : [
		'status',
		'trueArcGap',
		'euclideanDistance',
		'bearingDegrees',
		'estimatedGap',
		'candidateCount'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorPerceptionObservation class >> status: aStatus trueGap: aTrueGap distance: aDistance bearing: aBearing estimatedGap: anEstimatedGap candidates: aCount [
	^ self new
		status: aStatus;
		trueArcGap: aTrueGap;
		euclideanDistance: aDistance;
		bearingDegrees: aBearing;
		estimatedGap: anEstimatedGap;
		candidateCount: aCount;
		yourself
]

{ #category : 'measuring' }
MacroSimulatorPerceptionObservation >> absoluteGapError [
	(self estimatedGap isNil or: [ self trueArcGap isNil ]) ifTrue: [ ^ nil ].
	^ (self estimatedGap - self trueArcGap) abs
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> bearingDegrees [
	^ bearingDegrees
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> bearingDegrees: aNumber [
	bearingDegrees := aNumber
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> candidateCount [
	^ candidateCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> candidateCount: anInteger [
	candidateCount := anInteger
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> estimatedGap [
	^ estimatedGap
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> estimatedGap: aNumberOrNil [
	estimatedGap := aNumberOrNil
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> euclideanDistance [
	^ euclideanDistance
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> euclideanDistance: aNumber [
	euclideanDistance := aNumber
]

{ #category : 'testing' }
MacroSimulatorPerceptionObservation >> isAngular [
	^ self status = #angular
]

{ #category : 'testing' }
MacroSimulatorPerceptionObservation >> isDirect [
	^ self status = #direct
]

{ #category : 'testing' }
MacroSimulatorPerceptionObservation >> isOutOfRange [
	^ self status = #outOfRange
]

{ #category : 'testing' }
MacroSimulatorPerceptionObservation >> isUnobservable [
	^ #( unobservableAlignment unobservableAmbiguous unobservableNoIntersection noVision )
		includes: self status
]

{ #category : 'testing' }
MacroSimulatorPerceptionObservation >> isUsable [
	^ #( direct angular ) includes: self status
]

{ #category : 'printing' }
MacroSimulatorPerceptionObservation >> printOn: aStream [
	aStream
		nextPutAll: self status asString;
		nextPutAll: '(gap=';
		print: self estimatedGap;
		nextPutAll: ', true=';
		print: self trueArcGap;
		nextPutAll: ', d=';
		print: self euclideanDistance;
		nextPut: $)
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> status [
	^ status
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> status: aSymbol [
	status := aSymbol
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> trueArcGap [
	^ trueArcGap
]

{ #category : 'accessing' }
MacroSimulatorPerceptionObservation >> trueArcGap: aNumber [
	trueArcGap := aNumber
]
