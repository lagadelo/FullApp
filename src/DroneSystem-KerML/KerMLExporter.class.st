"
KerML Exporter - Generate KerML instance from a SimulationState
Usage:
    | exporter code |
    exporter := KerMLExporter new.
    code := exporter generateFromSimulationState: simState.
    exporter exportSimulationState: simState toFile: 'generated_system_instance.kerml'.
 
"
Class {
	#name : 'KerMLExporter',
	#superclass : 'Object',
	#instVars : [
		'out',
		'indent',
		'objectMap'
	],
	#category : 'DroneSystem-KerML',
	#package : 'DroneSystem-KerML'
}

{ #category : 'documentation' }
KerMLExporter class >> KerMLforMission [

"/**
 * KerML Model: Missions Hierarchy
 */
package MissionsModel {
    import CoreModel::*;

    // Base mission
    abstract class Mission {
        feature model : String; // reference to mission model/type
        feature status : MissionStatus;
        feature id : String;
        feature borderColor : String;
        feature color : String;
    }

enum MissionStatus {
    planned;
    active;
    completed;
    failed;
}

    // Cluster-level missions
    abstract class ClusterMission specializes Mission {}

    // Mixed mission with weighted sub-missions
    class MixedMission specializes ClusterMission {
        feature subMissions : WeightedSubMission[0..*];
        feature totalWeight : Real;
    }

    class WeightedSubMission {
        feature mission : Mission;
        feature weight : Real;
    }

    // Polygon geometry
    class Polygon {
        feature vertices : CoreModel::GeoPoint[3..*]; // at least 3 points
        feature wkt : String; // optional WKT representation
    }

    // Strike mission
    class StrikeMission specializes ClusterMission {
        feature targets : GeoPoint[0..*];
        feature target : GeoPoint[0..1];
    }

    // Zone based mission
    class ZoneBasedMission specializes ClusterMission {
        feature wayPoints : GeoPoint[0..*];
        feature polygon : Polygon;
        feature hasDeployed : Boolean;
    }

    class SecurizationMission specializes ZoneBasedMission {
        feature counter : Integer;
    }

    class SurveillanceMission specializes ZoneBasedMission {}

    // Drone-level missions
    abstract class DroneMission specializes Mission {
        feature wayPoints : GeoPoint[0..*];
    }

    class PatrolMission specializes DroneMission {}

    class StationaryMission specializes DroneMission {}
}

"
]

{ #category : 'documentation' }
KerMLExporter class >> kerMLforCoreModel [

"/**
 * KerML Model: Core - Fleet, Drones, Geo, Messages, Capabilities
 */
package CoreModel {

    // ---- Basic value types
    class GeoPoint {
        feature latitude : Real;
        feature longitude : Real;
        feature altitude : Real;
    }

    // Capabilities with dictionaries of metrics
    class Capabilities {
        // Current capabilities
        feature currentCapabilities : CapabilityEntry[0..*];
        // Max capabilities
        feature maxCapabilities : CapabilityEntry[0..*];
    }

    class CapabilityEntry {
        feature key : CapabilityKey;
        feature value : Real; // use Real for general numeric metric
    }

    enum CapabilityKey {
        perceptionRange;
        ammunition;
        energy;
        communicationRange;
    }

    // Messaging: a single Message and a Messages queue
    class Message {
        feature type : String;
        feature emiter : String; // id or name
        feature destinators : String[0..*];
        feature intent : String;
        feature receivers : String[0..*];
        feature payload : String; // can be JSON/text
    }

    class Messages {
        feature messageQueue : Message[0..*];
        feature sentMessages : Message[0..*];
        feature receivedMessages : Message[0..*];
    }

    // Base Fleet Element
    abstract class FleetElement {
        feature id : String;
        feature hostile : Boolean;
        feature capabilities : Capabilities;
        feature missions : Mission[0..*];
        feature messages : Messages;
    }

    // Components allowed inside a Cluster (excludes DroneFleet)
    abstract class ClusterComponent specializes FleetElement {}

    // Abstract Drone
    abstract class AbstractDrone specializes ClusterComponent {
        feature waypoint : GeoPoint[0..1];
        feature geoPoint : GeoPoint[0..1];
        feature behavior : String;
        feature type : String;
        feature cluster : DroneCluster[0..1];
    }

    // Logical Drone
    class Drone specializes AbstractDrone {
    }

    // Real Drone (hardware-backed)
    class RealDrone specializes AbstractDrone {
        feature adapter : String; // adapter reference or type
        feature currentCommandedWaypoint : GeoPoint[0..1];
    }

    // Cluster of fleet elements (composite pattern)
    class DroneCluster specializes ClusterComponent {
        feature components : ClusterComponent[0..*]; // Can contain Drones or other Clusters, but not DroneFleet
        feature coverage : String; // e.g., area/polygon id
        feature droneRoles : String[0..*];
        feature color : String;
    }

    // Fleet (top-level container, NOT part of FleetElement hierarchy)
    class DroneFleet {
        feature clusters : DroneCluster[0..*];
        feature hostileClusters : DroneCluster[0..*];
        feature log : String[0..*];
        feature fleetId : String;
        feature name : String;
    }

    // Forward declare Mission type for references
    import MissionsModel::Mission;
}

"
]

{ #category : 'documentation' }
KerMLExporter class >> kerMLforEvents [

"This is intentionally partial"

"/**
 * KerML Model: Simulation Events
 */
package EventsModel {
    import CoreModel::*;
    import MissionsModel::*;

    // Base event
    abstract class ScheduledEvent {
        feature timestamp : String;
        feature simulationState : SimulationModel::SimulationState;
        feature id : String;
        feature duration : Real;
        feature executed : Boolean;
        feature model : String;
    }

    class DestructionEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
        feature targetPosition : CoreModel::GeoPoint;
    }

    class DetectionByClusterEvent specializes ScheduledEvent {
        feature cluster : CoreModel::DroneCluster;
    }

    class LeaderElection specializes ScheduledEvent {
        feature cluster : CoreModel::DroneCluster;
    }

    class LeaderElectionRequest specializes ScheduledEvent {
        feature fromDrone : CoreModel::Drone;
        feature cluster : CoreModel::DroneCluster;
    }

    class MissionChangeEvent specializes ScheduledEvent {
        feature cluster : CoreModel::DroneCluster;
        feature newMission : MissionsModel::Mission;
    }

    class MissionStartEvent specializes ScheduledEvent {
        feature mission : MissionsModel::Mission;
    }

    class MoveStepEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
        feature speed : Real;
        feature wayPoint : CoreModel::GeoPoint;
    }

    class MoveToWaypointEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
        feature wayPoint : CoreModel::GeoPoint;
        feature speed : Real;
    }

    class ResumePatrolEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
    }

    class StartLeaderElectionRequest specializes ScheduledEvent {
        feature requestedByDrone : CoreModel::Drone;
        feature cluster : CoreModel::DroneCluster;
    }

    class WayPointReachedEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
        feature wayPoint : CoreModel::GeoPoint;
    }

    class SurveillanceHoldPositionEvent specializes ScheduledEvent {
        feature drone : CoreModel::Drone;
        feature holdDuration : Real;
        feature waypoint : CoreModel::GeoPoint;
    }
}
"
]

{ #category : 'documentation' }
KerMLExporter class >> kerMLforSimulationTooling [
"/**
 * KerML Model: Simulation Infrastructure
 */
package SimulationModel {
    import CoreModel::*;
    import MissionsModel::*;
    import EventsModel::*;

    class SimulationState {
        feature time : Real;
        feature allFleets : DroneFleet[0..*];
        feature missions : Mission[0..*];
        feature eventLog : String[0..*];
        feature missionHistory : String[0..*];
        feature reactionLog : String[0..*];
        feature engagementMode : EngagementMode;
        feature steps : Integer;
        feature verificationFunctions : String[0..*];
        feature observers : String[0..*];
    }

    enum EngagementMode {
        passive;
        defensive;
        aggressive;
        stealth;
    }

    class DiscreteEventScheduler {
        feature eventQueue : ScheduledEvent[0..*];
        feature eventGraph : EventDependencyGraph;
    }

    class EventDependencyGraph {
        feature nodes : ScheduledEvent[0..*];
        feature edges : EventDependency[0..*];
        feature scheduler : DiscreteEventScheduler[0..1];
    }

    class EventDependency {
        feature from : ScheduledEvent;
        feature to : ScheduledEvent;
        feature type : DependencyType;
    }

    enum DependencyType {
        precedes;
        blocks;
        triggers;
    }

    class ElectionSession {
        feature cluster : DroneCluster;
        feature initiator : Drone;
        feature dronesPending : Drone[0..*];
        feature statusByDrone : ElectionStatus[0..*];
        feature createdAt : String;
        feature strategy : ElectionStrategy;
    }

    class ElectionStatus {
        feature drone : Drone;
        feature status : String; // e.g., pending/accepted/rejected
    }

    enum ElectionStrategy {
        highest_capability;
        nearest;
        random;
        seniority;
    }

    class DroneSimulator {
        feature model : SimulationState;
        feature scheduler : DiscreteEventScheduler;
        feature currentTime : Real;
        feature timeStep : Real;
        feature entityEventMap : String[0..*]; // serialized mapping
        feature eventGraph : EventDependencyGraph;
        feature electionSessions : ElectionSession[0..*];
        feature autoResume : Boolean;
        feature isRunning : Boolean;
    }
}
"
]

{ #category : 'enum handling' }
KerMLExporter >> capabilityKeyKerMLFor: aKey [
    "Accept symbols, strings, or custom key objects; normalize to KerML enum values
    defined in CoreModel::CapabilityKey: perceptionRange, ammunition, energy, communicationRange.
    Provide reasonable fallbacks for common synonyms."
    | s |
    aKey isNil ifTrue: [ ^ nil ].
    s := aKey asString asLowercase.
    (#('perceptionrange' 'perception_range' 'sensorrange' 'sensor_range' 'range') includes: s)
        ifTrue: [ ^ 'perceptionRange' ].
    (#('ammo' 'ammunition' 'munitions') includes: s)
        ifTrue: [ ^ 'ammunition' ].
    (#('energy' 'battery' 'autonomy' 'power') includes: s)
        ifTrue: [ ^ 'energy' ].
    (#('communication' 'communicationrange' 'comms' 'commsrange' 'com_range') includes: s)
        ifTrue: [ ^ 'communicationRange' ].
    "Default: if matches existing enum exactly, return; else nil to skip."
    (#('perceptionRange' 'ammunition' 'energy' 'communicationRange') includes: aKey asString)
        ifTrue: [ ^ aKey asString ].
    ^ nil

]

{ #category : 'naming' }
KerMLExporter >> ensureNameFor: anObject prefix: aPrefix [
    | name |
    name := objectMap at: anObject ifAbsent: [
        | base |
        base := aPrefix, '_', (UUID new asString copyReplaceAll: '-' with: '_').
        objectMap at: anObject put: base.
        base
    ].
    ^ name
]

{ #category : 'generating' }
KerMLExporter >> exportSimulationState: aSimState toFile: aFilename [
    | code |
    code := self generateFromSimulationState: aSimState.
    aFilename asFileReference writeStreamDo: [ :s | s nextPutAll: code ].

]

{ #category : 'writing' }
KerMLExporter >> formatValue: val [
    (val isKindOf: String) ifTrue: [ ^ '"', val, '"' ].
    (val isKindOf: Number) ifTrue: [ ^ val asString ].
    (val isKindOf: UUID) ifTrue: [ ^ '"', val asString, '"' ].
    ^ '"', val asString, '"'.
]

{ #category : 'generating' }
KerMLExporter >> generateCluster: aCluster [
    | name |
    name := self ensureNameFor: aCluster prefix: 'cluster'.
    self writeLine: 'feature ', name, ' : CoreModel::DroneCluster {'.
    self in.
    
    self writeScalarIfNotNil: 'id' value: aCluster id asString.
    self writeBoolIfNotNil: 'hostile' value: aCluster hostile.
    self writeScalarIfNotNil: 'color' value: aCluster color.
    self writeScalarIfNotNil: 'coverage' value: aCluster coverage.
    (aCluster droneRoles ifNil: [#()]) isEmpty ifFalse: [
        aCluster droneRoles do: [ :role |
            self writeScalarIfNotNil: 'droneRoles' value: role
        ]
    ].
    
    self writeCapabilitiesIfPresent: aCluster capabilities.

    "Messages (if present on FleetElement)"
    (aCluster respondsTo: #messages) ifTrue: [ self writeMessagesIfPresent: aCluster messages ].
    
    "Components (composite pattern: drones or sub-clusters)"
    (aCluster respondsTo: #components) ifTrue: [
        (aCluster components ifNil: [#()]) do: [ :component |
            (component isKindOf: DroneCluster) 
                ifTrue: [ self generateCluster: component ]
                ifFalse: [ self generateDrone: component ]
        ]
    ] ifFalse: [
        "Fallback: legacy 'drones' accessor"
        (aCluster respondsTo: #drones) ifTrue: [
            (aCluster drones ifNil: [#()]) do: [ :drone | self generateDrone: drone ]
        ]
    ].
    
    "Missions"
    (aCluster missions ifNil: [#()]) do: [ :m | self generateMission: m ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'generating' }
KerMLExporter >> generateDrone: aDrone [
    | className name |
    className := (aDrone isKindOf: RealDrone)
        ifTrue: ['CoreModel::RealDrone']
        ifFalse: ['CoreModel::Drone'].
    name := self ensureNameFor: aDrone prefix: 'drone'.
    self writeLine: 'feature ', name, ' : ', className, ' {'.
    self in.
    
    self writeScalarIfNotNil: 'id' value: aDrone id asString.
    self writeBoolIfNotNil: 'hostile' value: aDrone hostile.
    self writeScalarIfNotNil: 'type' value: aDrone type.
    self writeScalarIfNotNil: 'behavior' value: aDrone behavior.
    
    (aDrone geoPoint) ifNotNil: [ self generateGeoPoint: aDrone geoPoint named: 'geoPoint' ].
    (aDrone waypoint) ifNotNil: [ self generateGeoPoint: aDrone waypoint named: 'waypoint' ].
    
    (aDrone isKindOf: RealDrone) ifTrue: [
        | rd |
        rd := aDrone.
        self writeScalarIfNotNil: 'adapter' value: rd adapter.
        (rd currentCommandedWaypoint) ifNotNil: [ self generateGeoPoint: rd currentCommandedWaypoint named: 'currentCommandedWaypoint' ].
    ].
    
    self writeCapabilitiesIfPresent: aDrone capabilities.

    "Messages (if present on FleetElement)"
    (aDrone respondsTo: #messages) ifTrue: [ self writeMessagesIfPresent: aDrone messages ].
    
    "Drone missions"
    (aDrone missions ifNil: [#()]) do: [ :m | self generateMission: m ].
    
    "Cluster reference"
    aDrone cluster ifNotNil: [ :cluster |
        | ref |
        ref := self nameFor: cluster.
        ref ifNotNil: [ self writeLine: 'feature cluster = ', ref, ';' ]
    ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'generating' }
KerMLExporter >> generateFleet: aFleet [
    | name |
    name := self ensureNameFor: aFleet prefix: 'fleet'.
    self writeLine: 'feature ', name, ' : CoreModel::DroneFleet {'.
    self in.
    
    self writeScalarIfNotNil: 'fleetId' value: aFleet fleetId.
    self writeScalarIfNotNil: 'name' value: aFleet name.
    self writeBoolIfNotNil: 'hostile' value: aFleet hostile.

    "Messages (if present on FleetElement)"
    (aFleet respondsTo: #messages) ifTrue: [ self writeMessagesIfPresent: aFleet messages ].
    
    "Clusters (allied)"
    (aFleet clusters ifNil: [#()]) do: [ :cluster | self generateCluster: cluster ].
    
    "Hostile clusters"
    (aFleet hostileClusters ifNil: [#()]) do: [ :cluster | self generateCluster: cluster ].
    
    "Fleet missions"
    (aFleet missions ifNil: [#()]) do: [ :m | self generateMission: m ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'generating' }
KerMLExporter >> generateFromSimulationState: aSimState [
    self writeHeader: 'Generated Drone System Instance'.
    self writePackageStart: 'GeneratedInstance'.
    self writeImports.
    
    self generateSimulationState: aSimState.
    
    self writePackageEnd.
    ^ out contents

]

{ #category : 'generating' }
KerMLExporter >> generateGeoPoint: aGeoPoint named: field [
    | name |
    name := field.
    self writeLine: 'feature ', name, ' : CoreModel::GeoPoint {'.
    self in.
    self writeScalarIfNotNil: 'latitude' value: aGeoPoint latitude.
    self writeScalarIfNotNil: 'longitude' value: aGeoPoint longitude.
    self writeScalarIfNotNil: 'altitude' value: aGeoPoint altitude.
    self out.
    self writeLine: '}'.
]

{ #category : 'generating' }
KerMLExporter >> generateMission: aMission [
    | name kermlClass |
    name := self ensureNameFor: aMission prefix: 'mission'.
    kermlClass := self missionKerMLClassFor: aMission.
    self writeLine: 'feature ', name, ' : ', kermlClass, ' {'.
    self in.
    
    self writeScalarIfNotNil: 'id' value: aMission id asString.
    self writeScalarIfNotNil: 'model' value: aMission model.
    self writeEnumIfNotNil: 'status' value: aMission status type: 'MissionsModel::MissionStatus'.
    self writeScalarIfNotNil: 'borderColor' value: aMission borderColor.
    self writeScalarIfNotNil: 'color' value: aMission color.
    
    "Specifics"
    (aMission respondsTo: #wayPoints) ifTrue: [
        (aMission wayPoints ifNil: [#()]) do: [ :wp | self generateGeoPoint: wp named: 'wayPoints' ]
    ].
    (aMission respondsTo: #polygon) ifTrue: [
        | poly |
        poly := aMission polygon.
        poly ifNotNil: [
            (poly isKindOf: Collection) ifTrue: [
                self writeLine: 'feature polygon : MissionsModel::Polygon {'.
                self in.
                poly do: [ :gp | self generateGeoPoint: gp named: 'vertices' ].
                self out.
                self writeLine: '}'.
            ] ifFalse: [
                (poly respondsTo: #vertices) | (poly respondsTo: #wkt) ifTrue: [
                    self writeLine: 'feature polygon : MissionsModel::Polygon {'.
                    self in.
                    (poly respondsTo: #vertices) ifTrue: [
                        (poly vertices ifNil: [#()]) do: [ :gp | self generateGeoPoint: gp named: 'vertices' ]
                    ].
                    (poly respondsTo: #wkt) ifTrue: [ self writeScalarIfNotNil: 'wkt' value: poly wkt ].
                    self out.
                    self writeLine: '}'.
                ] ifFalse: [
                    self writeLine: 'feature polygon : MissionsModel::Polygon {'.
                    self in.
                    self writeScalarIfNotNil: 'wkt' value: poly.
                    self out.
                    self writeLine: '}'.
                ].
            ].
        ]
    ].
    (aMission respondsTo: #hasDeployed) ifTrue: [ self writeBoolIfNotNil: 'hasDeployed' value: aMission hasDeployed ].
    (aMission respondsTo: #counter) ifTrue: [ self writeScalarIfNotNil: 'counter' value: aMission counter ].
    (aMission respondsTo: #targets) ifTrue: [
        (aMission targets ifNil: [#()]) do: [ :t | self generateGeoPoint: t named: 'targets' ]
    ].
    (aMission respondsTo: #target) ifTrue: [
        aMission target ifNotNil: [ :t | self generateGeoPoint: t named: 'target' ]
    ].
    (aMission respondsTo: #subMissions) ifTrue: [
        (aMission subMissions ifNil: [#()]) do: [ :assoc |
            | mission weight sname |
            mission := assoc key ifNil: [ assoc mission ] ifNotNil: [ assoc key ].
            weight := assoc value ifNil: [ assoc weight ].
            sname := self ensureNameFor: mission prefix: 'subMission'.
            self writeLine: 'feature subMissions : MissionsModel::WeightedSubMission {'.
            self in.
            self writeLine: 'feature mission = ', (self ensureNameFor: mission prefix: 'mission'), ';'.
            self writeScalarIfNotNil: 'weight' value: weight.
            self out.
            self writeLine: '}'.
        ]
    ].
    (aMission respondsTo: #totalWeight) ifTrue: [ self writeScalarIfNotNil: 'totalWeight' value: aMission totalWeight ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'generating' }
KerMLExporter >> generateSimulationState: aSimState [
    | name |
    name := self ensureNameFor: aSimState prefix: 'simulationState'.
    self writeLine: 'feature ', name, ' : SimulationModel::SimulationState {'.
    self in.
    
    self writeScalarIfNotNil: 'time' value: aSimState time.
    self writeEnumIfNotNil: 'engagementMode' value: aSimState engagementMode type: 'SimulationModel::EngagementMode'.
    self writeScalarIfNotNil: 'steps' value: aSimState steps.
    
    "Fleets"
    (aSimState allFleets ifNil: [#()]) isEmpty ifFalse: [
        self writeLine: ''.
        self writeLine: '// Fleets'.
        aSimState allFleets do: [ :fleet | self generateFleet: fleet ]
    ].
    
    "Missions"
    (aSimState missions ifNil: [#()]) isEmpty ifFalse: [
        self writeLine: ''.
        self writeLine: '// Global Missions'.
        aSimState missions do: [ :m | self generateMission: m ]
    ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'counting' }
KerMLExporter >> in [
    indent := indent + 1.
]

{ #category : 'generating' }
KerMLExporter >> initialize [
    super initialize.
    out := WriteStream on: String new.
    indent := 0.
    objectMap := Dictionary new. "Pharo object -> KerML feature name"

]

{ #category : 'enum handling' }
KerMLExporter >> missionKerMLClassFor: aMission [
    (aMission isKindOf: PatrolMission) ifTrue: [ ^ 'MissionsModel::PatrolMission' ].
    (aMission isKindOf: StationaryMission) ifTrue: [ ^ 'MissionsModel::StationaryMission' ].
    (aMission isKindOf: ZoneBasedMission) ifTrue: [ ^ 'MissionsModel::ZoneBasedMission' ].
    (aMission isKindOf: SecurizationMission) ifTrue: [ ^ 'MissionsModel::SecurizationMission' ].
    (aMission isKindOf: SurveillanceMission) ifTrue: [ ^ 'MissionsModel::SurveillanceMission' ].
    (aMission isKindOf: StrikeMission) ifTrue: [ ^ 'MissionsModel::StrikeMission' ].
    (aMission isKindOf: MixedMission) ifTrue: [ ^ 'MissionsModel::MixedMission' ].
    (aMission isKindOf: DroneMission) ifTrue: [ ^ 'MissionsModel::DroneMission' ].
    (aMission isKindOf: ClusterMission) ifTrue: [ ^ 'MissionsModel::ClusterMission' ].
    ^ 'MissionsModel::Mission'
]

{ #category : 'naming' }
KerMLExporter >> nameFor: anObject [
    ^ objectMap at: anObject ifAbsent: [ nil ]
]

{ #category : 'counting' }
KerMLExporter >> out [
    indent := (indent - 1) max: 0.
]

{ #category : 'writing' }
KerMLExporter >> writeBoolIfNotNil: field value: val [
    val ifNil: [ ^ self ].
    self writeLine: 'feature ', field, ' = ', (val ifTrue: ['true'] ifFalse: ['false']), ';'.

]

{ #category : 'writing' }
KerMLExporter >> writeCapabilitiesIfPresent: caps [
    caps ifNil: [ ^ self ].
    self writeLine: 'feature capabilities : CoreModel::Capabilities .slots {'.
    self in.
    
    (caps currentCapabilities ifNil: [Dictionary new]) keysAndValuesDo: [ :key :val |
        | mapped |
        mapped := self capabilityKeyKerMLFor: key.
        self writeLine: 'feature currentCapabilities : CoreModel::CapabilityEntry .slots {'.
        self in.
        mapped
            ifNil: [
                self writeLine: '// Warning: unknown capability key \'', key asString, '\' — entry skipped to remain future-proof.'
            ]
            ifNotNil: [
                self writeEnumIfNotNil: 'key' value: mapped type: 'CoreModel::CapabilityKey'.
                self writeScalarIfNotNil: 'value' value: val.
            ].
        self out.
        self writeLine: '}'.
    ].
    
    (caps maxCapabilities ifNil: [Dictionary new]) keysAndValuesDo: [ :key :val |
        | mapped |
        mapped := self capabilityKeyKerMLFor: key.
        self writeLine: 'feature maxCapabilities : CoreModel::CapabilityEntry .slots {'.
        self in.
        mapped
            ifNil: [
                self writeLine: '// Warning: unknown capability key \'', key asString, '\' — entry skipped to remain future-proof.'
            ]
            ifNotNil: [
                self writeEnumIfNotNil: 'key' value: mapped type: 'CoreModel::CapabilityKey'.
                self writeScalarIfNotNil: 'value' value: val.
            ].
        self out.
        self writeLine: '}'.
    ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'writing' }
KerMLExporter >> writeEnumIfNotNil: field value: val type: typeName [
    val ifNil: [ ^ self ].
    self writeLine: 'feature ', field, ' = ', typeName, '::', val asString, ';'.
]

{ #category : 'writing' }
KerMLExporter >> writeHeader: title [
    self writeLine: '/**'.
    self writeLine: ' * KerML Model: ', title.
    self writeLine: ' * Date: ', DateAndTime now asString.
    self writeLine: ' */'.
    self writeLine: ''.

]

{ #category : 'writing' }
KerMLExporter >> writeImports [
    self writeLine: 'import CoreModel::*;'.
    self writeLine: 'import MissionsModel::*;'.
    self writeLine: 'import SimulationModel::*;'.
    self writeLine: 'import EventsModel::*;'.
    self writeLine: ''.
]

{ #category : 'writing' }
KerMLExporter >> writeLine: aString [
    out nextPutAll: (String new: indent * 4 withAll: $ ).
    out nextPutAll: aString.
    out cr.
]

{ #category : 'writing' }
KerMLExporter >> writeMessagesIfPresent: msgs [
    msgs ifNil: [ ^ self ].
    self writeLine: 'feature messages : CoreModel::Messages {'.
    self in.
    
    "messageQueue"
    (msgs respondsTo: #messageQueue) ifTrue: [
        (msgs messageQueue ifNil: [#()]) do: [ :m |
            self writeLine: 'feature messageQueue : CoreModel::Message {'.
            self in.
            self writeScalarIfNotNil: 'type' value: ((m respondsTo: #type) ifTrue: [ m type ] ifFalse: [ nil ]).
            self writeScalarIfNotNil: 'emiter' value: ((m respondsTo: #emiter) ifTrue: [ m emiter ] ifFalse: [ nil ]).
            (m respondsTo: #destinators) ifTrue: [
                (m destinators ifNil: [#()]) do: [ :d | self writeScalarIfNotNil: 'destinators' value: d ]
            ].
            self writeScalarIfNotNil: 'intent' value: ((m respondsTo: #intent) ifTrue: [ m intent ] ifFalse: [ nil ]).
            (m respondsTo: #receivers) ifTrue: [
                (m receivers ifNil: [#()]) do: [ :r | self writeScalarIfNotNil: 'receivers' value: r ]
            ].
            self writeScalarIfNotNil: 'payload' value: ((m respondsTo: #payload) ifTrue: [ m payload ] ifFalse: [ nil ]).
            self out.
            self writeLine: '}'.
        ]
    ].
    
    "sentMessages"
    (msgs respondsTo: #sentMessages) ifTrue: [
        (msgs sentMessages ifNil: [#()]) do: [ :m |
            self writeLine: 'feature sentMessages : CoreModel::Message {'.
            self in.
            self writeScalarIfNotNil: 'type' value: ((m respondsTo: #type) ifTrue: [ m type ] ifFalse: [ nil ]).
            self writeScalarIfNotNil: 'emiter' value: ((m respondsTo: #emiter) ifTrue: [ m emiter ] ifFalse: [ nil ]).
            (m respondsTo: #destinators) ifTrue: [
                (m destinators ifNil: [#()]) do: [ :d | self writeScalarIfNotNil: 'destinators' value: d ]
            ].
            self writeScalarIfNotNil: 'intent' value: ((m respondsTo: #intent) ifTrue: [ m intent ] ifFalse: [ nil ]).
            (m respondsTo: #receivers) ifTrue: [
                (m receivers ifNil: [#()]) do: [ :r | self writeScalarIfNotNil: 'receivers' value: r ]
            ].
            self writeScalarIfNotNil: 'payload' value: ((m respondsTo: #payload) ifTrue: [ m payload ] ifFalse: [ nil ]).
            self out.
            self writeLine: '}'.
        ]
    ].
    
    "receivedMessages"
    (msgs respondsTo: #receivedMessages) ifTrue: [
        (msgs receivedMessages ifNil: [#()]) do: [ :m |
            self writeLine: 'feature receivedMessages : CoreModel::Message {'.
            self in.
            self writeScalarIfNotNil: 'type' value: ((m respondsTo: #type) ifTrue: [ m type ] ifFalse: [ nil ]).
            self writeScalarIfNotNil: 'emiter' value: ((m respondsTo: #emiter) ifTrue: [ m emiter ] ifFalse: [ nil ]).
            (m respondsTo: #destinators) ifTrue: [
                (m destinators ifNil: [#()]) do: [ :d | self writeScalarIfNotNil: 'destinators' value: d ]
            ].
            self writeScalarIfNotNil: 'intent' value: ((m respondsTo: #intent )ifTrue: [ m intent ] ifFalse: [ nil ]).
            (m respondsTo: #receivers) ifTrue: [
                (m receivers ifNil: [#()]) do: [ :r | self writeScalarIfNotNil: 'receivers' value: r ]
            ].
            self writeScalarIfNotNil: 'payload' value: ((m respondsTo: #payload) ifTrue: [ m payload ] ifFalse: [ nil ]).
            self out.
            self writeLine: '}'.
        ]
    ].
    
    self out.
    self writeLine: '}'.
]

{ #category : 'writing' }
KerMLExporter >> writePackageEnd [
    self out.
    self writeLine: '}'.

]

{ #category : 'writing' }
KerMLExporter >> writePackageStart: pkg [
    self writeLine: 'package ', pkg, ' {'.
    self in.
]

{ #category : 'writing' }
KerMLExporter >> writeScalarIfNotNil: field value: val [
    val ifNil: [ ^ self ].
    self writeLine: 'feature ', field, ' = ', (self formatValue: val), ';'.

]
