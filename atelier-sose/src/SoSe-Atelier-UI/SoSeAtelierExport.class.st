"
Exports de présentation. Le CSV lit l'historique de métriques macro.
La vidéo utilise les mêmes images et durées que la lecture de l'atelier.
"
Class {
	#name : 'SoSeAtelierExport',
	#superclass : 'Object',
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'exporting' }
SoSeAtelierExport class >> metrics: metrics fields: fields into: parent [
	| exporter directory passageFields |
	passageFields := fields select: [ :field | SoSeAtelierOptionsPresenter passageFields includes: field ].
	(passageFields notEmpty and: [ metrics history notEmpty and: [
		| sample |
		sample := metrics history first.
		passageFields anySatisfy: [ :field |
			(sample respondsTo: field) not or: [ (sample perform: field) isNil ] ] ] ])
		ifTrue: [ self error: 'Active le suivi de la fraîcheur des passages avant de simuler pour exporter ces colonnes.' ].
	directory := (parent asFileReference / ('metriques-', UUID new asString)) ensureCreateDirectory.
	exporter := MacroSimulatorResultExporter directoryName: directory.
	^ exporter exportHistoryCSV: metrics named: 'simulation' fields: fields
]

{ #category : 'exporting' }
SoSeAtelierExport class >> video: lecture into: parent [
	| directory timeline output log command status |
	(LibC system: 'command -v ffmpeg >/dev/null 2>&1') = 0
		ifFalse: [ self error: 'FFmpeg doit être accessible dans le PATH du processus Pharo.' ].
	directory := (parent asFileReference / ('demonstration-', UUID new asString)) ensureCreateDirectory.
	output := directory / 'demonstration.mp4'.
	log := directory / 'ffmpeg.log'.
	timeline := lecture exportImagesInto: directory.
	command := '/usr/bin/env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH ffmpeg -nostdin -v error -n -f concat -safe 0 -i ',
		(self quote: timeline fullName),
		' -fps_mode vfr -c:v libx264 -pix_fmt yuv420p -movflags +faststart ', (self quote: output fullName),
		' 2> ', (self quote: log fullName).
	status := LibC system: command.
	(status = 0 and: [ output isFile ])
		ifFalse: [ self error: 'FFmpeg a échoué. Diagnostic dans ', log fullName ].
	^ output
]

{ #category : 'private' }
SoSeAtelierExport class >> quote: string [
	| apostrophe escape |
	apostrophe := String with: $'.
	escape := String withAll: { $'. $". $'. $". $' }.
	^ apostrophe, (string copyReplaceAll: apostrophe with: escape), apostrophe
]
