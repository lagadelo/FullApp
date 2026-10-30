Class {
	#name : 'MacroSimulatorInterval',
	#superclass : 'Object',
	#instVars : [
		'startIndex',
		'endIndex',
		'startTime',
		'endTime',
		'sampleCount'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorInterval class >> fromIndex: aStartIndex toIndex: anEndIndex startTime: aStartTime endTime: anEndTime [
	^ self new
		startIndex: aStartIndex;
		endIndex: anEndIndex;
		startTime: aStartTime;
		endTime: anEndTime;
		sampleCount: anEndIndex - aStartIndex + 1;
		yourself
]

{ #category : 'measuring' }
MacroSimulatorInterval >> duration [
	"In a discrete-time simulation, duration means number of sampled steps."
	^ self sampleCount
]

{ #category : 'measuring' }
MacroSimulatorInterval >> elapsedTime [
	"Physical elapsed time between first and last timestamps. For consecutive integer steps,
	this is duration - 1."
	^ self endTime - self startTime
]

{ #category : 'accessing' }
MacroSimulatorInterval >> endIndex [
	^ endIndex
]

{ #category : 'accessing' }
MacroSimulatorInterval >> endIndex: anInteger [
	endIndex := anInteger
]

{ #category : 'accessing' }
MacroSimulatorInterval >> endTime [
	^ endTime
]

{ #category : 'accessing' }
MacroSimulatorInterval >> endTime: aNumber [
	endTime := aNumber
]

{ #category : 'printing' }
MacroSimulatorInterval >> printOn: aStream [
	aStream
		nextPutAll: 'Interval[';
		print: self startTime;
		nextPutAll: '..';
		print: self endTime;
		nextPutAll: '; steps=';
		print: self sampleCount;
		nextPut: $]
]

{ #category : 'accessing' }
MacroSimulatorInterval >> sampleCount [
	^ sampleCount
]

{ #category : 'accessing' }
MacroSimulatorInterval >> sampleCount: anInteger [
	sampleCount := anInteger
]

{ #category : 'accessing' }
MacroSimulatorInterval >> startIndex [
	^ startIndex
]

{ #category : 'accessing' }
MacroSimulatorInterval >> startIndex: anInteger [
	startIndex := anInteger
]

{ #category : 'accessing' }
MacroSimulatorInterval >> startTime [
	^ startTime
]

{ #category : 'accessing' }
MacroSimulatorInterval >> startTime: aNumber [
	startTime := aNumber
]
