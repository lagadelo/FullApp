Class {
	#name : 'StrikeMission',
	#superclass : 'ClusterMission',
	#instVars : [
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

{ #category : 'strategy' }
StrikeMission >> responseStrategy [
    ^ AllInterceptStrategy new.
]

{ #category : 'accessing' }
StrikeMission >> target [

	^ target
]

{ #category : 'accessing' }
StrikeMission >> target: anObject [

	target := anObject
]
