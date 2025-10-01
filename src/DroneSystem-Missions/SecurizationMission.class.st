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

{ #category : 'strategy' }
SecurizationMission >> responseStrategy [
    ^ HybridStrategy new.
]
