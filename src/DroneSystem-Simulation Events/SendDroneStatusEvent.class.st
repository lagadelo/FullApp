Class {
	#name : 'SendDroneStatusEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'fromDrone',
		'cluster',
		'statusData'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'as yet unclassified' }
SendDroneStatusEvent >> affectedEntities [
    ^ Set withAll: { fromDrone. cluster }.
]

{ #category : 'accessing' }
SendDroneStatusEvent >> cluster [

	^ cluster
]

{ #category : 'accessing' }
SendDroneStatusEvent >> cluster: anObject [

	cluster := anObject
]

{ #category : 'as yet unclassified' }
SendDroneStatusEvent >> executeOn: aSimulator [
    aSimulator handleSendDroneStatus: self.
]

{ #category : 'accessing' }
SendDroneStatusEvent >> fromDrone [

	^ fromDrone
]

{ #category : 'accessing' }
SendDroneStatusEvent >> fromDrone: anObject [

	fromDrone := anObject
]

{ #category : 'accessing' }
SendDroneStatusEvent >> statusData [

	^ statusData
]

{ #category : 'accessing' }
SendDroneStatusEvent >> statusData: anObject [

	statusData := anObject
]
