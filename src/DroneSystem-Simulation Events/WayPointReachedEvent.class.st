Class {
	#name : 'WayPointReachedEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'wayPoint'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
WayPointReachedEvent >> affectedEntities [
    ^ Set with: drone.
]

{ #category : 'accessing' }
WayPointReachedEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
WayPointReachedEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'execution' }
WayPointReachedEvent >> executeOn: aSimulator [
     aSimulator scheduleEvent: (
        ResumePatrolEvent for: drone at: self timestamp  
    ) after: (Set with: self).
]

{ #category : 'accessing' }
WayPointReachedEvent >> wayPoint [

	^ wayPoint
]

{ #category : 'accessing' }
WayPointReachedEvent >> wayPoint: anObject [

	wayPoint := anObject
]
