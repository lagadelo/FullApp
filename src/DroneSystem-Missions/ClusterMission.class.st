Class {
	#name : 'ClusterMission',
	#superclass : 'Mission',
	#classInstVars : [
		'missionType',
		'zoneParameters',
		'assignedCluster',
		'status'
	],
	#category : 'DroneSystem-Missions',
	#package : 'DroneSystem-Missions'
}

{ #category : 'visiting' }
ClusterMission class >> accept: aVisitor [

^aVisitor visitClusterMission: self 
]

{ #category : 'examples' }
ClusterMission class >> exampleSecurisation [
| cluster |
"Mission mixte : 30% surveillance, 70% attaque"
self mixedOn: {
        #(48.85 2.35 200).
        #(48.86 2.34 200).
        #(48.87 2.33 200) }
    target: #(48.90 2.31 50)
    ratio: 0.3
    forCluster: cluster.
]

{ #category : 'examples' }
ClusterMission class >> exampleStrike [
| cluster |
self strikeOn: #(48.90 2.31 50) forCluster: cluster.
]

{ #category : 'examples' }
ClusterMission class >> exampleSurveillance [
| cluster |
 "Mission mixte : moitié surveillance, moitié attaque"
self mixedOn: { #(48.85 2.35 200) . #(48.86 2.34 200) }
    target: #(48.90 2.31 50)
    forCluster: cluster.
]

{ #category : 'as yet unclassified' }
ClusterMission class >> mixedOn: polygon target: target forCluster: aCluster [
    "Crée une mission mixte surveillance + frappe."
    ^ (self new
        initializeWithType: #mixed
        zoneParameters: (Dictionary newFrom: { #polygon -> polygon . #target -> target }))
        assignToCluster: aCluster.
]

{ #category : 'examples' }
ClusterMission class >> mixedOn: polygon target: target ratio: ratio forCluster: aCluster [
    "Crée une mission mixte avec une proportion configurable (ratio entre 0 et 1)."
    ^ (self new
        initializeWithType: #mixed
        zoneParameters: (Dictionary newFrom: {
            #polygon -> polygon .
            #target -> target .
            #ratio -> ratio }))
        assignToCluster: aCluster.
]

{ #category : 'acccessing' }
ClusterMission class >> pointsExtraction [


"itemize the fields containing meaning points"
^#(target polygon)
]

{ #category : 'as yet unclassified' }
ClusterMission class >> securisationOn: polygon forCluster: aCluster [
    "Crée une mission de sécurisation statique sur un polygone et l’assigne immédiatement au cluster."
    ^ (self new
        initializeWithType: #securisation
        zoneParameters: (Dictionary newFrom: { #polygon -> polygon }))
        assignToCluster: aCluster.
]

{ #category : 'examples' }
ClusterMission class >> strikeOn: target forCluster: aCluster [
    "Crée une mission de frappe contre une cible unique (lat lon alt)."
    ^ (self new
        initializeWithType: #strike
        zoneParameters: (Dictionary newFrom: { #target -> target }))
        assignToCluster: aCluster.
]

{ #category : 'as yet unclassified' }
ClusterMission class >> surveillanceOn: polygon forCluster: aCluster [
    "Crée une mission de surveillance sur un polygone et l’assigne immédiatement au cluster."
    ^ (self new
        initializeWithType: #surveillance
        zoneParameters: (Dictionary newFrom: { #polygon -> polygon }))
        assignToCluster: aCluster.

]

{ #category : 'visiting' }
ClusterMission >> accept: aVisitor [

^aVisitor visitSurveillanceMission: self 
]

{ #category : 'private - utility' }
ClusterMission >> assignBehaviors [

^self assignBehaviors:  self assignedCluster drones 
]

{ #category : 'as yet unclassified' }
ClusterMission >> assignMixedBehaviorsTo: aCluster [
    | polygon target ratio total nSurveillance dronesSurveillance dronesStrike segments |
    polygon := zoneParameters at: #polygon ifAbsent: [ #() ].
    target := zoneParameters at: #target ifAbsent: [ nil ].
    ratio := zoneParameters at: #ratio ifAbsent: [ 0.5 ].
    total := aCluster drones size.
    nSurveillance := (total * ratio) rounded.
    nSurveillance := (nSurveillance min: total) max: 0.

    dronesSurveillance := aCluster drones first: nSurveillance.
    dronesStrike := aCluster drones allButFirst: nSurveillance.

    "Assigner la surveillance"
    segments := self computeSurveillanceWaypointsFor: aCluster.
    dronesSurveillance withIndexDo: [:drone :i |
        drone setBehavior: (PatrolBehavior new initializeWithWaypoints: (segments at: i))
    ].

    "Assigner l’attaque"
    target ifNotNil: [
        dronesStrike do: [:drone |
            drone setBehavior: (
                GoToHelpBehavior new
                    initializeWithLatitude: (target at: 1)
                    longitude: (target at: 2)
                    altitude: (target at: 3)
            )
        ].
    ].
]

{ #category : 'as yet unclassified' }
ClusterMission >> assignSecuringBehaviorsTo: aCluster [
    | positions |
    positions := self computeSecuringPositionsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (StaticPositionBehavior new initializeWithLatitude: ((positions at: i) at: 1) longitude: ((positions at: i) at: 2) altitude: ((positions at: i) at: 3)).
    ].
    ^ self.

]

{ #category : 'as yet unclassified' }
ClusterMission >> assignStrikeBehaviorsTo: aCluster [
    | target |
    target := zoneParameters at: #target.
    aCluster drones do: [:drone |
        drone setBehavior: (
            GoToHelpBehavior new
                initializeWithLatitude: (target at: 1)
                longitude: (target at: 2)
                altitude: (target at: 3)
        )
    ].
]

{ #category : 'as yet unclassified' }
ClusterMission >> assignSurveillanceBehaviorsTo: aCluster [
    | segments |
    segments := self computeSurveillanceWaypointsFor: aCluster.
    aCluster drones withIndexDo: [:drone :i |
        drone setBehavior: (PatrolBehavior new initializeWithWaypoints: (segments at: i)).
    ].
    ^ self.

]

{ #category : 'initialization' }
ClusterMission >> assignToCluster: aCluster [

	self assignedCluster: aCluster.
	self assignedCluster missions assignMission: self.

	status := #active.
	^ self
]

{ #category : 'copying' }
ClusterMission >> copy [ 
| copy |
copy := self new copy.
copy missionType: self missionType.
copy zoneParameters: self zoneParameters.
 
copy status: self status.
^copy 
]

{ #category : 'strategy' }
ClusterMission >> generateOrdersFor: aCluster threatAt: aPoint timestamp: aTimestamp [
    ^ self responseStrategy
        generateResponseEventsFor: self
        threatAt: aPoint
        timestamp: aTimestamp
]

{ #category : 'private - utility' }
ClusterMission >> generateWaypointsForDrones: nDrones existingWaypoints: waypoints [ 
    | nWaypoints segments neededWaypoints result newPoint fraction   |

    nWaypoints := waypoints size.

    "Si on a déjà assez de waypoints, on retourne la liste telle quelle"
    nWaypoints >= nDrones ifTrue: [ ^ waypoints copy ].

    result := OrderedCollection new.
    
    "Nombre de waypoints supplémentaires à générer"
    neededWaypoints := nDrones - nWaypoints.

    "Ajouter d’abord les waypoints existants"
    result addAll: waypoints.

    "Interpolation entre les points existants"
    segments := (1 to: nWaypoints) collect: [:i |
        | start end |
        start := waypoints at: i.
        end := (i = nWaypoints) ifTrue: [ waypoints first ] ifFalse: [ waypoints at: i + 1 ].
        {start. end}
    ].

    "Générer les nouveaux waypoints"
    1 to: neededWaypoints do: [:k ||start end i|
        i := ((k - 1) \\ segments size) + 1.
        start := (segments at: i) at:1.
        end := (segments at: i) at:2.
        fraction := ((k - 1) // neededWaypoints) + 0.5. "Point au milieu du segment pour régularité"
        newPoint := {
            (start at: 1) + ((end at: 1) - (start at: 1)) * fraction.
            (start at: 2) + ((end at: 2) - (start at: 2)) * fraction.
            (start at: 3) + ((end at: 3) - (start at: 3)) * fraction.
        }.
        result add: newPoint.
    ].

    ^ result


]

{ #category : 'initialization' }
ClusterMission >> initialize [ 
    status := #pending.
 
]

{ #category : 'characterization' }
ClusterMission >> isMixedMission [

^false
]

{ #category : 'characterization' }
ClusterMission >> isSecurizationMission [

^false
]

{ #category : 'characterization' }
ClusterMission >> isStrikeMission [

^false
]

{ #category : 'characterization' }
ClusterMission >> isSurveillanceMission [

^false
]

{ #category : 'characterization' }
ClusterMission >> isZoneBasedMission [

^false
]

{ #category : 'accessing' }
ClusterMission >> missionType [

	^ self className
]

{ #category : 'strategy' }
ClusterMission >> responseStrategy [
   ^self subclassResponsibility 
]
