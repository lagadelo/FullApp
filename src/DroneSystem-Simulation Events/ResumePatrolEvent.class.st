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

{ #category : 'as yet unclassified' }
ResumePatrolEvent >> duration [
    ^ 0.
]

{ #category : 'as yet unclassified' }
ResumePatrolEvent >> executeOn: simulator [
"Demande à la mission de redéfinir les objectifs"
    drone cluster currentMission ifNotNil: [:mission |
        mission planNextPatrolFor: drone at: self timestamp in: simulator
    ].
]
