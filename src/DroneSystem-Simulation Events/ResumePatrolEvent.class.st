Class {
	#name : 'ResumePatrolEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
ResumePatrolEvent class >> for: aDrone at: aTimestamp [
    ^ self new
        timestamp: aTimestamp;
        drone: aDrone;
        yourself.
]

{ #category : 'as yet unclassified' }
ResumePatrolEvent >> affectedEntities [
    ^ Set with: drone.
]

{ #category : 'accessing' }
ResumePatrolEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
ResumePatrolEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'as yet unclassified' }
ResumePatrolEvent >> duration [
    ^ 0.
]

{ #category : 'as yet unclassified' }
ResumePatrolEvent >> executeOn: simulator [
	"Demande à la mission de redéfinir les objectifs"

	| mission point |
	mission := drone cluster ifNil: [ ^ self ].
	mission := drone cluster missions assignedMissions first.
	 
	mission ifNotNil: [
			point := mission nextWayPointFor: drone.
			point ifNotNil: [
					simulator
						scheduleEvent:
						(MoveStepEvent drone: drone wayPoint: point speed: drone speed)
						after: (Set with: 100)
					"(MoveToWaypointEvent for: drone to: point at: self timestamp)" ] ]
]
