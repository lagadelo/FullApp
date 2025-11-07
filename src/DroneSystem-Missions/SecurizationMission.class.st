Class {
	#name : 'SecurizationMission',
	#superclass : 'ZoneBasedMission',
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
SecurizationMission >> accept: aVisitor [

^aVisitor visitSecurizationMission: self 
]

{ #category : 'characterization' }
SecurizationMission >> isSecurizationMission [ 

^true
]

{ #category : 'as yet unclassified' }
SecurizationMission >> nextWayPointFor: drone [

^nil
]

{ #category : 'strategy' }
SecurizationMission >> responseStrategy [
    ^ HybridStrategy new.
]
