Class {
	#name : 'ClusterAlertEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'alertingDrone',
		'enemy',
		'enemyPosition',
		'cluster'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
ClusterAlertEvent >> affectedEntities [
    ^ Set with: cluster.
]

{ #category : 'accessing' }
ClusterAlertEvent >> alertingDrone [

	^ alertingDrone
]

{ #category : 'accessing' }
ClusterAlertEvent >> alertingDrone: anObject [

	alertingDrone := anObject
]

{ #category : 'accessing' }
ClusterAlertEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
ClusterAlertEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'accessing' }
ClusterAlertEvent >> enemy [

	^ enemy
]

{ #category : 'accessing' }
ClusterAlertEvent >> enemy: anObject [

	enemy := anObject
]

{ #category : 'accessing' }
ClusterAlertEvent >> enemyPosition [

	^ enemyPosition
]

{ #category : 'accessing' }
ClusterAlertEvent >> enemyPosition: anObject [

	enemyPosition := anObject
]

{ #category : 'executing' }
ClusterAlertEvent >> executeOn: aSimulator [


]
