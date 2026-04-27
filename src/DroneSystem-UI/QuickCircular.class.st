Class {
	#name : 'QuickCircular',
	#superclass : 'QuickSimulationGround',
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

{ #category : 'getter' }
QuickCircular >> buildBackgroundOld [

	| form |
	form := Form extent: 500 @ 500 depth: 32.
	form fillColor: Color white.
	self background: "(RSBitmap new form: form)."form.
]

{ #category : 'building' }
QuickCircular >> buildFrom: tmp [
	"We represent the model as a ring of circles"

	| radius distances totalDistance hullShapes |
	self openWithScroller.
	radius := 200.
	distances := OrderedCollection with: 0.
	"First we need to compute distance from start"
	2 to: tmp hull size do: [ :i |
			distances add: distances last
				+ ((tmp hull at: i) haversineMetersTo: (tmp hull at: i - 1)) ].
	"Then total distance as this is mandatory to compute ratios"
	totalDistance := distances last
	                 + (tmp hull last haversineMetersTo: tmp hull first).

	"We build the circles, one per point"
	hullShapes := RSCircle models: tmp hull.
	hullShapes color: Color red.
	hullShapes size: 20.
	hullShapes keysAndValuesDo: [ :i :v |
			| ratio rad |
			"Comes from p = 2 Pi r"
			ratio := (distances at: i)   / totalDistance.
			rad := ratio * 2 * Float pi.
			v position: rad cos * radius @ (rad sin * radius negated).
			" Then we conform to our API"
			v model: (Array with: v model with: rad with: (distances at:i)).
			self addShape: v withModel: v model. v   @ RSPopup new. ]
]

{ #category : 'building' }
QuickCircular >> updateShapePosition: a [

]
