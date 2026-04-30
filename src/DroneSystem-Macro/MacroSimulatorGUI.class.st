Class {
	#name : 'MacroSimulatorGUI',
	#superclass : 'Object',
	#instVars : [
		'map',
		'macroSimulatorStep'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorGUI class >> openOn: aMacroSimulatorStep [

	self new
		macroSimulatorStep: aMacroSimulatorStep;
		initializeMap;
		yourself
]

{ #category : 'visiting' }
MacroSimulatorGUI >> accept: aVisitor [

	^ aVisitor visitMacroSimulatorGUI: self
]

{ #category : 'initialization' }
MacroSimulatorGUI >> initializeMap [ 


map := QuickGeoportailMap new.

]

{ #category : 'initialization' }
MacroSimulatorGUI >> initializeWaypoints [

	| wp latitudes mapForm longitudes |
	wp := self macroSimulatorStep simulator wayPoints.

	latitudes := (wp collect: [ :a | a y ]) asSortedCollection.

	longitudes := (wp collect: [ :a | a x ]) asSortedCollection.


	mapForm := self new
		           minLat: latitudes first;
		           maxLat: latitudes last;
		           minLon: longitudes first;
		           maxLon: longitudes last;
		           yourself.


	mapForm openWithScroller.
	wp keysAndValuesDo: [ :k :v |
		mapForm addModel: k withID: ('WP_' , v printString) asSymbol ]
]

{ #category : 'accessing' }
MacroSimulatorGUI >> macroSimulatorStep [

	^ macroSimulatorStep
]

{ #category : 'accessing' }
MacroSimulatorGUI >> macroSimulatorStep: anObject [

	macroSimulatorStep := anObject
]

{ #category : 'accessing' }
MacroSimulatorGUI >> map [

	^ map
]

{ #category : 'accessing' }
MacroSimulatorGUI >> map: anObject [

	map := anObject
]
