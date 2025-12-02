Class {
	#name : 'KerMLExporterTestCase',
	#superclass : 'TestCase',
	#category : 'DroneSystem-KerML-Tests',
	#package : 'DroneSystem-KerML-Tests'
}

{ #category : 'testing' }
KerMLExporterTestCase >> runAllTests [
    "Convenience method to run all tests"
    | results |
    results := OrderedCollection new.
    
    Transcript
        show: '================================';
        cr;
        show: 'Running KerML Exporter Test Suite';
        cr;
        show: '================================';
        cr.
    
    [ self testCapabilityKeyMapping. results add: 'Capability mapping: PASS' ]
        on: Error do: [ :e | results add: 'Capability mapping: FAIL - ', e messageText ].
    
    [ self testMinimalExport. results add: 'Minimal export: PASS' ]
        on: Error do: [ :e | results add: 'Minimal export: FAIL - ', e messageText ].
    
    [ self testDroneWithCapabilities. results add: 'Drone capabilities: PASS' ]
        on: Error do: [ :e | results add: 'Drone capabilities: FAIL - ', e messageText ].
    
    [ self testPolygonExport. results add: 'Polygon export: PASS' ]
        on: Error do: [ :e | results add: 'Polygon export: FAIL - ', e messageText ].
    
    [ self testMessagesExport. results add: 'Messages export: PASS' ]
        on: Error do: [ :e | results add: 'Messages export: FAIL - ', e messageText ].
    
    [ self testExportBlock4Scenario. results add: 'Full Block4 scenario: PASS' ]
        on: Error do: [ :e | results add: 'Full Block4 scenario: FAIL - ', e messageText ].
    
    Transcript
        cr;
        show: '================================';
        cr;
        show: 'Test Results:';
        cr;
        show: '================================';
        cr.
    
    results do: [ :result |
        Transcript show: result; cr
    ].
    
    Transcript
        cr;
        show: 'Tests completed.';
        cr.
    
    ^ results
]

{ #category : 'testing' }
KerMLExporterTestCase >> testCapabilityKeyMapping [
    "Test capability key normalization"
    | exporter |
    exporter := KerMLExporter new.
    
    "Test known keys"
    self assert: (exporter capabilityKeyKerMLFor: 'energy') equals: 'energy'.
    self assert: (exporter capabilityKeyKerMLFor: 'ammunition') equals: 'ammunition'.
    self assert: (exporter capabilityKeyKerMLFor: 'perceptionRange') equals: 'perceptionRange'.
    self assert: (exporter capabilityKeyKerMLFor: 'communicationRange') equals: 'communicationRange'.
    
    "Test synonyms"
    self assert: (exporter capabilityKeyKerMLFor: 'battery') equals: 'energy'.
    self assert: (exporter capabilityKeyKerMLFor: 'ammo') equals: 'ammunition'.
    self assert: (exporter capabilityKeyKerMLFor: 'range') equals: 'perceptionRange'.
    self assert: (exporter capabilityKeyKerMLFor: 'comms') equals: 'communicationRange'.
    
    "Test unknown key returns nil"
    self assert: (exporter capabilityKeyKerMLFor: 'unknownKey') isNil.
    
    Transcript
        show: '✓ Test passed: Capability key mapping';
        cr
]

{ #category : 'testing' }
KerMLExporterTestCase >> testDroneWithCapabilities [
    "Test drone export with capabilities"
    | sim fleet cluster drone exporter code caps |
    sim := SimulationState new.
    
    "Create drone with capabilities"
    drone := Drone new.
    drone id: UUID new.
    drone geoPoint: (GeoPoint new latitude: 48.8566; longitude: 2.3522; altitude: 100; yourself).
    
    caps := Capabilities new.
    caps currentCapabilities: (Dictionary new
        at: 'energy' put: 75;
        at: 'ammunition' put: 20;
        yourself).
    caps maxCapabilities: (Dictionary new
        at: 'energy' put: 100;
        at: 'ammunition' put: 50;
        yourself).
    drone capabilities: caps.
    
    "Create cluster and fleet"
    cluster := DroneCluster new.
    cluster id: 'C1'.
    (cluster respondsTo: #components:)
        ifTrue: [ cluster components: (OrderedCollection with: drone) ]
        ifFalse: [ cluster drones: (OrderedCollection with: drone) ].
    
    fleet := DroneFleet new.
    fleet fleetId: 'F1'.
    (fleet respondsTo: #addCluster:)
        ifTrue: [ fleet addCluster: cluster ]
        ifFalse: [ fleet clusters: (OrderedCollection with: cluster) ].
    
    sim allFleets: (OrderedCollection with: fleet).
    
    "Export"
    exporter := KerMLExporter new.
    code := exporter generateFromSimulationState: sim.
    
    "Validate capabilities output"
    self assert: (code includesSubstring: 'feature capabilities : CoreModel::Capabilities').
    self assert: (code includesSubstring: 'feature currentCapabilities : CoreModel::CapabilityEntry').
    self assert: (code includesSubstring: 'CoreModel::CapabilityKey::energy').
    self assert: (code includesSubstring: 'CoreModel::CapabilityKey::ammunition').
    self deny: (code includesSubstring: '<<').
    
    Transcript
        show: '✓ Test passed: Drone with capabilities';
        cr.
    
    ^ code
]

{ #category : 'testing' }
KerMLExporterTestCase >> testExportBlock4Scenario [
    "Full integration test: 30 drones, cluster, fleet, mission with polygon"
    | simulator polygon drones sim cluster1 mission fleet exporter kermlFile generatedCode |
    
    "Setup output file"
    kermlFile := 'generated_example_block4_test.kerml'.
    
    "Create SimulationState"
    sim := SimulationState new.
    sim time: 0.
    sim steps: 0.
    
    "Create 30 example drones with GeoPoints"
    drones := (1 to: 30) collect: [ :i |
        | d gp |
        d := Drone new.
        d id: (UUID new).
        d hostile: false.
        d type: 'Scout'.
        d behavior: 'patrol'.
        
        "Ensure each drone has a GeoPoint"
        gp := GeoPoint new
            latitude: 48.0 + (i * 0.01);
            longitude: 2.0 + (i * 0.01);
            altitude: 100;
            yourself.
        d geoPoint: gp.
        
        "Optional: add capabilities"
        (d respondsTo: #capabilities:) ifTrue: [
            | caps |
            caps := Capabilities new.
            caps currentCapabilities: (Dictionary new
                at: 'energy' put: 100;
                at: 'ammunition' put: 50;
                yourself).
            caps maxCapabilities: (Dictionary new
                at: 'energy' put: 100;
                at: 'ammunition' put: 50;
                yourself).
            d capabilities: caps
        ].
        
        d
    ].
    
    "Create cluster with drones"
    cluster1 := DroneCluster new.
    (cluster1 respondsTo: #initializeWithDrones:clusterId:)
        ifTrue: [ 
            cluster1 initializeWithDrones: drones clusterId: 'Cluster #1'
        ]
        ifFalse: [
            cluster1 id: 'Cluster #1'.
            cluster1 hostile: false.
            (cluster1 respondsTo: #components:)
                ifTrue: [ cluster1 components: drones ]
                ifFalse: [ cluster1 drones: drones ]
        ].
    
    "Set cluster color and coverage"
    (cluster1 respondsTo: #color:) ifTrue: [ cluster1 color: '#3498db' ].
    (cluster1 respondsTo: #coverage:) ifTrue: [ cluster1 coverage: 5000 ].
    
    "Create fleet and add cluster"
    fleet := DroneFleet new.
    fleet fleetId: 'FLEET-001'.
    fleet name: 'Test Fleet Alpha'.
    fleet hostile: false.
    
    (fleet respondsTo: #addCluster:)
        ifTrue: [ fleet addCluster: cluster1 ]
        ifFalse: [ 
            (fleet respondsTo: #clusters:)
                ifTrue: [ fleet clusters: (OrderedCollection with: cluster1) ]
        ].
    
    "Add fleet to simulation"
    (sim respondsTo: #addFleet:)
        ifTrue: [ sim addFleet: fleet ]
        ifFalse: [ sim allFleets: (OrderedCollection with: fleet) ].
    
    "Create polygon with GeoPoints (Brest, Marseille, Lille, Londres)"
    polygon := {
        { 48.3904. -4.4947. 100 }.  "Brest"
        { 43.2965. 5.3698. 100 }.   "Marseille"
        { 50.6292. 3.0573. 100 }.   "Lille"
        { 51.5074. -0.1276. 100 }   "Londres"
    } collect: [ :triple |
        GeoPoint new
            latitude: triple first;
            longitude: triple second;
            altitude: triple third;
            yourself
    ].
    
    "Create Securization mission with polygon"
    mission := SecurizationMission new.
    mission id: 'SECUR-BLOCK4'.
    mission model: 'SecurizationScenario'.
    mission status: #planned.
    mission borderColor: '#FF8800'.
    mission color: '#FFCC99'.
    
    "Set polygon as GeoPoint collection (will be exported as vertices)"
    (mission respondsTo: #polygon:) ifTrue: [ 
        mission polygon: polygon.
    ].
    
    "Optionally set wayPoints too"
    (mission respondsTo: #wayPoints:) ifTrue: [
        mission wayPoints: polygon
    ].
    
    "Add mission to cluster, fleet, and simulation"
    (cluster1 respondsTo: #addMission:)
        ifTrue: [ cluster1 addMission: mission ]
        ifFalse: [ 
            cluster1 missions ifNil: [ cluster1 missions: OrderedCollection new ].
            cluster1 missions add: mission
        ].
    
    (fleet respondsTo: #addMission:)
        ifTrue: [ fleet addMission: mission ]
        ifFalse: [
            fleet missions ifNil: [ fleet missions: OrderedCollection new ].
            fleet missions add: mission
        ].
    
    (sim respondsTo: #addMission:)
        ifTrue: [ sim addMission: mission ]
        ifFalse: [
            sim missions ifNil: [ sim missions: OrderedCollection new ].
            sim missions add: mission
        ].
    
    "Export to KerML"
    exporter := KerMLExporter new.
    generatedCode := exporter generateFromSimulationState: sim.
    
    "Write to file"
    kermlFile asFileReference writeStreamDo: [ :s | 
        s nextPutAll: generatedCode 
    ].
    
    "Assertions to validate output"
    self assert: generatedCode notNil description: 'Generated code should not be nil'.
    self assert: (generatedCode includesSubstring: 'package GeneratedInstance') description: 'Should contain package declaration'.
    self assert: (generatedCode includesSubstring: 'feature simulationState') description: 'Should contain simulation state'.
    self assert: (generatedCode includesSubstring: 'CoreModel::DroneFleet') description: 'Should contain fleet type'.
    self assert: (generatedCode includesSubstring: 'CoreModel::DroneCluster') description: 'Should contain cluster type'.
    self assert: (generatedCode includesSubstring: 'CoreModel::Drone') description: 'Should contain drone type'.
    self assert: (generatedCode includesSubstring: 'MissionsModel::SecurizationMission') description: 'Should contain mission type'.
    self assert: (generatedCode includesSubstring: 'feature polygon : MissionsModel::Polygon') description: 'Should contain polygon'.
    self assert: (generatedCode includesSubstring: 'feature vertices : CoreModel::GeoPoint') description: 'Should contain polygon vertices'.
    self deny: (generatedCode includesSubstring: '.slots') description: 'Should not contain Pharo .slots syntax'.
    self deny: (generatedCode includesSubstring: 'slot ') description: 'Should not contain slot keyword'.
    self deny: (generatedCode includesSubstring: '<<') description: 'Should not contain angle bracket enum wrapping'.
    self assert: (generatedCode includesSubstring: 'feature ') description: 'Should use KerML feature keyword'.
    
    "Log success"
    Transcript
        show: '✓ Test passed: KerML export successful';
        cr;
        show: '  File: ', kermlFile;
        cr;
        show: '  Size: ', generatedCode size asString, ' characters';
        cr;
        show: '  Drones: 30';
        cr;
        show: '  Polygon vertices: 4';
        cr.
    
    ^ generatedCode
]

{ #category : 'testing' }
KerMLExporterTestCase >> testMessagesExport [
    "Test message queue export"
    | sim fleet drone exporter code msgs msg |
    sim := SimulationState new.
    
    "Create drone with messages"
    drone := Drone new.
    drone id: UUID new.
    drone geoPoint: (GeoPoint new latitude: 48.0; longitude: 2.0; altitude: 100; yourself).
    
    "Create Messages with messageQueue"
    (drone respondsTo: #messages:) ifTrue: [
        msgs := Messages new.
        msg := Message new.
        (msg respondsTo: #type:) ifTrue: [ msg type: 'command' ].
        (msg respondsTo: #emiter:) ifTrue: [ msg emiter: 'controller' ].
        (msg respondsTo: #payload:) ifTrue: [ msg payload: 'move_to_waypoint' ].
        
        msgs messageQueue: (OrderedCollection with: msg).
        drone messages: msgs.
    ].
    
    "Create cluster and fleet"
    fleet := DroneFleet new.
    fleet fleetId: 'F1'.
    fleet clusters: (OrderedCollection with: (DroneCluster new
        id: 'C1';
        drones: (OrderedCollection with: drone);
        yourself)).
    
    sim allFleets: (OrderedCollection with: fleet).
    
    "Export"
    exporter := KerMLExporter new.
    code := exporter generateFromSimulationState: sim.
    
    "Validate messages output"
    (drone respondsTo: #messages) ifTrue: [
        self assert: (code includesSubstring: 'feature messages : CoreModel::Messages').
        self assert: (code includesSubstring: 'feature messageQueue : CoreModel::Message').
    ].
    
    Transcript
        show: '✓ Test passed: Messages export';
        cr.
    
    ^ code
]

{ #category : 'testing' }
KerMLExporterTestCase >> testMinimalExport [
    "Test minimal export with just simulation state"
    | sim exporter code |
    sim := SimulationState new.
    sim time: 42.
    sim steps: 10.
    
    exporter := KerMLExporter new.
    code := exporter generateFromSimulationState: sim.
    
    self assert: code notNil.
    self assert: (code includesSubstring: 'feature time = 42').
    self assert: (code includesSubstring: 'feature steps = 10').
    self deny: (code includesSubstring: '.slots').
    
    Transcript
        show: '✓ Test passed: Minimal export';
        cr.
    
    ^ code
]

{ #category : 'testing' }
KerMLExporterTestCase >> testPolygonExport [
    "Test different polygon representations"
    | mission exporter sim code geoPoints |
    sim := SimulationState new.
    
    "Test 1: Polygon as GeoPoint collection"
    geoPoints := {
        GeoPoint new latitude: 48.0; longitude: 2.0; altitude: 100; yourself.
        GeoPoint new latitude: 49.0; longitude: 3.0; altitude: 100; yourself.
        GeoPoint new latitude: 50.0; longitude: 4.0; altitude: 100; yourself.
    }.
    
    mission := SecurizationMission new.
    mission id: 'M1'.
    mission polygon: geoPoints.
    sim missions: (OrderedCollection with: mission).
    
    exporter := KerMLExporter new.
    code := exporter generateFromSimulationState: sim.
    
    self assert: (code includesSubstring: 'feature polygon : MissionsModel::Polygon').
    self assert: (code includesSubstring: 'feature vertices : CoreModel::GeoPoint').
    self assert: (code includesSubstring: 'feature latitude = 48').
    
    Transcript
        show: '✓ Test passed: Polygon export';
        cr.
    
    ^ code
]
