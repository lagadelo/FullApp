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
		'hostile',
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

{ #category : 'updating status' }
DroneCluster >> assignRole: aRole toDrone: aDrone [
    droneRoles at: aDrone put: aRole.
]

{ #category : 'initialization' }
DroneCluster >> beAllied [
hostile := false
]

{ #category : 'initialization' }
DroneCluster >> beHostile [ 
hostile := true
]

{ #category : 'detection ' }
DroneCluster >> canDetectCluster: aCluster [

aCluster drones detect: [:a| self canDetectDrone: a] ifNone:[^false].
^true.
]

{ #category : 'detection ' }
DroneCluster >> canDetectDrone: aDrone [

^( self howManyTimesDetectDrone: aDrone) >0
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

{ #category : 'initialization' }
DroneCluster >> destroy [
    drones := drones do: [:d | d destroy].
	 self removeDestroyedDrones 


]

{ #category : 'detection ' }
DroneCluster >> detectedDronesFromCluster:aCluster [

^aCluster drones select:[:aDrone| self canDetectDrone:aDrone]
]

{ #category : 'updating status' }
DroneCluster >> droneRoles [

droneRoles ifNil:[droneRoles := Dictionary new].
^droneRoles
]

{ #category : 'accessing' }
DroneCluster >> drones [

	drones ifNil:[drones := OrderedCollection new]. ^ drones
]

{ #category : 'accessing' }
DroneCluster >> drones: anObject [

	drones := anObject
]

{ #category : 'updating status' }
DroneCluster >> dronesWithRole: aRole [
   ^ self drones  select: [:d | (droneRoles at: d) = aRole]
]

{ #category : 'strategy' }
DroneCluster >> electionStrategy [
    self currentMission type = #surveillance ifTrue: [ ^ BestPerceptionStrategy new ].
      self currentMission type = #strike ifTrue: [ ^ ClosestToTargetStrategy new ].
    ^ MaxFuelStrategy new.
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

{ #category : 'detection ' }
DroneCluster >> howManyTimesDetectCluster: aCluster [

^aCluster drones inject:0 into:[:sum :aDrone|  sum + self howManyTimesDetectDrone: aDrone]
]

{ #category : 'detection ' }
DroneCluster >> howManyTimesDetectDrone: aDrone [

^self drones count: [ :a| (a position distanceTo: aDrone position  )<= a perceptionRange] 
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

{ #category : 'accessing' }
DroneCluster >> isAllied [
	^ hostile = false
]

{ #category : 'accessing' }
DroneCluster >> isHostile [

	^ hostile = true
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

{ #category : 'converting' }
DroneCluster >> polygon [

^Polygon vertices:(ConvexHullCalculator new convexHullGeoVerbose: self drones) "collect:[:a| a longitude@a latitude])"
]

{ #category : 'detection ' }
DroneCluster >> ratioOfdetectedDronesFromCluster:aCluster [

^(self detectedDronesFromCluster:aCluster) size / aCluster drones size 
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

{ #category : 'updating status' }
DroneCluster >> updateCoverageGeo [
    "Met à jour la couverture géographique du cluster à partir des drones actifs."

    | activePositions |

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
