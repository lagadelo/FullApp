Class {
	#name : 'BaselineOfDroneSystem',
	#superclass : 'BaselineOf',
	#category : 'DroneSystem-Installation',
	#package : 'DroneSystem-Installation'
}

{ #category : 'loading' }
BaselineOfDroneSystem class >> baseline: spec [
	<baseline>
	spec
		repository: 'git@github.com:lagadelo/FullApp.git/';
		package: 'DroneSystem-Core';
		package: 'DroneSystem-Demo';
		package: 'DroneSystem-Examples';
		package: 'DroneSystem-Missions';
		package: 'DroneSystem-Simulation';
		"		package: 'DroneSystem-Simulation Events';
		package: 'DroneSystem-Simulation Strategy';
		package: 'DroneSystem-Strategies';"
		package: 'DroneSystem-UI';
		package: 'DroneSystem-Utils';
		package: 'DroneSystem-Verification';
		package: 'DroneSystem-Installation'
]

{ #category : 'baselines' }
BaselineOfDroneSystem >> baseline: spec [
	<baseline>
	spec
		repository: 'git@github.com:lagadelo/FullApp.git';
		package: 'DroneSystem-Core';
	"	package: 'DroneSystem-Demo';
		package: 'DroneSystem-Examples';
		package: 'DroneSystem-Missions';
		package: 'DroneSystem-Simulation';"
		"		package: 'DroneSystem-Simulation Events';
		package: 'DroneSystem-Simulation Strategy';
		package: 'DroneSystem-Strategies';"
	"	package: 'DroneSystem-UI';
		package: 'DroneSystem-Utils';
		package: 'DroneSystem-Verification';"
		package: 'DroneSystem-Installation'
]
