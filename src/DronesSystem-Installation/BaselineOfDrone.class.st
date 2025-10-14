Class {
	#name : 'BaselineOfDrone',
	#superclass : 'BaselineOf',
	#category : 'DronesSystem-Installation',
	#package : 'DronesSystem-Installation'
}

{ #category : 'baselines' }
BaselineOfDrone >> baseline: spec [

	<baseline>
	spec
		baseline: 'XMLParser';
		repository: 'github://pharo-contributions/XML-XMLParser/src';
		load.
	spec
		baseline: 'OWS';
		repository: 'github://ThalesGroup/PharoOWS:main';
		load.
	spec
		baseline: 'CSV';
		repository: 'github://pharo-contributions/CSV:main/src';
		load.

	spec
		repository: 'git@github.com:lagadelo/FullApp.git/src';
		package: 'DroneSystem-Core';
		package: 'DroneSystem-Missions';
		package: 'DroneSystem-Simulation';
		package: 'DroneSystem-Demo';
		package: 'DroneSystem-Eval';
		package: 'DroneSystem-Examples';
		package: 'DroneSystem-Heuristics';
		package: 'DroneSystem-Simulation Events';
		package: 'DroneSystem-Simulation Strategy';
		package: 'DroneSystem-UI';
		package: 'DroneSystem-Utils';
		package: 'DroneSystem-Verification';
		package: 'DroneSystem-Visualization'
]
