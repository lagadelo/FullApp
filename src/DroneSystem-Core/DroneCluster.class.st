Class {
	#name : 'DroneCluster',
	#superclass : 'Object',
	#instVars : [
		'drones',
		'clusterId',
		'coverage',
		'capabilities',
		'currentMission',
		'name',
		'hostile'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'accessing' }
DroneCluster class >> example:n [

^self with: ((1 to: n) collect:[:i| Drone example])

]

{ #category : 'instance creation' }
DroneCluster class >> with: drones [

^self new  initializeWithDrones: drones  clusterId: nil;yourself
]

{ #category : 'missions' }
DroneCluster >> assignMission: aMission [
    currentMission := aMission.
    aMission assignToCluster: self.
]

{ #category : 'accessing' }
DroneCluster >> capabilities [

	^ capabilities
]

{ #category : 'accessing' }
DroneCluster >> capabilities: anObject [

	capabilities := anObject
]

{ #category : 'missions' }
DroneCluster >> clearMission [
    currentMission := nil.
    drones do: [:d | d clearBehavior ].

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
DroneCluster >> clusterId [

	^ clusterId
]

{ #category : 'accessing' }
DroneCluster >> clusterId: anObject [

	clusterId := anObject
]

{ #category : 'accessing' }
DroneCluster >> coverage [

	^ coverage
]

{ #category : 'accessing' }
DroneCluster >> coverage: anObject [

	coverage := anObject
]

{ #category : 'accessing' }
DroneCluster >> currentMission [

	^ currentMission
]

{ #category : 'accessing' }
DroneCluster >> currentMission: anObject [

	currentMission := anObject
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

{ #category : 'accessing' }
DroneCluster >> drones [

	^ drones
]

{ #category : 'accessing' }
DroneCluster >> drones: anObject [

	drones := anObject
]

{ #category : 'updating status' }
DroneCluster >> expandedCoverageByFactor: aFactor [
  | c |
c :=  self clusterCenter.
coverage := self updateCoverage.
^ coverage  collect:[:a| (a - c) * aFactor + c]

]

{ #category : 'accessing' }
DroneCluster >> hostile [

	^ hostile
]

{ #category : 'accessing' }
DroneCluster >> hostile: anObject [

	hostile := anObject
]

{ #category : 'initialization' }
DroneCluster >> initializeWithDrones: droneList clusterId: anId [
    drones := droneList.
    clusterId := anId.
    currentMission := nil.
    self updateCapabilities.
    self updateCoverage.
    ^ self.

]

{ #category : 'initialization' }
DroneCluster >> initializeWithDrones: droneList clusterId: anId hostile: whoKnows name: aName [

self initializeWithDrones: droneList clusterId: anId.
self name: aName.
self hostile: whoKnows.

    ^ self.
 
]

{ #category : 'initialization' }
DroneCluster >> isOperational [
    ^ drones anySatisfy: [:d | d isDestroyed not].
]

{ #category : 'accessing' }
DroneCluster >> name [

	^ name
]

{ #category : 'accessing' }
DroneCluster >> name: anObject [

	name := anObject
]

{ #category : 'initialization' }
DroneCluster >> removeDestroyedDrones [
    drones := drones reject: [:d | d isDestroyed ].
    self updateCapabilities.
    self updateCoverage.
    ^ self.


]

{ #category : 'updating status' }
DroneCluster >> updateCapabilities [
    "Calcule et met à jour les capacités agrégées du cluster."
    capabilities := Dictionary new.
    capabilities at: #fuel put: (drones sum: [:d | d isDestroyed ifFalse: [ d fuel ] ifTrue: [ 0 ]]).
    capabilities at: #perceptionRange put: (drones collect: [:d | d isDestroyed ifFalse: [ d perceptionRange ] ifTrue: [ 0 ]]) .
    capabilities at: #munitions put: (drones sum: [:d | d isDestroyed ifFalse: [ (d consumables at: #munitions) ] ifTrue: [ 0 ]]).
    ^ capabilities.
]

{ #category : 'updating status' }
DroneCluster >> updateCoverage [
    "Met à jour la couverture géographique du cluster à partir des drones actifs."

    | activePositions |

    "1. Extraire les positions des drones valides"
    activePositions := (drones select: [:d | d isDestroyed not])
        collect: [:d | { d    longitude . d latitude } ].

    "2. Si aucun drone actif → pas de couverture"
    activePositions isEmpty ifTrue: [
        coverage := #().
        ^ coverage ].

    "3. Calculer l’enveloppe convexe (zone couverte)"
    coverage := ConvexHullCalculator new
        convexHullVerbose: activePositions.

    ^ coverage

]
