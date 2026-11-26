"
Plan reproductible de retraits, d’arrivées et de changements de capteurs
dans une simulation macro. Le document contient seed et events. Chaque
règle porte un kind et soit un tick fixe, soit fromTick, toTick et count.
Les bornes de tirage sont inclusives et les tiks peuvent se répéter.

    plan := SoSeAtelierFleetSchedule readFrom: 'exemples/plan-evenements.json'.
    realization := plan scheduleOn: simulator through: 140.
    SoSeAtelierFleetSchedule writeRealization: realization into: output.

Le plan utilise un générateur privé. Au même tik, le simulateur applique
les retraits, les arrivées puis les réglages des capteurs. Le plan conserve
l’ordre des règles, puis l’ordre des tirages, pour départager ces phases.
Un retrait sans drone tire un identifiant actif. La position d’arrivée est
une abscisse de boucle et fait l’objet d’un tirage si elle est omise.
"
Class {
	#name : 'SoSeAtelierFleetSchedule',
	#superclass : 'Object',
	#instVars : [ 'seed', 'rules' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierFleetSchedule class >> fromJSON: document [
	^ self new initializeFrom: document
]

{ #category : 'files' }
SoSeAtelierFleetSchedule class >> readFrom: file [
	^ self fromJSON: (STONJSON fromString: file asFileReference contents)
]

{ #category : 'files' }
SoSeAtelierFleetSchedule class >> writeRealization: document into: directory [
	| output json csv columns |
	output := directory asFileReference ensureCreateDirectory.
	json := output / 'evenements-realises.json'.
	csv := output / 'evenements-realises.csv'.
	SoSeAtelierMissionFile write: document to: json.
	columns := #('tick' 'kind' 'drone' 'position' 'available' 'ruleIndex' 'drawIndex').
	csv writeStreamDo: [ :stream |
		| writer |
		writer := NeoCSVWriter on: stream.
		writer writeHeader: columns.
		(document at: 'events') do: [ :event |
			writer nextPut: (columns collect: [ :name | event at: name ]) ] ].
	^ { json. csv }
]

{ #category : 'initialization' }
SoSeAtelierFleetSchedule >> initializeFrom: document [
	| events |
	(document isKindOf: Dictionary) ifFalse: [ self error: 'Le plan d’événements doit être un objet JSON.' ].
	seed := document at: 'seed' ifAbsent: [ nil ].
	(seed isInteger and: [ seed > 0 ]) ifFalse: [ self error: 'Le plan exige une graine entière positive.' ].
	events := document at: 'events' ifAbsent: [ nil ].
	events isArray ifFalse: [ self error: 'Le plan exige un tableau events.' ].
	rules := events withIndexCollect: [ :rule :index | self validatedRule: rule at: index ]
]

{ #category : 'serializing' }
SoSeAtelierFleetSchedule >> asJSON [
	^ { 'seed' -> seed. 'events' -> (rules collect: #copy) } asDictionary
]

{ #category : 'validation' }
SoSeAtelierFleetSchedule >> validatedRule: rule at: index [
	| kind fixed first last count allowed id |
	(rule isKindOf: Dictionary) ifFalse: [ self invalidRule: index because: 'objet JSON attendu.' ].
	kind := rule at: 'kind' ifAbsent: [ nil ].
	allowed := #('kind' 'tick' 'fromTick' 'toTick' 'count'), (kind caseOf: {
		[ 'withdrawal' ] -> [ #('drone') ].
		[ 'arrival' ] -> [ #('position') ].
		[ 'distance' ] -> [ #('drone' 'available') ].
		[ 'vision' ] -> [ #('drone' 'available') ] }
		otherwise: [ self invalidRule: index because: 'kind doit être withdrawal, arrival, distance ou vision.' ]).
	(rule keys allSatisfy: [ :key | allowed includes: key ])
		ifFalse: [ self invalidRule: index because: 'champ inconnu ou incompatible avec le type d’événement.' ].
	fixed := rule includesKey: 'tick'.
	(fixed and: [ #('fromTick' 'toTick' 'count') anySatisfy: [ :key | rule includesKey: key ] ])
		ifTrue: [ self invalidRule: index because: 'utilise tick ou la plage fromTick/toTick/count.' ].
	first := rule at: (fixed ifTrue: [ 'tick' ] ifFalse: [ 'fromTick' ]) ifAbsent: [ nil ].
	last := fixed ifTrue: [ first ] ifFalse: [ rule at: 'toTick' ifAbsent: [ nil ] ].
	count := rule at: 'count' ifAbsent: [ 1 ].
	(first isInteger and: [ first > 0 and: [ last isInteger and: [ last >= first ] ] ])
		ifFalse: [ self invalidRule: index because: 'les tiks sont des entiers positifs et la plage doit être croissante.' ].
	(count isInteger and: [ count > 0 ])
		ifFalse: [ self invalidRule: index because: 'count doit être un entier positif.' ].
	id := rule at: 'drone' ifAbsent: [ nil ].
	(id isNil or: [ id isInteger and: [ id >= 0 ] ])
		ifFalse: [ self invalidRule: index because: 'drone doit être un identifiant entier positif ou nul.' ].
	(#('distance' 'vision') includes: kind) ifTrue: [
		(#(true false) includes: (rule at: 'available' ifAbsent: [ nil ]))
			ifFalse: [ self invalidRule: index because: 'available doit être true ou false.' ] ].
	(rule at: 'position' ifAbsent: [ nil ]) ifNotNil: [ :position |
		(position isNumber and: [ position asFloat isFinite and: [ position >= 0 ] ])
			ifFalse: [ self invalidRule: index because: 'la position d’arrivée doit être une abscisse positive ou nulle.' ] ].
	^ rule copy
]

{ #category : 'validation' }
SoSeAtelierFleetSchedule >> invalidRule: index because: reason [
	self error: 'Règle ', index printString, ' du plan d’événements. ', reason
]

{ #category : 'validation' }
SoSeAtelierFleetSchedule >> verifySimulator: simulator through: finalTick [
	| now range |
	now := simulator current timeStep.
	(finalTick isInteger and: [ finalTick >= now ])
		ifFalse: [ self error: 'L’horizon événementiel doit être un tik entier au moins égal au tik courant.' ].
	({ simulator losses. simulator incomers. simulator events } anySatisfy: [ :queue |
		queue keys anySatisfy: [ :tick | tick > now ] ])
		ifTrue: [ self error: 'Installe le plan avant tout autre événement futur.' ].
	range := simulator current range.
	(range isNumber and: [ range asFloat isFinite and: [ range > 0 ] ])
		ifFalse: [ self error: 'Le parcours exige une longueur positive.' ].
	simulator current drones ifEmpty: [ self error: 'Le plan exige une flotte initiale.' ]
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> scheduleOn: simulator through: finalTick [
	| document events |
	document := self realizeFor: simulator through: finalTick.
	events := document at: 'events'.
	events do: [ :event | self install: event on: simulator ].
	^ document
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> realizeFor: simulator through: finalTick [
	| generator pending active resolved nextId |
	self verifySimulator: simulator through: finalTick.
	generator := Random seed: seed.
	pending := self eventsFrom: simulator current timeStep through: finalTick using: generator.
	active := (simulator current drones collect: #id) asSortedCollection.
	nextId := simulator current maxID max: active last + 1.
	resolved := pending collect: [ :event |
		| kind index target tick |
		kind := event at: 'kind'.
		tick := event at: 'tick'.
		index := event at: 'ruleIndex'.
		target := event at: 'drone'.
		kind caseOf: {
			[ 'withdrawal' ] -> [
				active size > 1 ifFalse: [
					self invalidRule: index because: 'un retrait laisserait la flotte vide au tik ', tick printString, '.' ].
				target ifNil: [ target := active at: ((generator next * active size) floor + 1) ].
				self require: target in: active at: tick rule: index.
				active remove: target.
				event at: 'drone' put: target ].
			[ 'arrival' ] -> [
				| position perimeter |
				perimeter := simulator current range.
				position := (event at: 'position') ifNil: [ generator next * perimeter ].
				position < perimeter ifFalse: [
					self invalidRule: index because: 'la position d’arrivée doit être inférieure au périmètre.' ].
				event at: 'position' put: position; at: 'drone' put: nextId.
				active add: nextId.
				nextId := nextId + 1 ] }
			otherwise: [ target ifNotNil: [ self require: target in: active at: tick rule: index ] ].
		event ].
	^ { 'format' -> 'sose-atelier-fleet-realization'. 'version' -> 1. 'seed' -> seed.
		'throughTick' -> finalTick. 'events' -> resolved asArray } asDictionary
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> require: id in: active at: tick rule: index [
	(active includes: id) ifFalse: [
		self invalidRule: index because: 'drone ', id printString, ' absent au tik ', tick printString, '.' ]
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> eventsFrom: firstTick through: finalTick using: generator [
	| events |
	events := SortedCollection sortBlock: [ :left :right | self event: left precedes: right ].
	rules withIndexDo: [ :rule :index |
		| fixed low high count |
		fixed := rule at: 'tick' ifAbsent: [ nil ].
		low := fixed ifNil: [ rule at: 'fromTick' ].
		high := fixed ifNil: [ rule at: 'toTick' ].
		(low > firstTick and: [ high <= finalTick ]) ifFalse: [
			self invalidRule: index because: 'tous les tiks doivent être futurs et compris dans l’horizon.' ].
		count := rule at: 'count' ifAbsent: [ 1 ].
		1 to: count do: [ :draw |
			| tick |
			tick := fixed ifNil: [ low + ((generator next * (high - low + 1)) floor) ].
			events add: ({
				'tick' -> tick. 'kind' -> (rule at: 'kind').
				'drone' -> (rule at: 'drone' ifAbsent: [ nil ]).
				'position' -> (rule at: 'position' ifAbsent: [ nil ]).
				'available' -> (rule at: 'available' ifAbsent: [ nil ]).
				'ruleIndex' -> index. 'drawIndex' -> draw } asDictionary) ] ].
	^ events asArray
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> event: left precedes: right [
	| leftTick rightTick leftPhase rightPhase leftRule rightRule |
	leftTick := left at: 'tick'.
	rightTick := right at: 'tick'.
	leftTick = rightTick ifFalse: [ ^ leftTick < rightTick ].
	leftPhase := self phaseOf: (left at: 'kind').
	rightPhase := self phaseOf: (right at: 'kind').
	leftPhase = rightPhase ifFalse: [ ^ leftPhase < rightPhase ].
	leftRule := left at: 'ruleIndex'.
	rightRule := right at: 'ruleIndex'.
	leftRule = rightRule ifFalse: [ ^ leftRule < rightRule ].
	^ (left at: 'drawIndex') < (right at: 'drawIndex')
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> phaseOf: kind [
	kind = 'withdrawal' ifTrue: [ ^ 1 ].
	kind = 'arrival' ifTrue: [ ^ 2 ].
	^ 3
]

{ #category : 'simulation' }
SoSeAtelierFleetSchedule >> install: event on: simulator [
	| target tick match |
	tick := event at: 'tick'.
	target := event at: 'drone'.
	match := [ :drone | target isNil or: [ drone id = target ] ].
	(event at: 'kind') caseOf: {
		[ 'withdrawal' ] -> [ simulator loose: target at: tick ].
		[ 'arrival' ] -> [
			| drone |
			drone := simulator parameters generateDrone.
			drone id: target; position: (event at: 'position').
			simulator current maxID: target + 1.
			simulator enter: drone at: tick ].
		[ 'distance' ] -> [
			simulator scheduleDistanceMeasurementAvailable: (event at: 'available') at: tick matching: match ].
		[ 'vision' ] -> [
			simulator scheduleVisionAvailable: (event at: 'available') at: tick matching: match ] }
]
