"
Fichier JSON d’une mission. Les sources Pharo restent du texte à la lecture.
Les historiques produits par le simulateur se rejouent depuis la mission.
"
Class {
	#name : 'SoSeAtelierMissionFile',
	#superclass : 'Object',
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'files' }
SoSeAtelierMissionFile class >> read: file [
	| document commands selection |
	document := STONJSON fromString: file asFileReference contents.
	((document isKindOf: Dictionary) and: [
		(document at: 'format' ifAbsent: [ nil ]) = 'sose-mission' and: [
			(document at: 'version' ifAbsent: [ nil ]) = 1 ] ])
		ifFalse: [ self error: 'Choisis un fichier de mission SoSe (version 1).' ].
	commands := document at: 'laws'.
	(commands isArray and: [ commands notEmpty and: [
		(commands collect: [ :law | law at: 'id' ]) asSet size = commands size ] ])
		ifFalse: [ self error: 'La mission doit contenir des lois aux identifiants distincts.' ].
	selection := document at: 'simulation'.
	selection at: 'distanceWeight' ifAbsentPut: [ 2 ]; at: 'bearingHalfAngle' ifAbsentPut: [ 180 ].
	(commands anySatisfy: [ :law | (law at: 'id') = (selection at: 'policy') ])
		ifFalse: [ self error: 'La loi sélectionnée manque dans le fichier de mission.' ].
	self validateSettings: document.
	^ document
]

{ #category : 'validation' }
SoSeAtelierMissionFile class >> validateSettings: document [
	| terrain simulation display example |
	terrain := document at: 'terrain'.
	simulation := document at: 'simulation'.
	display := document at: 'display'.
	example := document at: 'example'.
	((document at: 'scenario') isString and: [ (document at: 'source') isString and: [
		(example isNil or: [ example isString ]) and: [
			(terrain at: 'directory') isString and: [ (terrain at: 'source') isString and: [
				(terrain at: 'geoTiff') ifNil: [ true ] ifNotNil: #isString ] ] ] ] ])
		ifFalse: [ self error: 'Les réglages du scénario ou du terrain sont invalides.' ].
	self requireNumbers: (SoSeAtelierMissionPresenter numericFields copyWith: #nominalSpeed) in: simulation.
	self requireNumbers: #(gridStep margin) in: terrain.
	self requireNumbers: (SoSeAtelierOptionsPresenter numericalSettings copyWith: #normalRate) in: display.
	(SoSeAtelierOptionsPresenter passageFields, #(trackPassages)) do: [ :key |
		display at: key asString ifAbsentPut: [ false ] ].
	(SoSeAtelierOptionsPresenter checkboxSettings allSatisfy: [ :key | #(true false) includes: (display at: key asString) ])
		ifFalse: [ self error: 'Les options d’affichage doivent être cochées ou décochées.' ].
	((simulation at: 'perceptionMode') isString and: [
		(display at: 'background') isString and: [ (display at: 'droneColorMode') isString ] ])
		ifFalse: [ self error: 'Les modes de perception et d’affichage doivent être nommés.' ]
]

{ #category : 'validation' }
SoSeAtelierMissionFile class >> requireNumbers: keys in: settings [
	keys do: [ :key |
		| value |
		value := settings at: key asString.
		(value isNumber and: [ value asFloat isFinite ])
			ifFalse: [ self error: 'Valeur numérique requise pour ', key asString ] ]
]

{ #category : 'files' }
SoSeAtelierMissionFile class >> write: document to: file [
	| target temporary |
	target := file asFileReference asAbsolute.
	temporary := target parent / ('.mission-', UUID new asString, '.tmp').
	[ temporary writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toStringPretty: document) ].
		(File rename: (File encodePathString: temporary fullName) to: (File encodePathString: target fullName))
			ifNil: [ self error: 'Impossible d’enregistrer la mission dans ', target parent fullName ] ]
		ensure: [ temporary exists ifTrue: [ temporary delete ] ]
]
