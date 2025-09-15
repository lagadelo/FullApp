Class {
	#name : 'SimulationVerifier',
	#superclass : 'Object',
	#instVars : [
		'simulation',
		'issues'
	],
	#category : 'DroneSystem-Verification-verification',
	#package : 'DroneSystem-Verification',
	#tag : 'verification'
}

{ #category : 'change reporting' }
SimulationVerifier >> eportIssues [
    ^ issues copy
]

{ #category : 'initialization' }
SimulationVerifier >> initializeWithSimulation: aSimulation [
    simulation := aSimulation.
    issues := OrderedCollection new.
    ^ self
]

{ #category : 'accessing' }
SimulationVerifier >> issues [

	^ issues
]

{ #category : 'accessing' }
SimulationVerifier >> issues: anObject [

	issues := anObject
]

{ #category : 'change reporting' }
SimulationVerifier >> resetIssues [
    issues := OrderedCollection new.
]

{ #category : 'accessing' }
SimulationVerifier >> simulation [

	^ simulation
]

{ #category : 'accessing' }
SimulationVerifier >> simulation: anObject [

	simulation := anObject
]

{ #category : 'initialization' }
SimulationVerifier >> verifyDrones [
    "Vérifie chaque drone"
    simulation allDrones do: [:d |
        (d energy < 0) ifTrue: [ issues add: 'Drone ', d uniqueId, ' has negative energy' ].
        (d latitude isNil or: [ d longitude isNil ]) ifTrue: [ issues add: 'Drone ', d uniqueId, ' has invalid coordinates' ].
        (d altitude < 0) ifTrue: [ issues add: 'Drone ', d uniqueId, ' has negative altitude' ].
    ].
]

{ #category : 'initialization' }
SimulationVerifier >> verifyFleets [
    "Vérifie cohérence des flottes"
    simulation allFleets do: [:fleet |
        fleet drones isEmpty ifTrue: [ issues add: 'Fleet ', fleet name, ' has no drones' ].
        (fleet coverage isNil or: [ fleet coverage isEmpty ]) ifTrue: [
            issues add: 'Fleet ', fleet name, ' has no computed coverage'
        ].
    ].
]

{ #category : 'initialization' }
SimulationVerifier >> verifyMissions [
    "Vérifie cohérence des missions de clusters"
    simulation allFleets do: [:fleet |
        fleet clusters do: [:cluster |
            cluster currentMission ifNil: [
                issues add: 'Cluster ', cluster clusterId asString, ' has no mission'
            ].
        ].
    ].
]

{ #category : 'initialization' }
SimulationVerifier >> verifyStep: stepNumber [
    "Vérifie les règles de cohérence à l’instant donné."
    self verifyDrones.
    self verifyFleets.
    self verifyMissions.
    issues isEmpty ifFalse: [
        Transcript show: 'Verification step ', stepNumber asString, ' issues: ', issues size asString; cr.
    ].
    ^ issues

]
