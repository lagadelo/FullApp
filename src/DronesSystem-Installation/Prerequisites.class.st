"
This class has only one methos in class. 
It loads the prerequisite packages
"
Class {
	#name : 'Prerequisites',
	#superclass : 'Object',
	#category : 'DronesSystem-Installation',
	#package : 'DronesSystem-Installation'
}

{ #category : 'loading' }
Prerequisites class >> load [


Metacello new
  baseline: 'XMLParser';
  repository: 'github://pharo-contributions/XML-XMLParser/src';
  load.
Metacello new
  baseline: 'OWS';
  repository: 'github://ThalesGroup/PharoOWS:main';
  load.
]

{ #category : 'baselines' }
Prerequisites >> baseline: spec [

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
