Class {
	#name : 'MacroSimulatorResultExporter',
	#superclass : 'Object',
	#instVars : [
		'directory',
		'width',
		'height',
		'padding'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorResultExporter class >> directoryName: aDirectoryName [
	^ self new directory: aDirectoryName asFileReference; yourself
]

{ #category : 'accessing' }
MacroSimulatorResultExporter >> directory [
	^ directory ifNil: [ '.' asFileReference ]
]

{ #category : 'accessing' }
MacroSimulatorResultExporter >> directory: aFileReference [
	directory := aFileReference ensureCreateDirectory
]

{ #category : 'csv' }
MacroSimulatorResultExporter >> exportHistoryCSV: aMetricsHistory named: aBaseName [
	^ self exportHistoryCSV: aMetricsHistory named: aBaseName fields: self fieldsDefault
]

{ #category : 'csv' }
MacroSimulatorResultExporter >> exportHistoryCSV: aMetricsHistory named: aBaseName fields: fields [
	| file |
	file := self fileNamed: aBaseName , '-timeseries.csv'.
	file writeStreamDo: [ :stream |
		| writer |
		writer := NeoCSVWriter on: stream.
		writer nextPut: fields.
		aMetricsHistory history do: [ :metric |
			writer nextPut: (fields collect: [ :field | metric perform: field ]) ] ].
	^ file
]

{ #category : 'csv' }
MacroSimulatorResultExporter >> exportIntervalsCSV: aMetricsHistory field: aField threshold: aThreshold named: aBaseName [
	| file intervals |
	intervals := aMetricsHistory intervalsOf: aField where: [ :v | v > aThreshold ].
	file := self fileNamed: aBaseName , '-' , aField asString , '-violations.csv'.
	file writeStreamDo: [ :stream |
		| writer |
		writer := NeoCSVWriter on: stream.
		writer nextPut: #( startTime endTime sampleCount elapsedTime ).
		intervals do: [ :interval |
			writer nextPut: { interval startTime. interval endTime. interval sampleCount. interval elapsedTime } ] ].
	^ file
]

{ #category : 'bundle' }
MacroSimulatorResultExporter >> exportRun: aSimulator named: aBaseName fields: chartFields [
	| history files |
	history := aSimulator evaluateMetrics.
	files := OrderedCollection new.
	files add: (self exportHistoryCSV: history named: aBaseName).
	chartFields do: [ :field |
		files add: (self exportSVG: history field: field named: aBaseName).
		files add: (self exportTikZ: history field: field named: aBaseName) ].
	^ files
]

{ #category : 'svg' }
MacroSimulatorResultExporter >> exportSVG: aMetricsHistory field: aField named: aBaseName [
	^ self exportSVG: aMetricsHistory field: aField named: aBaseName threshold: nil
]

{ #category : 'svg' }
MacroSimulatorResultExporter >> exportSVG: aMetricsHistory field: aField named: aBaseName threshold: aThresholdOrNil [
	| file points ranges minX maxX minY maxY plotWidth plotHeight scaleX scaleY polyline |
	points := self pointsFor: aMetricsHistory field: aField.
	points ifEmpty: [ ^ nil ].
	ranges := self rangeOf: points.
	minX := ranges first. maxX := ranges second. minY := ranges third. maxY := ranges fourth.
	plotWidth := self width - (2 * self padding).
	plotHeight := self height - (2 * self padding).
	scaleX := [ :x | self padding + ((x - minX) / (maxX - minX) * plotWidth) ].
	scaleY := [ :y | self height - self padding - ((y - minY) / (maxY - minY) * plotHeight) ].
	polyline := String streamContents: [ :s |
		points do: [ :p |
			s nextPutAll: (scaleX value: p x) asFloat printString;
				nextPut: $,;
				nextPutAll: (scaleY value: p y) asFloat printString;
				nextPut: Character space ] ].
	file := self fileNamed: aBaseName , '-' , aField asString , '.svg'.
	file writeStreamDo: [ :stream |
		stream
			nextPutAll: '<svg xmlns="http://www.w3.org/2000/svg" width="'; nextPutAll: self width asString;
			nextPutAll: '" height="'; nextPutAll: self height asString; nextPutAll: '" viewBox="0 0 ';
			nextPutAll: self width asString; nextPut: Character space; nextPutAll: self height asString; nextPutAll: '">'; cr;
			nextPutAll: '<rect width="100%" height="100%" fill="white"/>'; cr;
			nextPutAll: '<line x1="'; nextPutAll: self padding asString; nextPutAll: '" y1="'; nextPutAll: (self height - self padding) asString;
			nextPutAll: '" x2="'; nextPutAll: (self width - self padding) asString; nextPutAll: '" y2="'; nextPutAll: (self height - self padding) asString;
			nextPutAll: '" stroke="black" stroke-width="1"/>'; cr;
			nextPutAll: '<line x1="'; nextPutAll: self padding asString; nextPutAll: '" y1="'; nextPutAll: self padding asString;
			nextPutAll: '" x2="'; nextPutAll: self padding asString; nextPutAll: '" y2="'; nextPutAll: (self height - self padding) asString;
			nextPutAll: '" stroke="black" stroke-width="1"/>'; cr.
		aThresholdOrNil ifNotNil: [
			| ty |
			ty := scaleY value: aThresholdOrNil.
			stream nextPutAll: '<line x1="'; nextPutAll: self padding asString; nextPutAll: '" y1="'; nextPutAll: ty asFloat printString;
				nextPutAll: '" x2="'; nextPutAll: (self width - self padding) asString; nextPutAll: '" y2="'; nextPutAll: ty asFloat printString;
				nextPutAll: '" stroke="gray" stroke-dasharray="6,4"/>'; cr ].
		stream
			nextPutAll: '<polyline fill="none" stroke="black" stroke-width="2" points="'; nextPutAll: polyline; nextPutAll: '"/>'; cr;
			nextPutAll: '<text x="'; nextPutAll: (self width / 2) asString; nextPutAll: '" y="25" text-anchor="middle" font-family="sans-serif" font-size="16">';
			nextPutAll: aField asString; nextPutAll: '</text>'; cr;
			nextPutAll: '</svg>' ].
	^ file
]

{ #category : 'tikz' }
MacroSimulatorResultExporter >> exportTikZ: aMetricsHistory field: aField named: aBaseName [
	^ self exportTikZ: aMetricsHistory field: aField named: aBaseName threshold: nil
]

{ #category : 'tikz' }
MacroSimulatorResultExporter >> exportTikZ: aMetricsHistory field: aField named: aBaseName threshold: aThresholdOrNil [
	| file points |
	points := self pointsFor: aMetricsHistory field: aField.
	file := self fileNamed: aBaseName , '-' , aField asString , '.tex'.
	file writeStreamDo: [ :stream |
		stream nextPutAll: '% Requires \usepackage{pgfplots} and \pgfplotsset{compat=1.18}'; cr.
		stream nextPutAll: '\begin{tikzpicture}'; cr.
		stream nextPutAll: '\begin{axis}[xlabel={time step},ylabel={' , aField asString , '},grid=both]'; cr.
		stream nextPutAll: '\addplot+[mark=none] coordinates {'; cr.
		points do: [ :p |
			stream nextPutAll: '(' , p x printString , ',' , p y printString , ')'; cr ].
		stream nextPutAll: '};'; cr.
		aThresholdOrNil ifNotNil: [
			stream nextPutAll: '\addplot[dashed] coordinates {(' , points first x printString , ',' , aThresholdOrNil printString , ') (' , points last x printString , ',' , aThresholdOrNil printString , ')};'; cr ].
		stream nextPutAll: '\end{axis}'; cr.
		stream nextPutAll: '\end{tikzpicture}'; cr ].
	^ file
]

{ #category : 'private' }
MacroSimulatorResultExporter >> fieldsDefault [
	^ #( timeStep fleetSize minGap maxGap avgGap stdGap coverageRatio maxUncoveredGap totalUncoveredLength directPerceptionRatio angularPerceptionRatio unobservablePerceptionRatio outOfRangePerceptionRatio avgGapEstimationError maxGapEstimationError )
]

{ #category : 'files' }
MacroSimulatorResultExporter >> fileNamed: aName [
	^ (self directory / aName) ensureDelete; createFile; yourself
]

{ #category : 'accessing' }
MacroSimulatorResultExporter >> height [
	^ height ifNil: [ 420 ]
]

{ #category : 'accessing' }
MacroSimulatorResultExporter >> padding [
	^ padding ifNil: [ 55 ]
]

{ #category : 'private - charts' }
MacroSimulatorResultExporter >> pointsFor: aMetricsHistory field: aField [
	^ aMetricsHistory history collect: [ :metric |
		(metric timeStep ifNil: [ 0 ]) @ (metric perform: aField) asFloat ]
]

{ #category : 'private - charts' }
MacroSimulatorResultExporter >> rangeOf: points [
	| xs ys minX maxX minY maxY |
	xs := points collect: [ :p | p x ].
	ys := points collect: [ :p | p y ].
	minX := xs min asFloat.
	maxX := xs max asFloat.
	minY := ys min asFloat.
	maxY := ys max asFloat.
	maxX = minX ifTrue: [ maxX := minX + 1.0 ].
	maxY = minY ifTrue: [ maxY := minY + 1.0 ].
	^ { minX. maxX. minY. maxY }
]

{ #category : 'accessing' }
MacroSimulatorResultExporter >> width [
	^ width ifNil: [ 900 ]
]
