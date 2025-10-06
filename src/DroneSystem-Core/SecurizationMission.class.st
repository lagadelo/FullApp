Class {
	#name : 'SecurizationMission',
	#superclass : 'AnObsoleteZoneBasedMission',
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'visiting' }
SecurizationMission >> accept: aVisitor [

^aVisitor visitSecurizationMission: self 
]

{ #category : 'characterization' }
SecurizationMission >> isSecurizationMission [ 

^true
]
