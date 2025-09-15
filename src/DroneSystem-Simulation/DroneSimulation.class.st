Class {
	#name : 'DroneSimulation',
	#superclass : 'Object',
	#instVars : [
		'state',
		'fleets'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'initialization' }
DroneSimulation >> addAllies: n [
    | fleet |
    fleet := DroneFleet new initializeWith: n hostile: false name: 'Allies'.
    fleets add: fleet.
    state addFleet: fleet.
]

{ #category : 'initialization' }
DroneSimulation >> addHostiles: n [
    | fleet |
    fleet := DroneFleet new initializeWith: n hostile: true name: 'Hostiles'.
    fleets add: fleet.
    state addFleet: fleet.
]

{ #category : 'initialization' }
DroneSimulation >> assignDefaultMissions [
    fleets do: [:f | f assignDefaultMission ].

]

{ #category : 'accessing' }
DroneSimulation >> fleets [

	^ fleets
]

{ #category : 'accessing' }
DroneSimulation >> fleets: anObject [

	fleets := anObject
]

{ #category : 'initialization' }
DroneSimulation >> initialize [
    state := SimulationState new.
    fleets := OrderedCollection new.

]

{ #category : 'accessing' }
DroneSimulation >> state [

	^ state
]

{ #category : 'accessing' }
DroneSimulation >> state: anObject [

	state := anObject
]

{ #category : 'initialization' }
DroneSimulation >> step [
    ^ state step.

]

{ #category : 'initialization' }
DroneSimulation >> stepAt: t [
    ^ state stepAt: t.
]
