Class {
	#name : 'DetectionEvent',
	#superclass : 'ScheduledEvent',
	#instVars : [
		'intruder',
		'drone'
	],
	#category : 'DroneSystem-Simulation Events',
	#package : 'DroneSystem-Simulation Events'
}

{ #category : 'accessing' }
DetectionEvent class >> fromDrone: aDrone at: aTimestamp intruderAt: aPoint [
    ^ self new
        timestamp: aTimestamp;
        drone: aDrone;
        intruderPosition: aPoint;
        yourself.
]

{ #category : 'as yet unclassified' }
DetectionEvent >> affectedEntities [
    ^ Set with: self drone.
]

{ #category : 'accessing' }
DetectionEvent >> drone [

	^ drone
]

{ #category : 'accessing' }
DetectionEvent >> drone: anObject [

	drone := anObject
]

{ #category : 'executing' }
DetectionEvent >> executeOn: simulator [
    | cluster responseEvents |
    
    Transcript
        show: '⚠️ Intrusion detected by Drone ', self drone id printString,
              ' at position ', self intruderPosition printString;
        cr.
    
    cluster := self drone cluster.
    
    responseEvents := cluster currentMission generateOrdersFor: cluster threatAt: self intruderPosition.
    
    responseEvents do: [:e |
        simulator scheduleEvent: e after: (Set with: self)
    ].
]

{ #category : 'accessing' }
DetectionEvent >> intruder [

	^ intruder
]

{ #category : 'accessing' }
DetectionEvent >> intruder: anObject [

	intruder := anObject
]

{ #category : 'accessing' }
DetectionEvent >> intruderPosition [

^self intruder position
]
