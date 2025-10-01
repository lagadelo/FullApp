Class {
	#name : 'CollisionCheckEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'comparing' }
CollisionCheckEvent >> > execute [
    simulationState detectAndHandleCollisions.
    simulationState scheduler scheduleEvent: (
        CollisionCheckEvent new
            timestamp: simulationState currentTime + 1;
            yourself).

]

{ #category : 'as yet unclassified' }
CollisionCheckEvent >> affectedEntities [
    ^ (Set with: cluster)
]

{ #category : 'accessing' }
CollisionCheckEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
CollisionCheckEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'comparing' }
CollisionCheckEvent >> execute [
    simulationState detectAndHandleCollisions.
    simulationState scheduler scheduleEvent: (
        CollisionCheckEvent new
            timestamp: simulationState currentTime + 1;
            yourself).

]

{ #category : 'execution' }
CollisionCheckEvent >> executeOn: aSimulator [
    aSimulator handleMissionChanged: self.
]
