Class {
	#name : 'MacroExporter',
	#superclass : 'Object',
	#instVars : [
		'file',
		'repository',
		'directory'
	],
	#category : 'DroneSystem-Simulation-Macrolevel',
	#package : 'DroneSystem-Simulation-Macrolevel'
}

{ #category : 'visiting' }
MacroExporter class >> directoryName: aName [

	^ self new
		  directoryName: aName;
		  yourself
]

{ #category : 'visiting' }
MacroExporter class >> visit: anObject [

^self new visit: anObject 
]

{ #category : 'visiting' }
MacroExporter >> columnNamesFor: aClass [

	^ aClass instanceVariables collect: [ :aVariable |
			  | aVariableName |
			  aVariableName := aVariable name ]
]

{ #category : 'actions' }
MacroExporter >> createFile: aFileName [

	self file: (self directory ifNotNil: [
				 (self directory fullName , '/' , aFileName) asFileReference
					 createFile ]).

	^ self file
]

{ #category : 'visiting' }
MacroExporter >> defaultExport: anObject [

	^ (self columnNamesFor: anObject class) collect: [ :aVariableName |
		  anObject perform: aVariableName asSymbol ]
]

{ #category : 'actions' }
MacroExporter >> deleteFile: aFileName [

	self directory ifNotNil: [
			(self directory fullName , '/' , aFileName) asFileReference
				deleteIfAbsent: [ ] ]
]

{ #category : 'actions' }
MacroExporter >> directory [

	directory ifNil: [
			self repository: (UIManager default chooseDirectory:
					 'Select directory of the collection') ].
	^ directory
]

{ #category : 'accessing' }
MacroExporter >> directory: anObject [

	directory := anObject
]

{ #category : 'actions' }
MacroExporter >> directoryName: aString [

	self directory: aString asFileReference ensureCreateDirectory.
	^ directory
]

{ #category : 'use case specific' }
MacroExporter >> extractMacroMetricsOutOf: data [

	| s e |
	s := (1 to: data size) detect: [ :i |
		     ((data at: i) = (data at: i + 1)) not ].
	e := (s to: data size - 1) detect: [ :i |
		     (data at: i) = (data at: i + 1) ].
	^ Array with: s with: e
]

{ #category : 'accessing' }
MacroExporter >> file [

	^ file
]

{ #category : 'accessing' }
MacroExporter >> file: anObject [

	file := anObject
]

{ #category : 'visiting' }
MacroExporter >> metaMetrics [ 
	| data aSimulator s e |
	data := self visit: aSimulator evaluateMetrics.
	s := (1 to: data size) detect: [ :i |
		     (data at: i) = (data at: i + 1) not ].
	e := (s to: data size) detect: [ :i |
		     (data at: i) = (data at: i + 1) ].

 
]

{ #category : 'actions' }
MacroExporter >> repositoryName: aString [

	self repository: aString asFileReference ensureCreateDirectory.
	^ repository
]

{ #category : 'visiting' }
MacroExporter >> saveDataOf: aSimulator [

	| historyFile data fields |
	"Save Data"
	historyFile := self createFile:
		               aSimulator behavior exportName , '.csv'.
	data := self visit: aSimulator evaluateMetrics.

	historyFile writeStreamDo: [ :stream |
			| nw |
			nw := NeoCSVWriter on: stream.
			fields := data removeFirst.
			nw
				nextPut: fields;
				addRawFields: fields. "accessors over lines"
			nw nextPutAll: data ].
	^ data
]

{ #category : 'visiting' }
MacroExporter >> saveMacroMetricsOutOf: data [

	| s e |
	s := (1 to: self data size) detect: [ :i |
		     ((self data at: i) = (self data at: i + 1)) not ].
	e := (s to: self data size) detect: [ :i |
		     ((self data at: i) = (self data at: i + 1)) not ].
	^ Array with: s with: e
]

{ #category : 'visiting' }
MacroExporter >> saveParametersOf: aSimulator [

	| parameters parametersFile |
	"Save Meta data"
	parametersFile := self createFile: 'parameters.csv'.
	parameters := self visit: aSimulator parameters.

	parametersFile writeStreamDo: [ :stream |
			| nw |
			nw := NeoCSVWriter on: stream.
			nw nextPutAll: parameters ]
]

{ #category : 'visiting' }
MacroExporter >> saveScenarioOf: aSimulator [

	| tmp parametersFile scenario |
	"Save Meta data"
	scenario := aSimulator scenario.
	scenario ifEmpty: [ ^ self ].
	self deleteFile: 'scenario.csv'.
	parametersFile := self createFile: 'scenario.csv'.

	tmp := (OrderedCollection with: #timeStamp)
	       , (self columnNamesFor: scenario first last class).

	parametersFile writeStreamDo: [ :stream |
			| nw |
			nw := NeoCSVWriter on: stream.

			nw nextPut: tmp.
			aSimulator scenario do: [ :anEvent |
					nw nextPut:
						(OrderedCollection with: anEvent first)
						, (self visit: anEvent last) ] ]
]

{ #category : 'visiting' }
MacroExporter >> visit: anObject [

	^ anObject accept: self
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulator: aSimulator [

	| data |
	"Save Meta data"
	self saveParametersOf: aSimulator.
	"Save incoming and lost drones"
	self saveScenarioOf: aSimulator.
	"Save Data"
	data := self saveDataOf: aSimulator.

	^ self extractMacroMetricsOutOf: data
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorBehavior: aBehavior [


	| tmp |
	tmp := OrderedCollection new.
	aBehavior class instanceVariables do: [ :aVariable |
			| aVariableName |
			aVariableName := aVariable name.
			tmp
				add: aVariableName;
				add: (aBehavior perform: aVariableName asSymbol) ].

	^ tmp
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorDrone: aDrone [

	^ self defaultExport: aDrone
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorMetrics: aMetrics [

	^ self defaultExport: aMetrics
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorParameters: aParameters [

	| tmp |
	tmp := OrderedCollection new.
	tmp add: (self columnNamesFor: aParameters class).
	tmp add: (self defaultExport: aParameters).
	^ tmp
]

{ #category : 'visiting' }
MacroExporter >> visitSimulatorMetricsHistory: aHistory [

	| tmp |
	aHistory initial ifNotNil: [
			tmp := OrderedCollection new.
			tmp add:
				(aHistory  initial class instanceVariables collect: [ :aVariable |
						 | aVariableName |
						 aVariableName := aVariable name ]).

			tmp addAll: "(aHistory history collect: [ :aMetricsAtATimeStep |
					 aMetricsAtATimeStep accept: self ]" aHistory history    .
			^ tmp ]
]
