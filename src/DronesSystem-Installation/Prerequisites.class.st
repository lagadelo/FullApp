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
