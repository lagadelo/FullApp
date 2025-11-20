Class {
	#name : 'DroneShapes',
	#superclass : 'Shapes',
	#instVars : [
		'position',
		'ammunitions',
		'perceptionRange',
		'energy'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
DroneShapes >> ammunitions [

	^ ammunitions
]

{ #category : 'accessing' }
DroneShapes >> ammunitions: anObject [

	ammunitions := anObject
]

{ #category : 'accessing' }
DroneShapes >> energy [

	^ energy
]

{ #category : 'accessing' }
DroneShapes >> energy: anObject [

	energy := anObject
]

{ #category : 'coloring' }
DroneShapes >> hide: aField [

	| v |
	v := self perform: aField.
	v ifNotNil: [ v color alpha: 0 ]
]

{ #category : 'coloring' }
DroneShapes >> hideAll [

	self ammunitions ifNotNil: [
		self ammunitions color: Color transparent ].
	self energy ifNotNil: [ self energy color: Color transparent ].
	self perceptionRange ifNotNil: [
		self perceptionRange color: Color transparent.
		self perceptionRange borderColor: Color transparent ].
	self position ifNotNil: [
			position color: Color transparent.
			(position propertyAt: #RSLabeled) paint: Color transparent ]
]

{ #category : 'accessing' }
DroneShapes >> perceptionRange [

	^ perceptionRange
]

{ #category : 'accessing' }
DroneShapes >> perceptionRange: anObject [

	perceptionRange := anObject
]

{ #category : 'accessing' }
DroneShapes >> position [

	^ position
]

{ #category : 'accessing' }
DroneShapes >> position: anObject [

	position := anObject
]

{ #category : 'coloring' }
DroneShapes >> reset: aField [

	self perform: (aField , ':') asSymbol with: nil
]

{ #category : 'coloring' }
DroneShapes >> show: aField [

self perform: (#show,aField capitalized) asSymbol
]

{ #category : 'coloring' }
DroneShapes >> showAll [

self showAmmunitions.
self showEnergy.
self showPosition.
self showPerceptionRange 
]

{ #category : 'coloring' }
DroneShapes >> showAmmunitions [

self ammunitions ifNotNil:[	self ammunitions color: Color blue]
]

{ #category : 'coloring' }
DroneShapes >> showEnergy [

self energy ifNotNil:[	self energy color: ([ :a |
			 a < 0.4
				 ifTrue: [ Color red ]
				 ifFalse: [
						 a < 0.7
							 ifTrue: [ Color purple alpha: 0.3 ]
							 ifFalse: [ Color black ] ] ]
			 value: ((self model capabilities energy max: 0) / 100.0
			 min: 1.0))]
]

{ #category : 'coloring' }
DroneShapes >> showFollowing: anOverlayModel [

	anOverlayModel showAmmoBars ifTrue: [ self showAmmunitions ].
	anOverlayModel showEnergyBars ifTrue: [ self showEnergy ].
	"anOverlayModel showPosition" true ifTrue: [ self showPosition ].
	anOverlayModel showPerceptionRadius ifTrue: [ self showPerceptionRange ]
]

{ #category : 'coloring' }
DroneShapes >> showPerceptionRange [

self perceptionRange ifNotNil:[ self perceptionRange color: (Color lightBlue alpha: 0.15).
		self perceptionRange borderColor: (Color lightBlue alpha: 0.5)]
]

{ #category : 'coloring' }
DroneShapes >> showPosition [

	self position ifNotNil: [
			self position color: self model getColor.
			(position propertyAt: #RSLabeled) paint: Color black ]
]
