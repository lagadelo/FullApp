Class {
	#name : 'UIParameterValue',
	#superclass : 'SpPresenter',
	#instVars : [
		'buttonOk',
		'buttonCancel',
		'target',
		'field',
		'returnsNumber',
		'retrainedValue'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
UIParameterValue class >> target: aTarget field: aField returnsNumber: bool [

	^ self new
		  target: aTarget;
		  field: aField;
		  returnsNumber: bool;
		  yourself
]

{ #category : 'buttons' }
UIParameterValue >> cancel [

self window close 
]

{ #category : 'initialization' }
UIParameterValue >> defaultLayout [

	^ SpBoxLayout newTopToBottom 
		  add: retrainedValue; add:
		
		(SpBoxLayout newLeftToRight add: buttonOk; add:buttonCancel;yourself )
]

{ #category : 'accessing' }
UIParameterValue >> field [

	^ field
]

{ #category : 'accessing' }
UIParameterValue >> field: anObject [

	field := anObject
]

{ #category : 'initialization' }
UIParameterValue >> initializePresenters [

 
	retrainedValue := self newTextInput.
	buttonOk := self newButton
		label: 'ok';
		icon: ((self iconNamed: #doIt) scaledToSize: 16 @ 16);
		action:[self validate];
		yourself.
	buttonCancel := self newButton 
		label: 'ok';
		icon: ((self iconNamed: #cancel) scaledToSize: 16 @ 16);
		action:[self cancel];
		yourself.
]

{ #category : 'buttons' }
UIParameterValue >> open [ 
     self initializePresenters.
        self layout: self defaultLayout "]".
    ^ (super open)
        withWindowDo: [ :w | w title: self field,' Selection']
]

{ #category : 'accessing' }
UIParameterValue >> retrainedValue [

	^ retrainedValue
]

{ #category : 'accessing' }
UIParameterValue >> retrainedValue: anObject [

	retrainedValue := anObject
]

{ #category : 'accessing' }
UIParameterValue >> returnsNumber [

	^ returnsNumber
]

{ #category : 'accessing' }
UIParameterValue >> returnsNumber: anObject [

	returnsNumber := anObject
]

{ #category : 'accessing' }
UIParameterValue >> target [

	^ target
]

{ #category : 'accessing' }
UIParameterValue >> target: anObject [

	target := anObject
]

{ #category : 'buttons' }
UIParameterValue >> validate [

	self target
		perform: (self field , ':') asSymbol
		withArguments: (Array with: (self returnsNumber
				 ifTrue: [ self retrainedValue text asNumber ]
				 ifFalse: [ self retrainedValue text  ])).
self cancel
]
