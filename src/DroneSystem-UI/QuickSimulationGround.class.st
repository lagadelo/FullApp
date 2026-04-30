Class {
	#name : 'QuickSimulationGround',
	#superclass : 'Object',
	#instVars : [
		'autoRefresh',
		'canvas',
		'morph',
		'model',
		'rsObjects',
		'background',
		'imageSize'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
QuickSimulationGround class >> exampleBrittany [

^self buildFrom:  MissionFactory example.
	 
]

{ #category : 'model' }
QuickSimulationGround >> addModel: aModel withID: anID [

	self model add: anID -> aModel
]

{ #category : 'model' }
QuickSimulationGround >> addShape: aShape withModel: aModel [

	self updateShapePosition: aShape.
	self rsObjects add: aModel -> aShape.
	self canvas add: aShape.
	self update
]

{ #category : 'accessing' }
QuickSimulationGround >> autoRefresh [

	^ autoRefresh
]

{ #category : 'accessing' }
QuickSimulationGround >> autoRefresh: anObject [

	autoRefresh := anObject
]

{ #category : 'accessing' }
QuickSimulationGround >> background [

	background ifNil: [ self buildBackground ].
	^ background
]

{ #category : 'accessing' }
QuickSimulationGround >> background: anObject [

	background := anObject
]

{ #category : 'accessing' }
QuickSimulationGround >> buidBackground [

	^ self subclassResponsibility 
]

{ #category : 'getter' }
QuickSimulationGround >> build [
	canvas ifNil: [
			canvas := RSCanvas new.
			canvas add: ((RSBitmap new form: self background)  ).
			canvas @ RSCanvasController.


			morph := canvas createMorph.
			morph extent: self background extent "important: sinon pas de scroll" . canvas zoomToFit.]
]

{ #category : 'accessing' }
QuickSimulationGround >> canvas [

	^ canvas
]

{ #category : 'accessing' }
QuickSimulationGround >> canvas: anObject [

	canvas := anObject
]

{ #category : 'updating' }
QuickSimulationGround >> forceRefresh [

	self morph signalUpdate
]

{ #category : 'model' }
QuickSimulationGround >> getID: anID [

	^(self model at: anID) 
]

{ #category : 'model' }
QuickSimulationGround >> getShapeFromID: anID [

	^(self rsObjects at: (self getID:anID) )
]

{ #category : 'model' }
QuickSimulationGround >> getShapeFromModel: aModel [

	^(self rsObjects at: aModel) 
]

{ #category : 'accessing' }
QuickSimulationGround >> imageSize [

	^ imageSize
]

{ #category : 'accessing' }
QuickSimulationGround >> imageSize: anObject [

	imageSize := anObject
]

{ #category : 'initialize' }
QuickSimulationGround >> initialize [

"model links ID to model elements (eg. drones)
rsObjects links model elements to forms (eg. RSCircle)"


	model := Dictionary new.
	rsObjects  := Dictionary new.
	self autoRefresh: true.
]

{ #category : 'accessing' }
QuickSimulationGround >> morph [

	^ morph
]

{ #category : 'accessing' }
QuickSimulationGround >> morph: anObject [

	morph := anObject
]

{ #category : 'gui' }
QuickSimulationGround >> openWithScroller [

	| scroll |
	self build.

	scroll := ScrollPane new.
	scroll scroller addMorph: self morph.


	scroll extent: 700 @ 600.

	scroll openInWindowLabeled: self printString , ' with scrollers'
]

{ #category : 'model' }
QuickSimulationGround >> removeID: anID [

	self model removeKey: anID
]

{ #category : 'accessing' }
QuickSimulationGround >> rsObjects [

	^ rsObjects
]

{ #category : 'accessing' }
QuickSimulationGround >> rsObjects: anObject [

	rsObjects := anObject
]

{ #category : 'updating' }
QuickSimulationGround >> update [ 

	self autoRefresh ifTrue: [ self forceRefresh ]
]

{ #category : 'as yet unclassified' }
QuickSimulationGround >> updateShapePosition: aShape [

	self subclassResponsibility
]

{ #category : 'visiting' }
QuickSimulationGround >> visit: aNode [

	^aNode accept: self
]

{ #category : 'visiting' }
QuickSimulationGround >> visitDrone: aNode [

	 
]

{ #category : 'visiting' }
QuickSimulationGround >> visitMacroSimulationStep: aNode [

	 
]

{ #category : 'visiting' }
QuickSimulationGround >> visitMacroSimulator: aNode [

	 
]

{ #category : 'visiting' }
QuickSimulationGround >> visitMission: aNode [

	 
]
