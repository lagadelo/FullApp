Class {
	#name : 'QuickCircular',
	#superclass : 'QuickSimulationGround',
	#instVars : [
		'radius'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
QuickCircular class >> buildFrom: tmp [

	^self new buildFrom: tmp
]

{ #category : 'examples' }
QuickCircular class >> exampleBrittany [
^super exampleBrittany
]

{ #category : 'getter' }
QuickCircular >> buildBackground [
| form   tmp |
form := Form extent: 500 @ 500 depth: 32.
form fillColor: Color white.

tmp := FormCanvas on: form.
tmp
    frameOval: (Rectangle center: 250 @ 250 extent: 400 @ 400)
    width: 4
    color: Color black.

self background: form.
]

{ #category : 'building' }
QuickCircular >> buildFrom: tmp [
	"We represent the model as a ring of circles"

	| radius hullShapes hull |
	self openWithScroller.
	radius := 200.
	"First we need to compute distance from start"

	hull := tmp hull.
	"We build the circles, one per point"
	hullShapes := RSCircle models: tmp hull points.
	hullShapes color: Color red.
	hullShapes size: 20.
	hullShapes do: [ :aShape |
			| ratio rad |
			"Comes from p = 2 Pi r"
			ratio := (hull distanceFromOrigin at: aShape model)
			         / hull totalDistance.
			rad := ratio * 2 * Float pi.
			aShape position: rad cos * radius @ (rad sin * radius negated).
			" Then we conform to our API"
			"aShape model: (Array with: v model with: rad with: (distances at:i))."
			self addShape: aShape withModel: (Array
					 with: aShape model
					 with: rad
					 with: (hull distanceFromOrigin at: aShape model)).
			aShape @ RSPopup new ]
]

{ #category : 'initialize' }
QuickCircular >> initialize [

	super initialize.
	self radius: 200
]

{ #category : 'getter' }
QuickCircular >> positionOf: element [

	| ratio rad |
	"Comes from p = 2 Pi r"
	ratio := (self hull distanceFromOrigin at: element)
	         / self hull totalDistance.
	rad := ratio * 2 * Float pi.
	^ rad cos * self radius @ (rad sin * self radius negated)
]

{ #category : 'building' }
QuickCircular >> updateShapePosition: a [

]
