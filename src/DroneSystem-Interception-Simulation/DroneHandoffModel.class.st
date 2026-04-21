"
DroneHandoffModel captures the model for high level monte carlo based simulation, i.e parameters:

tDetect — time to detect a target (seconds).
tClassify — time to classify/confirm target type (seconds).
tAlert — time to raise and route alert (seconds).
tAck — time for operator/system acknowledgment (seconds).
tHandoff — time to hand track/control to response asset (seconds).
tLaunch — launch/readiness delay before interceptor moves (seconds).
distanceKm — interceptor travel distance to intercept area (km).
speedKmh — interceptor speed used for transit time (km/h).
slaSeconds — maximum allowed total response latency (seconds).
Derived values

transitSeconds = 3600 * distanceKm / speedKmh
nominalTotalSeconds = tDetect + tClassify + tAlert + tAck + tHandoff + tLaunch + transitSeconds
isNominalOnTime = nominalTotalSeconds <= slaSeconds
DroneHandoffSimulation parameters

model — the baseline DroneHandoffModel.
sampleCount — number of Monte Carlo trials (e.g., 10,000).
results — per-trial outputs (totalSeconds, onTime).
random — RNG state.
Random variability (in runOneTrial)
"
Class {
	#name : 'DroneHandoffModel',
	#superclass : 'Object',
	#instVars : [
		'tDetect',
		'tClassify',
		'tAlert',
		'tAck',
		'tHandoff',
		'tLaunch',
		'distanceKm',
		'speedKmh',
		'slaSeconds'
	],
	#classInstVars : [
		'tDetect',
		'printReport',
		'tClassify',
		'tAlert',
		'tAck',
		'tHandoff',
		'tLaunch',
		'distanceKm',
		'speedKmh',
		'slaSeconds'
	],
	#category : 'DroneSystem-Interception-Simulation',
	#package : 'DroneSystem-Interception-Simulation'
}

{ #category : 'accessing' }
DroneHandoffModel class >> default [
    ^ self new
          initializeDefaults;
          yourself
]

{ #category : 'examples' }
DroneHandoffModel class >> example [
| model |
model := self default.
model distanceKm: 40.
model slaSeconds: 420.
model printReport.
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioBoundaryCondition [
	"Distance exactly at SLA edge."

	^ self new
		  tDetect: 15;
		  tClassify: 12;
		  tAlert: 4;
		  tAck: 10;
		  tHandoff: 12;
		  tLaunch: 20;
		  distanceKm: 20;
		  speedKmh: 100;
		  slaSeconds: 315;
		  "Knife-edge: fixed=73s, transit≈242s"yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioCoastalPatrol [
    "Coastal patrol: moderate latencies, longer distance, 5-minute SLA."
    ^ self new
        tDetect: 25;
        tClassify: 20;
        tAlert: 8;
        tAck: 15;
        tHandoff: 25;
        tLaunch: 40;
        distanceKm: 50;
        speedKmh: 130;
        slaSeconds: 300;
        yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioElbow [
    "Borderline SLA scenario to expose knees/cliffs in speed-distance curves."
    ^ self new
        tDetect: 18;
        tClassify: 12;
        tAlert: 6;
        tAck: 10;
        tHandoff: 14;
        tLaunch: 24;
        distanceKm: 20;
        speedKmh: 130;
        slaSeconds: 210;
        yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioKneeDemo [
    "Calibrated to place feasible distances around 10-22km where non-linear penalties activate."
    ^ self new
        tDetect: 16;
        tClassify: 11;
        tAlert: 6;
        tAck: 9;
        tHandoff: 13;
        tLaunch: 22;
        distanceKm: 15;
        speedKmh: 130;
        slaSeconds: 500;
        yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioTightIntercept [
    "Short distance, tight SLA — responsive intercept."
    ^ self new
        tDetect: 15;
        tClassify: 10;
        tAlert: 3;
        tAck: 8;
        tHandoff: 15;
        tLaunch: 20;
        distanceKm: 15;
        speedKmh: 150;
        slaSeconds: 300;
        yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioUltraTight [
    "Ultra-tight scenario: tight fixed latencies, short distance, very tight SLA."
    ^ self new
        tDetect: 15;
        tClassify: 10;
        tAlert: 5;
        tAck: 8;
        tHandoff: 12;
        tLaunch: 20;
        distanceKm: 10;
        speedKmh: 130;
        slaSeconds: 150;
        yourself
]

{ #category : 'as yet unclassified' }
DroneHandoffModel class >> scenarioUrgentIntercept [
    "Urgent intercept: tight latencies, medium distance, very tight SLA."
    ^ self new
        tDetect: 20;
        tClassify: 15;
        tAlert: 5;
        tAck: 12;
        tHandoff: 18;
        tLaunch: 25;
        distanceKm: 30;
        speedKmh: 130;
        slaSeconds: 250;
        yourself
]

{ #category : 'initialization' }
DroneHandoffModel >> asDictionary [
    ^ Dictionary new
          at: #tDetect put: tDetect;
          at: #tClassify put: tClassify;
          at: #tAlert put: tAlert;
          at: #tAck put: tAck;
          at: #tHandoff put: tHandoff;
          at: #tLaunch put: tLaunch;
          at: #distanceKm put: distanceKm;
          at: #speedKmh put: speedKmh;
          at: #slaSeconds put: slaSeconds;
          at: #transitSeconds put: self transitSeconds;
          at: #totalSeconds put: self totalSeconds;
          at: #onTime put: self isOnTime;
          yourself
]

{ #category : 'accessing' }
DroneHandoffModel >> distanceKm [

	^ distanceKm
]

{ #category : 'initialization' }
DroneHandoffModel >> distanceKm: aNumber [
    distanceKm := aNumber asFloat
]

{ #category : 'initialization' }
DroneHandoffModel >> initializeDefaults [

	tDetect := 20.0.
	tClassify := 15.0.
	tAlert := 5.0.
	tAck := 10.0.
	tHandoff := 20.0.
	tLaunch := 30.0.
	distanceKm := 25.0.
	speedKmh := 130.0.
	slaSeconds := 900.0
]

{ #category : 'testing' }
DroneHandoffModel >> isOnTime [
    ^ self totalSeconds <= slaSeconds
]

{ #category : 'initialization' }
DroneHandoffModel >> printReport [
    Transcript
        cr;
        show: '=== Drone Handoff Report ==='; cr;
        show: 'Detect      : ', tDetect asString, ' s'; cr;
        show: 'Classify    : ', tClassify asString, ' s'; cr;
        show: 'Alert       : ', tAlert asString, ' s'; cr;
        show: 'Ack         : ', tAck asString, ' s'; cr;
        show: 'Handoff     : ', tHandoff asString, ' s'; cr;
        show: 'Launch      : ', tLaunch asString, ' s'; cr;
        show: 'Distance    : ', distanceKm asString, ' km'; cr;
        show: 'Speed       : ', speedKmh asString, ' km/h'; cr;
        show: 'Transit     : ', (self transitSeconds printShowingDecimalPlaces: 1), ' s'; cr;
        show: 'Total       : ', (self totalSeconds printShowingDecimalPlaces: 1), ' s'; cr;
        show: 'SLA         : ', slaSeconds asString, ' s'; cr;
        show: 'On time     : ', self isOnTime asString; cr;
        show: '==========================='; cr
]

{ #category : 'accessing' }
DroneHandoffModel >> slaSeconds [

	^ slaSeconds
]

{ #category : 'initialization' }
DroneHandoffModel >> slaSeconds: aNumber [
    slaSeconds := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> speedKmh [

	^ speedKmh
]

{ #category : 'initialization' }
DroneHandoffModel >> speedKmh: aNumber [
    speedKmh := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tAck [

	^ tAck
]

{ #category : 'initialization' }
DroneHandoffModel >> tAck: aNumber [
    tAck := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tAlert [

	^ tAlert
]

{ #category : 'initialization' }
DroneHandoffModel >> tAlert: aNumber [
    tAlert := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tClassify [

	^ tClassify
]

{ #category : 'initialization' }
DroneHandoffModel >> tClassify: aNumber [
    tClassify := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tDetect [

	^ tDetect
]

{ #category : 'initialization' }
DroneHandoffModel >> tDetect: aNumber [
    tDetect := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tHandoff [

	^ tHandoff
]

{ #category : 'accessing' }
DroneHandoffModel >> tHandoff1: anObject [

	tHandoff := anObject
]

{ #category : 'initialization' }
DroneHandoffModel >> tHandoff: aNumber [
    tHandoff := aNumber asFloat
]

{ #category : 'accessing' }
DroneHandoffModel >> tLaunch [

	^ tLaunch
]

{ #category : 'accessing' }
DroneHandoffModel >> tLaunch1: anObject [

	tLaunch := anObject
]

{ #category : 'initialization' }
DroneHandoffModel >> tLaunch: aNumber [
    tLaunch := aNumber asFloat
]

{ #category : 'initialization' }
DroneHandoffModel >> totalSeconds [

	^ tDetect + tClassify + tAlert + tAck + tHandoff + tLaunch
	  + self transitSeconds
]

{ #category : 'initialization' }
DroneHandoffModel >> transitSeconds [
    ^ 3600.0 * (distanceKm / speedKmh)
]
