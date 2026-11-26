Class {
	#name : 'SoSeAtelierFormPresenter',
	#superclass : 'SpPresenter',
	#instVars : [ 'fields' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierFormPresenter >> initializePresenters [
	fields := Dictionary new
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> field: key [
	^ fields at: key
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> number: key initial: value from: low to: high [
	| input |
	input := self newNumberInput.
	value isInteger ifFalse: [ input beFloat; digits: 6 ].
	input rangeMinimum: low maximum: high; number: value.
	fields at: key put: input.
	^ input
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> check: key label: title initial: state [
	^ fields at: key put: (self newCheckBox label: title; state: state; yourself)
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> choice: key labels: items [
	^ fields at: key put: (self newDropList
		display: [ :entry | entry value ];
		items: items;
		selectFirst;
		yourself)
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> slider: key initial: value from: low to: high [
	^ fields at: key put: (self newSlider
		min: low; max: high; quantum: 1; value: value; yourself)
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> choiceValue: key [
	^ (self field: key) selectedItem key
]

{ #category : 'widgets' }
SoSeAtelierFormPresenter >> selectChoice: value ofField: key [
	| menu |
	menu := self field: key.
	menu selectItem: (menu items detect: [ :entry | entry key = value ] ifNone: [ menu items first ])
]

{ #category : 'layout' }
SoSeAtelierFormPresenter >> row: title field: key [
	^ SpBoxLayout newLeftToRight
		spacing: 6;
		add: (self newLabel label: title; yourself) width: 139;
		add: (self field: key);
		yourself
]

{ #category : 'layout' }
SoSeAtelierFormPresenter >> column [
	^ SpBoxLayout newTopToBottom borderWidth: 8; spacing: 5; yourself
]

{ #category : 'layout' }
SoSeAtelierFormPresenter >> scrollPage: aLayout [
	| panel |
	panel := self newPresenter layout: aLayout; yourself.
	^ self newPresenter
		layout: (SpBoxLayout newTopToBottom
			add: (SpScrollableLayout new withoutHScrollbar; child: panel; yourself);
			yourself);
		yourself
]
