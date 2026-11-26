"
Exécute le bloc éditable du scénario sur l'image Pharo. Les valeurs de
simulation sont prises au lancement. Le temps d'un tik est exprimé en secondes,
les vitesses de configuration en m/s.
"
Class {
	#name : 'SoSeAtelierSimulation',
	#superclass : 'Object',
	#instVars : [ 'terrain', 'settings' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierSimulation class >> terrain: aTerrain settings: options [
	^ self new initializeTerrain: aTerrain settings: options
]

{ #category : 'initialization' }
SoSeAtelierSimulation >> initializeTerrain: aTerrain settings: options [
	terrain := aTerrain.
	settings := options copy
]

{ #category : 'configuration' }
SoSeAtelierSimulation class >> commandChoices [
	^ { #revisedCapingPolicy -> 'Capping révisé'. #capingPolicy -> 'Capping'.
		#revisitCapingPolicy -> 'Capping avec revisite' }
]

{ #category : 'configuration' }
SoSeAtelierSimulation class >> perceptionChoices [
	^ { #scenario -> 'Selon le scénario'. #distance -> 'Distance seule'.
		#bearing -> 'Gisement seul'. #hybrid -> 'Distance puis gisement' }
]

{ #category : 'scenarios' }
SoSeAtelierSimulation class >> scenarios [
	| examples |
	examples := (MacroSimulatorExample class selectors select: [ :selector |
		selector numArgs = 0 and: [ selector beginsWith: 'example' ] ]) asSortedCollection.
	^ { #vercors -> 'Vercors'. #geographic -> 'Parcours cartographié'.
		#sose -> 'SoSe paramétrable'. #soseLegacy -> 'SoSe historique'. #isse -> 'ISSe historique' }
		, (examples collect: [ :selector | selector -> ('MacroSimulatorExample ', selector) ]) asArray
]

{ #category : 'scenarios' }
SoSeAtelierSimulation class >> sourceFor: scenario [
	scenario = #geographic ifTrue: [
		^ '[ :atelier |
	| simulateur |
	simulateur := atelier simulateurSurParcours.
	simulateur runSingleUpdate: atelier nombreTiks.
	simulateur ]' ].
	scenario = #soseLegacy ifTrue: [ ^ '[ :atelier | FullAppMacroReplay soSe ]' ].
	scenario = #vercors ifTrue: [
		^ '[ :atelier |
	| exemple simulateur |
	exemple := atelier exempleVercors.
	simulateur := exemple newSimulatorWith: [ :parametres |
		atelier configurer: parametres ].
	atelier configurerPerceptionDe: simulateur.
	exemple scheduleOutageOn: simulateur.
	simulateur runSingleUpdate: atelier nombreTiks.
	simulateur ]' ].
	scenario = #sose ifTrue: [
		^ '[ :atelier |
	| simulateur |
	simulateur := atelier simulateurEnAnneau.
	simulateur behavior sensibility: 0.01; pacingRate: 0.9.
	simulateur loose: 1 at: 200.
	simulateur loose: 30 at: 500.
	simulateur loose: 80 at: 800.
	simulateur newIncomerAt: 500.
	simulateur newIncomerAt: 500.
	simulateur newIncomerAt: 1000.
	atelier avancerAnneau: simulateur.
	simulateur ]' ].
	scenario = #isse ifTrue: [
		^ '[ :atelier |
	| simulateur |
	simulateur := MacroSimulatorExample generateScenario: atelier indiceISSe.
	atelier appliquerRevisiteA: simulateur.
	simulateur run: atelier nombreTiks.
	simulateur ]' ].
	^ (MacroSimulatorExample class >> scenario) sourceCode
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> runSource: source [
	^ MacroSimulatorFreshnessScope
		value: (settings at: #maxDate ifAbsent: [ MacroSimulatorFreshnessScope value ])
		during: [ self evaluateSource: source ]
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> evaluateSource: source [
	| block |
	(source trimLeft beginsWith: '[') ifFalse: [ ^ self runLegacyMethod: source ].
	block := Smalltalk compiler evaluate: source.
	(block isBlock and: [ block numArgs = 1 ])
		ifFalse: [ self error: 'Le code doit être un bloc Smalltalk [ :atelier | … ].' ].
	^ block value: self
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> runLegacyMethod: source [
	| method |
	method := MacroSimulatorExample class compiler source: source; compile.
	method numArgs = 0
		ifFalse: [ self error: 'Une méthode d’exemple doit être sans argument.' ].
	^ method valueWithReceiver: MacroSimulatorExample arguments: #()
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> configurer: parameters [
	| low nominal high |
	low := settings at: #minSpeed.
	nominal := settings at: #nominalSpeed.
	high := settings at: #maxSpeed.
	(low >= 0 and: [ nominal > 0 and: [ low <= nominal and: [ nominal <= high ] ] ])
		ifFalse: [ self error: 'Règle les vitesses dans l’ordre min ≤ nominale ≤ max.' ].
	parameters
		numberOfDrones: (settings at: #numberOfDrones);
		minSpeed: low;
		nominalSpeed: nominal;
		maxSpeed: high;
		sensingRadius: (settings at: #sensingRadius);
		captureRadius: (settings at: #captureRadius);
		seed: (settings at: #seed);
		policy: (settings at: #policy);
		revisitTargetSeconds: self objectifRevisite;
		secondsPerTick: self secondesParTik.
	settings at: #maxDate ifPresent: [ :duration | parameters maxDate: duration ]
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> configurerPerceptionDe: simulator [
	| mode |
	mode := settings at: #perceptionMode ifAbsent: [ #scenario ].
	mode = #scenario ifTrue: [ ^ self ].
	simulator parameters wayPoints ifNil: [ self error: 'Ce modèle de perception exige un parcours plan, réel ou synthétique.' ].
	simulator perceptionModel: (SoSeAtelierNeighborPerception mode: mode
		halfAngle: (settings at: #bearingHalfAngle ifAbsent: [ 180 ]))
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> configurerCommandeDe: simulator [
	| law weight |
	weight := settings at: #distanceWeight ifAbsent: [ 2 ].
	(weight isNumber and: [ weight between: 0 and: 10 ])
		ifFalse: [ self error: 'Le poids des écarts doit être compris entre 0 et 10.' ].
	law := settings at: #commandLaw ifAbsent: [ nil ].
	(weight = 2 and: [ law isNil or: [ law isOriginal ] ]) ifTrue: [ ^ self ].
	law ifNil: [
		law := SoSeAtelierCommandLaw presets detect: [ :preset | preset id = simulator behavior policy ]
			ifNone: [ self error: 'Le poids des écarts exige une loi du catalogue.' ] ].
	simulator behavior: ((SoSeAtelierLocalBehavior using: law settingsOf: simulator behavior)
		distanceWeight: weight; yourself)
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> appliquerRevisiteA: simulator [
	| target seconds |
	target := self objectifRevisite.
	seconds := self secondesParTik.
	simulator parameters revisitTargetSeconds: target; secondsPerTick: seconds.
	simulator current drones do: [ :drone | drone revisitTargetSeconds: target; secondsPerTick: seconds ]
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> avancerAnneau: simulator [
	self configurerCommandeDe: simulator.
	(simulator behavior policy = #revisitCapingPolicy or: [ simulator behavior isKindOf: SoSeAtelierLocalBehavior ])
		ifTrue: [ simulator runSingleUpdate: self nombreTiks ]
		ifFalse: [ simulator run: self nombreTiks ]
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> exempleVercors [
	| example |
	example := SoSeAtelierGeographicExample on: terrain newReplay.
	example recipe: self.
	example replay secondsPerTick: self secondesParTik.
	^ example
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> simulateurSurParcours [
	| replay simulator |
	replay := terrain newReplay.
	replay secondsPerTick: self secondesParTik.
	simulator := replay newSimulatorWith: [ :parameters |
		parameters wayPoints: replay projectedWayPoints.
		self configurer: parameters ].
	simulator behavior sensibility: 0.01; pacingRate: 0.9.
	simulator perceptionModel: MacroSimulatorHybridPerception new.
	self configurerCommandeDe: simulator.
	self configurerPerceptionDe: simulator.
	^ simulator
]

{ #category : 'simulation' }
SoSeAtelierSimulation >> simulateurEnAnneau [
	| parameters seconds |
	parameters := MacroSimulatorParameters new totalDistance: self longueurAnneau; yourself.
	self configurer: parameters.
	seconds := self secondesParTik.
	parameters
		minSpeed: parameters minSpeed * seconds;
		nominalSpeed: parameters nominalSpeed * seconds;
		maxSpeed: parameters maxSpeed * seconds.
	^ parameters initializeSimulator
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> longueurAnneau [
	^ 10000
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> longueurPour: scenario [
	^ scenario caseOf: {
		[ #vercors ] -> [ self exempleVercors replay perimeterMeters ].
		[ #geographic ] -> [ terrain newReplay perimeterMeters ].
		[ #sose ] -> [ self longueurAnneau ] }
		otherwise: [ self error: 'L’estimation utilise un scénario avec une flotte paramétrable.' ]
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> objectifRevisite [
	^ settings at: #revisitTargetSeconds ifAbsent: [ nil ]
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> nombreTiks [
	^ settings at: #ticks
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> secondesParTik [
	^ settings at: #tickSeconds
]

{ #category : 'accessing' }
SoSeAtelierSimulation >> indiceISSe [
	^ settings at: #seedIndex
]
