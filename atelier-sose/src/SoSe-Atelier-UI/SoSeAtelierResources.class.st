Class {
	#name : 'SoSeAtelierResources',
	#superclass : 'Object',
	#classVars : [ 'Directory' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'configuration' }
SoSeAtelierResources class >> directory: bundle [
	Directory := bundle asFileReference asAbsolute
]

{ #category : 'accessing' }
SoSeAtelierResources class >> directory [
	^ Directory ifNil: [ FileLocator imageDirectory asFileReference ]
]

{ #category : 'accessing' }
SoSeAtelierResources class >> examples [
	| file |
	file := self directory / 'terrains' / 'index.json'.
	^ file isFile ifTrue: [ STONJSON fromString: file contents ] ifFalse: [ #() ]
]

{ #category : 'accessing' }
SoSeAtelierResources class >> exampleNamed: id [
	^ self examples detect: [ :example | (example at: 'id') = id ] ifNone: [ nil ]
]

{ #category : 'accessing' }
SoSeAtelierResources class >> directoryFor: id [
	^ self directory / 'terrains' / id
]
