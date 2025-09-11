Class {
	#name : 'PatrolBehavior',
	#superclass : 'Object',
	#instVars : [
		'waypoints',
		'currentIndex'
	],
	#category : 'DroneSystem-Behaviors',
	#package : 'DroneSystem-Behaviors'
}

{ #category : 'accessing' }
PatrolBehavior >> currentIndex [

	^ currentIndex
]

{ #category : 'accessing' }
PatrolBehavior >> currentIndex: anObject [

	currentIndex := anObject
]

{ #category : 'initialization' }
PatrolBehavior >> executeFor: aDrone atTime: aTime [
      | nextWaypoint |

	 waypoints isEmpty ifTrue: [ ^ self ].

    nextWaypoint := waypoints at: currentIndex.
    aDrone moveToLatitude: (nextWaypoint at: 1) longitude: (nextWaypoint at: 2) altitude: (nextWaypoint at: 3).
    currentIndex := (currentIndex \\ waypoints size) + 1.
    ^ self.

]

{ #category : 'initialization' }
PatrolBehavior >> initializeWithWaypoints: aCollection [
    waypoints := aCollection.
    currentIndex := 1.
    ^ self.

]

{ #category : 'accessing' }
PatrolBehavior >> waypoints [

	^ waypoints
]

{ #category : 'accessing' }
PatrolBehavior >> waypoints: anObject [

	waypoints := anObject
]
