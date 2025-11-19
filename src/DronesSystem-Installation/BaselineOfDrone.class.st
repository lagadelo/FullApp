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
		baseline: 'XMLParser';
		repository: 'github://pharo-contributions/XML-XMLParser/src';
		load.
	spec
		baseline: 'OWS';
		repository: 'github://ThalesGroup/PharoOWS:main';
		load.
	spec
		baseline: 'NeoCSV';
		repository: 'github://svenvc/NeoCSV/src';
		load.
	spec
		baseline: 'Roassal'
		with: [ spec repository: 'github://pharo-graphics/Roassal/src' ].
	spec
		baseline: 'Roassal3Exporters';
		repository: 'github://ObjectProfile/Roassal3Exporters';
		load.
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
