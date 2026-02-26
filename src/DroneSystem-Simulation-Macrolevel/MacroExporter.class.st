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

{ #category : 'actions' }
MacroExporter >> createFile: aFileName [

	self file: (self directory ifNotNil: [
				 (self directory fullName , '/' , aFileName) asFileReference
					 createFile ]).

	^ self file
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

{ #category : 'accessing' }
MacroExporter >> file [

	^ file
]

{ #category : 'accessing' }
MacroExporter >> file: anObject [

	file := anObject
]

{ #category : 'actions' }
MacroExporter >> repositoryName: aString [

	self repository: aString asFileReference ensureCreateDirectory.
	^ repository
]

{ #category : 'visiting' }
MacroExporter >> visit: anObject [

	^ anObject accept: self
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulator: aSimulator [

	| historyFile data fields parameters parametersFile |
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
				"labels""First line = column labels"addRawFields: fields. "accessors over lines"
			nw nextPutAll: data ].

	"Save Meta data"
	parametersFile := self createFile: 'parameters.csv'.
	parameters := self visit: aSimulator parameters.

	parametersFile writeStreamDo: [ :stream |
			| nw |
			nw := NeoCSVWriter on: stream.
			nw nextPutAll: parameters ]
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


	| tmp |
	tmp := OrderedCollection new.
	aDrone class instanceVariables do: [ :aVariable |
			| aVariableName |
			aVariableName := aVariable name.
			tmp
				add: aVariableName;
				add: (aDrone perform: aVariableName asSymbol) ].

	^ tmp
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorMetrics: aMetrics [

	^ aMetrics class instanceVariables collect: [ :aVariable |
			  | aVariableName |
			  aVariableName := aVariable name.

			  aMetrics perform: aVariableName asSymbol ]
]

{ #category : 'visiting' }
MacroExporter >> visitMacroSimulatorParameters: aParameters [

	| tmp |
	tmp := OrderedCollection new.
	tmp add:
		(aParameters class instanceVariables collect: [ :aVariable |
				 | aVariableName |
				 aVariableName := aVariable name ]).
	tmp add:
		(aParameters class instanceVariables collect: [ :aVariable |
			 aParameters perform: aVariable name asSymbol ]).
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
