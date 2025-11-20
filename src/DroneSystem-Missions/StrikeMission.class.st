Class {
	#name : 'StrikeMission',
	#superclass : 'ClusterMission',
	#instVars : [
		'targets',
		'target'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
StrikeMission >> accept: aVisitor [

^aVisitor visitStrikeMission: self 
]

{ #category : 'assignments' }
StrikeMission >> assignBehaviors [ 
   
     
    self assignedCluster drones withIndexDo: [:drone :i |
     "   drone setBehavior: AttackBehavior new initializeWithWeapon: w qty: q prob: p impact: i targetSelector: sel"
    ].
    ^ self.
]

{ #category : 'assignments' }
StrikeMission >> assignBehaviors: someDrones [
   
     
    someDrones  withIndexDo: [:drone :i |
     "   drone setBehavior: AttackBehavior new initializeWithWeapon: w qty: q prob: p impact: i targetSelector: sel"
    ].
    ^ self.
]

{ #category : 'resolution' }
StrikeMission >> battleZone [

^OrderedCollection with: self target
]

{ #category : 'characterization' }
StrikeMission >> isStrikemission [

^true
]

{ #category : 'accessing' }
StrikeMission >> nextWayPointFor: aModel [

	target = targets last ifTrue: [ ^ nil ].
	^ target := targets at: (targets indexOf: target) + 1
]

{ #category : 'accessing' }
StrikeMission >> points: aValue [

self targets: aValue
]

{ #category : 'strategy' }
StrikeMission >> responseStrategy [
    ^ AllInterceptStrategy new.
]

{ #category : 'accessing' }
StrikeMission >> target [

	^ target ifNil:[ self target: targets first]
	
]

{ #category : 'accessing' }
StrikeMission >> target: anObject [

	target := anObject
]

{ #category : 'accessing' }
StrikeMission >> targets [

	^ targets
]

{ #category : 'accessing' }
StrikeMission >> targets: anObject [

	targets := anObject
]
