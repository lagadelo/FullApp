Class {
	#name : 'AbstractDrone',
	#superclass : 'Object',
	#instVars : [
		'uniqueId',
		'waypoint'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'path commands' }
AbstractDrone >> hasMoreWaypoints [
    self subclassResponsibility.

]

{ #category : 'path commands' }
AbstractDrone >> moveTo: aWaypoint [
    self subclassResponsibility.

]

{ #category : 'path commands' }
AbstractDrone >> nextWaypoint [
    self subclassResponsibility.


]

{ #category : 'path commands' }
AbstractDrone >> position [
    self subclassResponsibility.

]

{ #category : 'accessing' }
AbstractDrone >> waypoint [

	^ waypoint
]

{ #category : 'accessing' }
AbstractDrone >> waypoint: anObject [

	waypoint := anObject
]
