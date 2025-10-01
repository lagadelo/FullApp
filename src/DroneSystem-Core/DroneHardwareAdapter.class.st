"
This is used for digital twins.
Adapter supports send orders to and collecting data from a real device
"
Class {
	#name : 'DroneHardwareAdapter',
	#superclass : 'Object',
	#instVars : [
		'connection',
		'lastKnownPosition',
		'telemetryLog'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'as yet unclassified' }
DroneHardwareAdapter >> currentGPSPosition [
    ^ lastKnownPosition.

]

{ #category : 'as yet unclassified' }
DroneHardwareAdapter >> initialize [
    lastKnownPosition := Waypoint new x: 0; y: 0.
    telemetryLog := OrderedCollection new.

]

{ #category : 'as yet unclassified' }
DroneHardwareAdapter >> sendMoveCommandTo: aWaypoint [
    "Ici, on simule l'envoi. Dans un vrai système : ROS, UDP, etc."
    telemetryLog add: ('Command sent to: ', aWaypoint printString).
    lastKnownPosition := aWaypoint. "On simule le mouvement instantané."


]

{ #category : 'as yet unclassified' }
DroneHardwareAdapter >> updateFromTelemetry: data [
    "Met à jour la position, fuel, etc."
    lastKnownPosition := data position.



]
