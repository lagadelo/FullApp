Class {
	#name : 'DroneCluster',
	#superclass : 'FleetElement',
	#instVars : [
		'drones',
		'coverage',
		'droneRoles'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'instance creation' }
DroneCluster class >> clusterId: id [

^self new    clusterId: id
]

{ #category : 'accessing' }
DroneCluster class >> example:n [

| tmp |
tmp := self new clusterId: #test; yourself. ((1 to: n) do:  [:i| tmp addDrone: Drone example]).
^tmp 

]

{ #category : 'instance creation' }
DroneCluster class >> with: drones [

|tmp|

tmp := self  clusterId: nil.
tmp  initializeWithDrones: drones.
 ^tmp
]

{ #category : 'visiting' }
DroneCluster >> accept: aVisitor [

^aVisitor visitDroneCluster: self 
]

{ #category : 'accessing' }
DroneCluster >> addDrone: aDrone [

	self drones add: aDrone
]

{ #category : 'initialization' }
DroneCluster >> allOperational [
    ^ drones select: [:d | d isDestroyed not].
]

{ #category : 'missions' }
DroneCluster >> assignMission: aMission [
    currentMission := aMission.
    aMission assignToCluster: self.
]

{ #category : 'initialization' }
DroneCluster >> clusterCenter [
    "Retourne le centre géométrique (moyenne des points de coverage)."
   | lats lons | 
(coverage isEmpty or: [ coverage size = 0 ]) ifTrue: [
        "Fallback : moyenne des drones actifs si pas de coverage"
        | act |
        act := (drones select: [:d | d isDestroyed not]) collect: [:d | { d latitude. d longitude } ].
        act isEmpty ifTrue: [ ^ 0@0 ].
        ^ Point x: ((act collect: [:p | p at: 2]) sum / (act size)) y: ((act collect: [:p | p at: 1]) sum / (act size))
    ].
    
    lats := coverage collect: [:p | p at: 1 ].
    lons := coverage collect: [:p | p at: 2 ].
    ^ Point x: ( (lons sum) / lons size ) y: ( (lats sum) / lats size ).
]

{ #category : 'accessing' }
DroneCluster >> coverage [

	^ coverage
]

{ #category : 'accessing' }
DroneCluster >> coverage: anObject [

	coverage := anObject
]

{ #category : 'copying' }
DroneCluster >> deepCopy [
    | copy mapping newDrones |
    copy := self class new.
    copy clusterId: clusterId .
    "Create fresh drone copies and keep mapping"
    mapping := Dictionary new.
    newDrones := OrderedCollection new.
    drones do: [:d |
        | cd |
        cd := d deepCopy.
        mapping at: d put: cd.
        newDrones add: cd.
    ].
    copy drones: newDrones "ifResponds: [] ifFalse: []".
    copy updateCapabilities.
    copy updateCoverage.
"Prevent endless loop - must refactor"
  "  copy currentMission: (currentMission ifNotNil: [ currentMission deepCopy ] ifNil: [ nil ])."
    ^ copy.
]

{ #category : 'initialization' }
DroneCluster >> describe [
    ^ String streamContents: [:s |
        s nextPutAll: 'Cluster ID: '; nextPutAll: clusterId asString; cr.
        s nextPutAll: 'Mission: '; nextPutAll: (currentMission ifNil: ['none'] ifNotNil: [ currentMission missionType asString ]); cr.
        s nextPutAll: 'Drones: '; nextPutAll: drones size asString; cr.
        s nextPutAll: 'Capabilities: '; nextPutAll: (capabilities ifNil: ['?'] ifNotNil: [ capabilities asString ]); cr.
        s nextPutAll: 'Coverage: '; nextPutAll: (coverage ifNil: ['?'] ifNotNil: [ coverage size asString , ' points' ]).
    ].

]

{ #category : 'initialization' }
DroneCluster >> destroy [
    drones := drones do: [:d | d destroy].
	 self removeDestroyedDrones 


]

{ #category : 'accessing' }
DroneCluster >> drones [

	drones ifNil:[drones := OrderedCollection new]. ^ drones
]

{ #category : 'accessing' }
DroneCluster >> drones: anObject [

	drones := anObject
]

{ #category : 'strategy' }
DroneCluster >> electionStrategy [

	self currentMission type = #surveillance ifTrue: [
		^ BestPerceptionStrategy new ].
	self currentMission type = #strike ifTrue: [
		^ ClosestToTargetStrategy new ].
	^ MaxFuelStrategy new
]

{ #category : 'updating status' }
DroneCluster >> expandedCoverageByFactor: aFactor [

	| c |
	c := self clusterCenter.
	coverage := self updateCoverage.
	^ coverage collect: [ :a | a - c * aFactor + c ]
]

{ #category : 'initialization' }
DroneCluster >> initializeWithDrones: droneList clusterId: anId [
    drones := droneList.
    id := anId.
  
"    self updateCapabilities.
    self updateCoverage."
    ^ self.

]

{ #category : 'initialization' }
DroneCluster >> initializeWithDrones: droneList clusterId: anId hostile: whoKnows name: aName [

self initializeWithDrones: droneList clusterId: anId.
self name: aName.
self hostile: whoKnows.

    ^ self.
 
]

{ #category : 'updating status' }
DroneCluster >> isCompromized [

^self isAllied and: [(self drones anySatisfy: [:a| a isHostile]) isNotNil]
]

{ #category : 'initialization' }
DroneCluster >> isOperational [
    ^ drones anySatisfy: [:d | d isDestroyed not].
]

{ #category : 'converting' }
DroneCluster >> polygon [

^Polygon vertices:(ConvexHullCalculator new convexHullGeoVerbose: self drones) "collect:[:a| a longitude@a latitude])"
]

{ #category : 'updating status' }
DroneCluster >> updateCapabilities [
    "Calcule et met à jour les capacités agrégées du cluster."
    self error.
capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [ d fuel ] ifTrue: [ 0 ]]).
    capabilities at: #perceptionRange put: (drones collect: [:d | d isDestroyed ifFalse: [ d perceptionRange ] ifTrue: [ 0 ]]) .
    capabilities at: #munitions put: (drones sum: [:d | d isDestroyed ifFalse: [ (d consumables at: #munitions) ] ifTrue: [ 0 ]]).
    ^ capabilities.
]

{ #category : 'updating status' }
DroneCluster >> updateCoverage [
    "Met à jour la couverture géographique du cluster à partir des drones actifs."

 

    "1. Extraire les positions des drones valides"
    "activePositions := (drones select: [:d | d isDestroyed not])
        collect: [:d |  d  geoPoint  ]."

    "2. Si aucun drone actif → pas de couverture"
   " activePositions" self "allOperational" drones  isEmpty ifTrue: [
        coverage := #().
        ^ coverage ].

    "3. Calculer l’enveloppe convexe (zone couverte)"
    coverage := ConvexHullCalculator new
        convexHullGeoVerbose: self "allOperational" drones.


"ConvexHullCalculator new
        convexHullVerbose: (self allOperational collect:[:d|Array with:  d longitude with: d latitude])."

    ^ coverage

]
