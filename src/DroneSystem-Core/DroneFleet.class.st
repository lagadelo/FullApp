Class {
	#name : 'DroneFleet',
	#superclass : 'Object',
	#instVars : [
		'clusters',
		'missions',
		'hostileClusters',
		'log',
		'fleetId',
		'hostile',
		'name'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'as yet unclassified' }
DroneFleet class >> fleetWithClusters: clusters id: anId hostile: aBool name: aString [
    ^ (self new) initializeWithClusters: clusters id: anId hostile: aBool name: aString.
]

{ #category : 'initialization' }
DroneFleet >> addCluster: aCluster [
    clusters add: aCluster.
    log add: 'New cluster ', aCluster clusterId asString, ' accepted.'.
]

{ #category : 'initialization' }
DroneFleet >> addHostileCluster: aCluster [
    self addCluster: aCluster.
	 hostileClusters add: aCluster.
    log add: 'Cluster ', aCluster clusterId asString, ' tagged as hostile.'.
]

{ #category : 'accessing' }
DroneFleet >> allAlliedDrones [ 
^self alliedClusters collectMany:[:c| c drones]
]

{ #category : 'accessing' }
DroneFleet >> allDrones [ 
^(self clusters reject:[:c| c isNil] )collectMany:[:c| c drones]
]

{ #category : 'accessing' }
DroneFleet >> allHostileDrones [ 
^self hostileClusters collectMany:[:c| c drones]
]

{ #category : 'as yet unclassified' }
DroneFleet >> alliedCenter [

^(DroneCluster with: self allAlliedDrones) clusterCenter 
]

{ #category : 'accessing' }
DroneFleet >> alliedClusters [

^self clusters reject:[:c|  self hostileClusters includes:c]
]

{ #category : 'execution' }
DroneFleet >> assignMission: aMission toCluster: aCluster [
    aCluster currentMission: aMission.
    aMission assignToCluster: aCluster.
    missions add: aMission.
    log add: 'Mission ', aMission missionType asString, 
        ' assignée au cluster ', aCluster clusterId asString.
]

{ #category : 'initialization' }
DroneFleet >> clearLog [
    log := OrderedCollection new
]

{ #category : 'accessing' }
DroneFleet >> clusters [

	^ clusters
]

{ #category : 'accessing' }
DroneFleet >> clusters: anObject [

	clusters := anObject
]

{ #category : 'initialization' }
DroneFleet >> deepCopy [ 

| f  clustersMapping|
f := self class new. 
clustersMapping := Dictionary new.
self clusters do:[:c| clustersMapping at:c put: c deepCopy].

self alliedClusters do:[:c| f addCluster:  (clustersMapping at:c) ].
self hostileClusters do:[:c| f addHostileCluster: (clustersMapping at:c)].
f name:  self name.
f missions: (self missions collect:[:m| |mc| mc := m copy. mc assignToCluster: (clustersMapping at: m cluster)]  ).

 ^f
]

{ #category : 'evaluation' }
DroneFleet >> evaluateCoverage [
    "Retourne la couverture combinée de tous les clusters"
    ^ clusters collectMany: [ :c | c coverage ].
]

{ #category : 'evaluation' }
DroneFleet >> evaluateDefense [
    "Évalue la résilience face aux attaques hostiles"
    ^ clusters collect: [ :c | { c clusterId . c isOperational } ].
]

{ #category : 'evaluation' }
DroneFleet >> evaluateStrategy: aStrategyBlock [
    "Applique une heuristique d’évaluation à la flotte"
    ^ aStrategyBlock value: self
]

{ #category : 'execution' }
DroneFleet >> executeOn: aSimulation [
    self subclassResponsibility.


]

{ #category : 'accessing' }
DroneFleet >> flattenCluster [ 
^DroneCluster with: (self clusters collectMany:[:c| c drones  ])
]

{ #category : 'as yet unclassified' }
DroneFleet >> fleetCenter [

^(DroneCluster with: self allDrones) clusterCenter 
]

{ #category : 'accessing' }
DroneFleet >> fleetId [

	^ fleetId
]

{ #category : 'accessing' }
DroneFleet >> fleetId: anObject [

	fleetId := anObject
]

{ #category : 'accessing' }
DroneFleet >> hostile [

	^ hostile
]

{ #category : 'accessing' }
DroneFleet >> hostile: anObject [

	hostile := anObject
]

{ #category : 'as yet unclassified' }
DroneFleet >> hostileCenter [

^(DroneCluster with: self allHostileDrones) clusterCenter 
]

{ #category : 'accessing' }
DroneFleet >> hostileClusters [

	^ hostileClusters
]

{ #category : 'accessing' }
DroneFleet >> hostileClusters: anObject [

	hostileClusters := anObject
]

{ #category : 'initialization' }
DroneFleet >> initialize [
    clusters := OrderedCollection new.
    missions := OrderedCollection new.
    hostileClusters := OrderedCollection new.
    log := OrderedCollection new.
]

{ #category : 'initialization' }
DroneFleet >> initializeWithClusters: clusterCollection id: anId hostile: aBool name: aString [
    clusters := (clusterCollection copy asOrderedCollection).
    fleetId := anId.
    hostile := aBool.
    name := aString.
    log := OrderedCollection new.
    ^ self.
]

{ #category : 'accessing' }
DroneFleet >> log [

	^ log
]

{ #category : 'accessing' }
DroneFleet >> log: anObject [

	log := anObject
]

{ #category : 'accessing' }
DroneFleet >> missions [

	^ missions
]

{ #category : 'accessing' }
DroneFleet >> missions: anObject [

	missions := anObject
]

{ #category : 'accessing' }
DroneFleet >> name [

	^ name
]

{ #category : 'accessing' }
DroneFleet >> name: anObject [

	name := anObject
]

{ #category : 'initialization' }
DroneFleet >> removeCluster: aCluster [
    clusters remove: aCluster ifAbsent: [].
    log add: 'Cluster ', aCluster clusterId asString, ' retiré de la flotte.'.
]
