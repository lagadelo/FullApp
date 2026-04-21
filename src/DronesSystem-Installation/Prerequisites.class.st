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
	"spec
		baseline: 'XMLParser';
		repository: 'github://pharo-contributions/XML-XMLParser/src';
		load."
"	spec
		baseline: 'OWS';
		repository: 'github://ThalesGroup/PharoOWS:main';
		load."
	Metacello new
		baseline: 'NeoCSV';
		repository: 'github://svenvc/NeoCSV/src';
		load.
Metacello new
		baseline: 'Roassal';
		"with: [ Metacello new "repository: 'github://pharo-graphics/Roassal/src' "]".
Metacello new
		baseline: 'Roassal3Exporters';
		repository: 'github://ObjectProfile/Roassal3Exporters';
		load.
]
