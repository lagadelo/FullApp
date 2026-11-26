Class {
	#name : 'Status',
	#superclass : 'Object',
	#instVars : [
		'currentStatus',
		'values'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'api' }
Status >> basicGet: aField [

	self doesExist: aField.
	^self currentStatus at: aField
]

{ #category : 'internal' }
Status >> basicSet: aField to: aValue [

	self currentStatus at: aField put: aValue
]

{ #category : 'internal' }
Status >> canSet: aField to: aValue [

	(self doesExist: aField) ifFalse: [ self error: 'Non existing field' ].

	((self values at: aField) isKindOf: Collection) ifFalse:[^true]. "Should compare class instead"
	^ (self values at: aField) includes: aValue
]

{ #category : 'accessing' }
Status >> currentStatus [

	^ currentStatus
]

{ #category : 'accessing' }
Status >> currentStatus: anObject [

	currentStatus := anObject
]

{ #category : 'initialization' }
Status >> defineField: field withValues: anObject [

	self values at: field put: anObject.
	self currentStatus at: field put: ((anObject isKindOf: Collection)
			 ifTrue: [ anObject first ]
			 ifFalse: [ "default value" anObject ])
]

{ #category : 'internal' }
Status >> doesExist: aField [  

	^ (self values includesKey: aField)  
]

{ #category : 'api' }
Status >> get: aField [

	self doesExist: aField.
	^self basicGet: aField
]

{ #category : 'initialization' }
Status >> initialize [ 
values := IdentityDictionary new.
currentStatus := IdentityDictionary new.
self initializeFields
]

{ #category : 'initialization' }
Status >> initializeFields [

	self
		defineField: #state
		withValues:
		{ #idle. #active. #damaged. #destroyed. #lost. #compromized }.
	self defineField: #role withValues: { #ally. #ennemy }.
	self defineField: #orientation withValues: (0 to: 360).
	self defineField: #speed withValues: (0 to: 100000 / 3600).
		self defineField: #position withValues: GeoPoint new
]

{ #category : 'api' }
Status >> set: aField to: aValue [

	(self canSet: aField to: aValue)
		ifTrue: [ self basicSet: aField to: aValue ]
		ifFalse: [ self error: 'Impossible value' ]
]

{ #category : 'api' }
Status >> set: aField toPercent: aValue [

	| max |
	self doesExist: aField.
	aValue < 0 | (aValue > 100) ifTrue: [ self error: 'Invalid value' ].

	max := (self values at: aField) asSortedCollection last.
	max isNumber ifFalse: [ self error: 'Only supports numerical values' ].
	self basicSet: aField to: max * aValue / 100
]

{ #category : 'accessing' }
Status >> values [

	^ values
]

{ #category : 'accessing' }
Status >> values: anObject [

	values := anObject
]
