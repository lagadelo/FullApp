Class {
	#name : 'StrikeMission',
	#superclass : 'ClusterMission',
	#instVars : [
		'target'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
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
StrikeMission >> target [

	^ target
]

{ #category : 'accessing' }
StrikeMission >> target: anObject [

	target := anObject
]
