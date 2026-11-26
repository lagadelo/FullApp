"
Une loi éditable de l’atelier. Le code est un bloc Pharo qui prend une
SoSeAtelierLocalInput et renvoie un déplacement en mètres par tik.
"
Class {
	#name : 'SoSeAtelierCommandLaw',
	#superclass : 'Object',
	#instVars : [ 'id', 'label', 'source' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierCommandLaw class >> id: identifier label: aLabel source: code [
	^ self new initializeId: identifier label: aLabel source: code
]

{ #category : 'instance creation' }
SoSeAtelierCommandLaw class >> fromJSON: dictionary [
	| key code |
	key := (dictionary at: 'id') asSymbol.
	code := dictionary at: 'source'.
	code = (self legacySourceFor: key) ifTrue: [ code := self originalSourceFor: key ].
	^ self id: key label: (dictionary at: 'label') source: code
]

{ #category : 'presets' }
SoSeAtelierCommandLaw class >> presets [
	^ SoSeAtelierSimulation commandChoices collect: [ :entry |
		self id: entry key label: entry value source: (self originalSourceFor: entry key) ]
]

{ #category : 'presets' }
SoSeAtelierCommandLaw class >> originalSourceFor: key [
	^ (self legacySourceFor: key) ifNotNil: [ :code |
		code copyReplaceAll: '2 * local relativeGapError' with: 'local distanceWeight * local relativeGapError' ]
]

{ #category : 'presets' }
SoSeAtelierCommandLaw class >> legacySourceFor: key [
	^ key caseOf: {
		[ #capingPolicy ] -> [ '[ :local |
	local hasBothGaps
		ifFalse: [ local currentSpeed ]
		ifTrue: [
			local scaledSpeed: (local balanced
				ifTrue: [ local pacingRate ]
				ifFalse: [ 1 + (2 * local relativeGapError) ]) ] ]' ].
		[ #revisedCapingPolicy ] -> [ '[ :local |
	local hasBothGaps
		ifFalse: [ local currentSpeed ]
		ifTrue: [ local balanced
			ifTrue: [ local toward: local nominalSpeed ]
			ifFalse: [ local scaledSpeed: 1 + (2 * local relativeGapError) ] ] ]' ].
		[ #revisitCapingPolicy ] -> [ '[ :local |
	local hasBothGaps
		ifFalse: [ local currentSpeed ]
		ifTrue: [ local balanced
			ifTrue: [
				| seconds reference |
				seconds := local revisitTargetSeconds.
				reference := local nominalSpeed.
				seconds ifNotNil: [
					reference := (reference max: (local gapAhead max: local gapBehind)
						/ seconds * local secondsPerTick) min: local maxSpeed ].
				(local toward: reference) max: local minSpeed ]
			ifFalse: [ local scaledSpeed: 1 + (2 * local relativeGapError) ] ] ]' ] }
		otherwise: [ nil ]
]

{ #category : 'initialization' }
SoSeAtelierCommandLaw >> initializeId: identifier label: aLabel source: code [
	id := identifier.
	self label: aLabel source: code
]

{ #category : 'accessing' }
SoSeAtelierCommandLaw >> id [ ^ id ]

{ #category : 'accessing' }
SoSeAtelierCommandLaw >> label [ ^ label ]

{ #category : 'accessing' }
SoSeAtelierCommandLaw >> source [ ^ source ]

{ #category : 'accessing' }
SoSeAtelierCommandLaw >> label: aLabel source: code [
	(aLabel isString and: [ aLabel trimBoth notEmpty and: [ code isString ] ])
		ifFalse: [ self error: 'Nomme la loi et fournis un bloc Pharo.' ].
	label := aLabel trimBoth.
	source := code
]

{ #category : 'testing' }
SoSeAtelierCommandLaw >> isOriginal [
	^ source = (self class originalSourceFor: id)
]

{ #category : 'compilation' }
SoSeAtelierCommandLaw >> compileBlock [
	| tree |
	tree := OCParser parseExpression: source.
	(tree isBlock and: [ tree arguments size = 1 ])
		ifFalse: [ self error: 'Saisis un bloc [ :local | … ] à un seul argument.' ].
	^ Smalltalk compiler evaluate: source
]

{ #category : 'serializing' }
SoSeAtelierCommandLaw >> asJSON [
	^ { 'id' -> id asString. 'label' -> label. 'source' -> source } asDictionary
]
