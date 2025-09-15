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
DroneFleet >> addHostileCluster: aCluster [
    hostileClusters add: aCluster.
    log add: 'Cluster hostile ', aCluster clusterId asString, ' détecté.'.
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

{ #category : 'initialization' }
DroneFleet >> removeCluster: aCluster [
    clusters remove: aCluster ifAbsent: [].
    log add: 'Cluster ', aCluster clusterId asString, ' retiré de la flotte.'.
]
