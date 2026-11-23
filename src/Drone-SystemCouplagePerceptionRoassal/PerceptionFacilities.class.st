Class {
	#name : 'PerceptionFacilities',
	#superclass : 'Object',
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'as yet unclassified' }
PerceptionFacilities class >> dependencies [

	Metacello new
		baseline: 'OSSubprocess';
		repository:
			'github://pharo-contributions/OSSubprocess:master/repository';
		load
]

{ #category : 'meta-data' }
PerceptionFacilities class >> exportFromPath: aPath imagesNamed: aName from: startIndex to: stopIndex to: aFilename [

	| tmp imagesNames size |
	tmp := stopIndex log: 10.
	tmp = tmp ceiling
		ifTrue: [ size := tmp ceiling + 1 ]
		ifFalse: [ size := tmp ceiling ].

	imagesNames := aPath , '/' , aName , size printString , 'd.png'.
	OSSUnixSubprocess new
		command: 'ffmpeg';
		arguments:
			#( '-nostdin' '-n' '-framerate' '25' '-start_number'
			   '1' '-i' imagesNames '-c:v' 'libx264' '-pix_fmt' 'yuv420p'
			   aFileName );
		redirectStdout;
		redirectStderr;
		runAndWaitOnExitDo: [ :process :stdout :stderr |
				Transcript
					show: stderr;
					cr ]
]
