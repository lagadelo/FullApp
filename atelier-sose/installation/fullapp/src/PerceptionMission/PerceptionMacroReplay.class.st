"
Rejoue un historique de MacroSimulator sur un parcours associé à un MNT. La géométrie et l’état des relevés appartiennent à PerceptionScene. Le simulateur reste responsable des drones, des vitesses et des événements.

Pour créer une simulation, configurer secondsPerTick avant newSimulatorWith:. Les vitesses de configuration sont en m/s et les distances en mètres. Avancer le simulateur par runSingleUpdate:. Pour un historique existant, secondsPerTick donne la durée simulée d’un tik.

"
Class {
	#name : 'PerceptionMacroReplay',
	#superclass : 'Object',
	#instVars : [
		'scene',
		'heightAt',
		'secondsPerTick',
		'displayOptions'
	],
	#category : 'PerceptionMission-Replay',
	#package : 'PerceptionMission',
	#tag : 'Replay'
}

{ #category : 'instance creation' }
PerceptionMacroReplay class >> example [ 

|replay sim | 
sim := MacroSimulatorExample example6b.
replay := (self
    vercorsFrom: FileLocator home / 'Downloads' / 'rejeu-vercors').
replay displayOptions
    at: #showCoverage put: false;
    at: #showRoute put: false;
    at: #lossMarkerSeconds put: 10; at: #droneColorMode put: "#acceleration" #speed.
   replay  playHistory: sim  history every: 5.
]

{ #category : 'instance creation' }
PerceptionMacroReplay class >> fromTerrain: aDirectory routeFile: aFile [

	| geometry features coordinates points |
	geometry := STONJSON fromString: aFile asFileReference contents.
	(geometry at: 'type') = 'FeatureCollection' ifTrue: [
			features := geometry at: 'features'.
			features size = 1 ifFalse: [
				self error: 'Le fichier doit contenir un seul parcours.' ].
			geometry := features first ].
	(geometry at: 'type') = 'Feature' ifTrue: [
		geometry := geometry at: 'geometry' ].
	coordinates := (geometry at: 'type')
		               caseOf: {
				               ([ 'Polygon' ]
				                -> [ (geometry at: 'coordinates') first ]).
				               ([ 'LineString' ] -> [ geometry at: 'coordinates' ]) }
		               otherwise: [
				               self error:
					               'Le parcours GeoJSON doit être un Polygon ou un LineString.' ].
	points := coordinates collect: [ :pair | pair first @ pair second ].
	^ self fromTerrain: aDirectory wayPoints: points
]

{ #category : 'instance creation' }
PerceptionMacroReplay class >> fromTerrain: aDirectory wayPoints: wayPoints [
	"Les sommets sont ordonnés et exprimés dans le repère d’entrée du terrain."

	| points |
	points := wayPoints collect: [ :wayPoint |
			          wayPoint isPoint
				          ifTrue: [ wayPoint ]
				          ifFalse: [ wayPoint longitude @ wayPoint latitude ] ].
	^ self on: (PerceptionScene on: aDirectory wayPoints: points)
]

{ #category : 'instance creation' }
PerceptionMacroReplay class >> on: aScene [

	^ self new
		  scene: aScene;
		  yourself
]

{ #category : 'instance creation' }
PerceptionMacroReplay class >> vercorsFrom: aDirectory [

	| directory |
	directory := aDirectory asFileReference.
	^ self
		  fromTerrain: directory / 'terrain-vercors'
		  routeFile: directory / 'parcours-vercors.geojson'
]

{ #category : 'configuration' }
PerceptionMacroReplay >> displayOptions [

	^ displayOptions
]

{ #category : 'replay' }
PerceptionMacroReplay >> exportHistory: aHistory every: stride into: aDirectory [

	| nextFrame directory view index |
	nextFrame := self frameReaderFor: aHistory every: stride.
	directory := (aDirectory asFileReference
	              / ('images-' , UUID new asString))
		             ensureCreateDirectory.
	index := 0.
	view := nextFrame value.
	[ view notNil ] whileTrue: [
			| file |
			file := directory
			        / ((index printString padLeftTo: 4 with: $0) , '.png').
			file binaryWriteStreamDo: [ :stream |
				(PNGReadWriter on: stream) nextPutImage: view asForm ].
			index := index + 1.
			view := nextFrame value ].
	^ directory
]

{ #category : 'replay' }
PerceptionMacroReplay >> frameReaderFor: aHistory every: stride [
    | history observe nextIndex tickSeconds |
    (stride isInteger and: [ stride > 0 ])
        ifFalse: [ self error: 'L’intervalle entre deux images doit être un entier positif.' ].
    history := aHistory asArray.
    history ifEmpty: [ self error: 'L’historique est vide.' ].
    tickSeconds := secondsPerTick.
    observe := scene observerWith: displayOptions
        heightAt: heightAt
        intrudersAt: [ :step | #() ]
        secondsPerTick: tickSeconds.
    nextIndex := 1.
    ^ [
        | end view |
        nextIndex <= history size ifTrue: [
            end := nextIndex = 1 ifTrue: [ 1 ] ifFalse: [ (nextIndex + stride - 1) min: history size ].
            nextIndex to: end do: [ :index |
                | step |
                step := history at: index.
                view := observe value: step value: step timeStep * tickSeconds ].
            nextIndex := end + 1 ].
        view ]

]

{ #category : 'configuration' }
PerceptionMacroReplay >> heightAboveGround: metres [

	(metres isNumber and: [ metres asFloat isFinite and: [ metres > 0 ] ])
		ifFalse: [
			self error:
				'La hauteur au-dessus du sol doit être positive et finie.' ].
	self heightAt: [ :step :drone | metres ]
]

{ #category : 'configuration' }
PerceptionMacroReplay >> heightAt: aBlock [
	"Le bloc reçoit le tik et le drone, et renvoie une hauteur au-dessus du sol en mètres."

	heightAt := aBlock
]

{ #category : 'initialization' }
PerceptionMacroReplay >> initialize [

	super initialize.
	secondsPerTick := 1.
	self heightAboveGround: 180.
	displayOptions := {
		                  (#background -> #hillshade).
		                  (#showDroneNames -> false).
		                  (#showSpeedColors -> true).
		                  (#lossMarkerSeconds -> 40).
		                  (#fadeAfterSeconds -> 16).
		                  (#transparentAfterSeconds -> 28) } asDictionary
]

{ #category : 'simulation' }
PerceptionMacroReplay >> newSimulatorWith: configure [

	| parameters minSpeed nominalSpeed maxSpeed |
	parameters := MacroSimulatorParameters new
		              numberOfDrones: 20;
		              totalDistance: self perimeterMeters;
		              minSpeed: 5;
		              nominalSpeed: 10;
		              maxSpeed: 15;
		              sensingRadius: 20;
		              captureRadius: 20;
		              policy: #capingPolicy;
		              seed: 3950149054165;
		              yourself.
	configure value: parameters.
	(parameters numberOfDrones isInteger and: [
		 parameters numberOfDrones > 0 ]) ifFalse: [
		self error: 'L’effectif doit être un entier positif.' ].
	minSpeed := parameters minSpeed.
	nominalSpeed := parameters nominalSpeed.
	maxSpeed := parameters maxSpeed.
	(({
		  minSpeed.
		  nominalSpeed.
		  maxSpeed } allSatisfy: [ :speed |
		  speed isNumber and: [ speed asFloat isFinite ] ]) and: [
			 minSpeed >= 0 and: [
					 nominalSpeed > 0 and: [
						 minSpeed <= nominalSpeed and: [ nominalSpeed <= maxSpeed ] ] ] ])
		ifFalse: [
				self error:
					'Les vitesses doivent respecter 0 ≤ min ≤ nominale ≤ max et nominale > 0.' ].
	"MacroSimulatorDrone >> update ajoute la vitesse à l’abscisse à chaque mouvement."
	parameters
		minSpeed: minSpeed * secondsPerTick;
		nominalSpeed: nominalSpeed * secondsPerTick;
		maxSpeed: maxSpeed * secondsPerTick.
	^ parameters initializeSimulator
]

{ #category : 'configuration' }
PerceptionMacroReplay >> perimeterMeters [

	^ scene perimeterMeters
]

{ #category : 'replay' }
PerceptionMacroReplay >> playHistory: aHistory every: stride [

	| nextFrame view animation lastFrame window extent |
	nextFrame := self frameReaderFor: aHistory every: stride.
	view := nextFrame value.
	extent := view canvas extent + (20 @ 40).
	lastFrame := Time millisecondClockValue.
	animation := view canvas newAnimation.
	animation
		repeat;
		onStepDo: [
				(Time millisecondsSince: lastFrame) >= 80 ifTrue: [
							nextFrame value
								ifNil: [ animation stop ]
								ifNotNil: [ :nextView | nextView refresh ].
							lastFrame := Time millisecondClockValue ] ].
	window := view open.
	window extent: extent.
	^ window
]

{ #category : 'initialization' }
PerceptionMacroReplay >> scene: aScene [

	scene := aScene
]

{ #category : 'configuration' }
PerceptionMacroReplay >> secondsPerTick: seconds [

	(seconds isNumber and: [
		 seconds asFloat isFinite and: [ seconds > 0 ] ]) ifFalse: [
		self error: 'La durée d’un tik doit être positive et finie.' ].
	secondsPerTick := seconds
]
