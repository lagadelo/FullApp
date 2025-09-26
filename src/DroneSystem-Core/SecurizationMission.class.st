Class {
	#name : 'SecurizationMission',
	#superclass : 'ZoneBasedMission',
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
