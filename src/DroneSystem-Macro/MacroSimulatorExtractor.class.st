Class {
	#name : 'MacroSimulatorExtractor',
	#superclass : 'Object',
	#instVars : [
		'block',
		'label'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorExtractor class >> block: aBlock [


^self new block: aBlock; yourself 
]

{ #category : 'instance creation' }
MacroSimulatorExtractor class >> label: aLabel block: aBlock [

	^ (self block: aBlock)
		  label: aLabel;
		  yourself
]

{ #category : 'as yet unclassified' }
MacroSimulatorExtractor class >> process: aProcessing overField: p [

"	^ self block: [ :d |
			  | data |
			  data := d collect: [ :aMacroSimulatorMetrics |
				          aMacroSimulatorMetrics perform: p ].
			  aProcessing value: data ]"
	  ^self label:( aProcessing,'(',p,')') block: (
	

	OpalCompiler new
		 source: '[ :d |
			  | data |
			  data := d collect: [ :aMacroSimulatorMetrics |
				          aMacroSimulatorMetrics  ',p,' ].
			  data ',aProcessing ,' asFloat ]'; evaluate).
 
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> block [

	^ block
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> block: anObject [

	block := anObject
]

{ #category : 'eval' }
MacroSimulatorExtractor >> evaluateOn: aValue [

	^ self block value: aValue
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> label [

	label ifNil: [ self label: 'Block based processing' ].
	^ label
]

{ #category : 'accessing' }
MacroSimulatorExtractor >> label: anObject [

	label := anObject
]
