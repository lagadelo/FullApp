Class {
	#name : 'DetectionByDroneEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'drone',
		'position',
		'enemyDrone'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
DetectionByDroneEvent >> affectedEntities [
    ^ Set withAll: { #detectingDrone .#enemyDrone }.
]

{ #category : 'accessing' }
DetectionByDroneEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
DetectionByDroneEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'accessing' }
DetectionByDroneEvent >> enemyDrone [

	^ enemyDrone
]

{ #category : 'accessing' }
DetectionByDroneEvent >> enemyDrone: anObject [

	enemyDrone := anObject
]

{ #category : 'as yet unclassified' }
DetectionByDroneEvent >> executeOn: simulator [
    simulator handleEnemyDetection: self.
]

{ #category : 'accessing' }
DetectionByDroneEvent >> position [

	^ position
]

{ #category : 'accessing' }
DetectionByDroneEvent >> position: anObject [

	position := anObject
]
