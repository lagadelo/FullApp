Class {
	#name : 'DroneActionChain',
	#superclass : 'Object',
	#instVars : [
		'tTask',
		'tTx',
		'tLaunch',
		'tIntercept',
		'tEffect',
		'cholesky',
		'rng'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'initialize' }
DroneActionChain >> initialize [

	tTask := StochasticParam fixed: 2.0.
	tTx := StochasticParam fixed: 0.2.
	tLaunch := StochasticParam fixed: 8.0.
	tIntercept := StochasticParam fixed: 45.0.
	tEffect := StochasticParam fixed: 5.0
]

{ #category : 'printing' }
DroneActionChain >> printBreakdownOn: aStream [

	aStream
		nextPutAll: '=== Action Chain ===';
		cr;
		nextPutAll: '  Ttask      : ' , tTask printString , ' s';
		cr;
		nextPutAll: '  Ttx        : ' , tTx printString , ' s';
		cr;
		nextPutAll: '  Tlaunch    : ' , tLaunch printString , ' s';
		cr;
		nextPutAll: '  Tintercept : ' , tIntercept printString , ' s';
		cr;
		nextPutAll: '  Teffect    : ' , tEffect printString , ' s';
		cr;
		nextPutAll: '  TOTAL      : ' , self totalSeconds printString , ' s';
		cr
]

{ #category : 'computing' }
DroneActionChain >> sampleSeconds [

	^ tTask sample + tTx sample + tLaunch sample + tIntercept sample
	  + tEffect sample
]

{ #category : 'accessing' }
DroneActionChain >> tEffect [

	^ tEffect
]

{ #category : 'accessing' }
DroneActionChain >> tEffect: anObject [

	tEffect := anObject
]

{ #category : 'accessing' }
DroneActionChain >> tIntercept [

	^ tIntercept
]

{ #category : 'accessing' }
DroneActionChain >> tIntercept: anObject [

	tIntercept := anObject
]

{ #category : 'accessing' }
DroneActionChain >> tLaunch [

	^ tLaunch
]

{ #category : 'accessing' }
DroneActionChain >> tLaunch: anObject [

	tLaunch := anObject
]

{ #category : 'accessing' }
DroneActionChain >> tTask [

	^ tTask
]

{ #category : 'accessing' }
DroneActionChain >> tTask: anObject [

	tTask := anObject
]

{ #category : 'accessing' }
DroneActionChain >> tTx [

	^ tTx
]

{ #category : 'accessing' }
DroneActionChain >> tTx: anObject [

	tTx := anObject
]

{ #category : 'computing' }
DroneActionChain >> totalSeconds [

	^ tTask + tTx + tLaunch + tIntercept + tEffect
]
