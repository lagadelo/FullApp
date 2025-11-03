"
This class is intended to serve as a support for formal verification.
Assumptions are defined as blocks, taking the simulation as parameter.

'step' steps the simulation
'stepUntil:' steps the simulation until a given assumtion comes true
'stepUntilAny' steps until any of the assuption comes true
'stepWhile:' steps as long as a given assumption remains true
'stepWhileaAny' steps as long as at least one assumption remains true
'stepUntilNone' same as stepWhileaAny
'stepWhileNone' same as stepUntilAny
"
Class {
	#name : 'Verifier',
	#superclass : 'Object',
	#instVars : [
		'assumptions',
		'simulation'
	],
	#category : 'DroneSystem-Verification',
	#package : 'DroneSystem-Verification'
}

{ #category : 'instance creation' }
Verifier class >> on: aSimulation [

	^ self new
		  simulation: aSimulation;
		  yourself
]

{ #category : 'assumptions' }
Verifier >> addAssuption: name behavior: aBlock [

assumptions add: name -> aBlock 
]

{ #category : 'evaluating' }
Verifier >> assertedAssuptions [

	^ assumptions keys select: [ :a | assumptions at: a ]
]

{ #category : 'accessing' }
Verifier >> assumptions [

	^ assumptions
]

{ #category : 'evaluating' }
Verifier >> deniedAssuptions [

	^ assumptions keys reject: [ :a | assumptions at: a ]
]

{ #category : 'evaluating' }
Verifier >> evaluateAllAssuptions [

	^ assumptions keys collect: [ :a |
		  a -> ((assumptions at: a) value: simulation) ]
]

{ #category : 'evaluating' }
Verifier >> evaluateAssuption: name [  

^(assumptions at:  name) value: simulation
]

{ #category : 'initialize' }
Verifier >> initialize [ 

assumptions := IdentityDictionary new.

]

{ #category : 'assumptions' }
Verifier >> removeAssuption: name [

	assumptions remoeKey: name
]

{ #category : 'accessing' }
Verifier >> simulation [

	^ simulation
]

{ #category : 'accessing' }
Verifier >> simulation: anObject [

	simulation := anObject
]

{ #category : 'simulation steping' }
Verifier >> step [ 

	simulation step
]

{ #category : 'simulation steping' }
Verifier >> stepUntil: aName [

	[ self evaluateAssuption: aName ] whileFalse: [ self step ]
]

{ #category : 'simulation steping' }
Verifier >> stepUntilAny [

	[ self assertedAssuptions isEmpty ] whileTrue: [ self step ]
]

{ #category : 'simulation steping' }
Verifier >> stepUntilNone [

	^ self stepWhileAny
]

{ #category : 'simulation steping' }
Verifier >> stepWhile: aName [

	[ self evaluateAssuption: aName ] whileTrue: [ self step ]
]

{ #category : 'simulation steping' }
Verifier >> stepWhileAny [

	[ self assertedAssuptions isEmpty ] whileFalse: [ self step ]
]

{ #category : 'simulation steping' }
Verifier >> stepWhileNone [

	^self stepUntilAny 
]
