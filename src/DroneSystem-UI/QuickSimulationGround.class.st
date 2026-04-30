Class {
	#name : 'QuickSimulationGround',
	#superclass : 'Object',
	#instVars : [
		'autoRefresh',
		'canvas',
		'morph',
		'model',
		'ids',
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
QuickSimulationGround class >> represent: aModel [

^self new
]

{ #category : 'visiting' }
QuickSimulationGround >> acceptMacroSimulator: step [



]

{ #category : 'model' }
QuickSimulationGround >> addModel: aModel withID: anID [

	self ids add: anID -> aModel
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

{ #category : 'building' }
QuickSimulationGround >> buildFrom: tmp [
 
self model: tmp.
self buildFromModel.

]

{ #category : 'building' }
QuickSimulationGround >> buildFromModel [

^self subclassResponsibility 

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

	^(self ids at: anID) 
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
QuickSimulationGround >> ids [

	^ ids
]

{ #category : 'accessing' }
QuickSimulationGround >> ids: anObject [

	ids := anObject
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

"ids links ID to model elements (eg. drones)
rsObjects links model elements to forms (eg. RSCircle)"


	ids := Dictionary new.
	rsObjects  := Dictionary new.
	self autoRefresh: true.
]

{ #category : 'accessing' }
QuickSimulationGround >> model [

	^ model
]

{ #category : 'accessing' }
QuickSimulationGround >> model: anObject [

	model := anObject
]

{ #category : 'accessing' }
QuickSimulationGround >> morph [

	^ morph
]

{ #category : 'accessing' }
QuickSimulationGround >> morph: anObject [

	morph := anObject
]

{ #category : 'building' }
QuickSimulationGround >> nodePopup [

	| view |
	view := self.
	^ RSPopup new
		  text: [ :m |
				  '#' , (view model hull points indexOf: m) printString
				  , String lf , m printString , String lf
				  , (view model hull distanceFromOrigin at: m) rounded printString
				  , ' km' ];
		  yourself
]

{ #category : 'gui' }
QuickSimulationGround >> open [ 

 self morph  openInWindowLabeled: self printString , self className
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

	self ids removeKey: anID
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
