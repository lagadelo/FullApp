Class {
	#name : 'BaselineOfDrone',
	#superclass : 'BaselineOf',
	#classInstVars : [
		'spec'
	],
	#category : 'DronesSystem-Installation',
	#package : 'DronesSystem-Installation'
}

{ #category : 'baselines' }
BaselineOfDrone >> baseline: spec [

	<baseline>
 
	spec
		repository: 'git@github.com:lagadelo/FullApp.git/src';
		package: 'DroneSystem-Core';
		package: 'DroneSystem-Demo';
		package: 'DroneSystem-Examples';
		package: 'DroneSystem-Missions';
		package: 'DroneSystem-Simulation';
		package: 'DroneSystem-Simulation Events';
		package: 'DroneSystem-Simulation Strategy';
		package: 'DroneSystem-Strategies';
		package: 'DroneSystem-UI';
		package: 'DroneSystem-Utils';
		package: 'DroneSystem-Verification';
		package: 'DroneSystem-Installation'
]

{ #category : 'information' }
BaselineOfDrone >> howTo [

Metacello new
    baseline: 'FullApp';
    repository: 'github:/lagadelo/FullApp';
    load.
]
