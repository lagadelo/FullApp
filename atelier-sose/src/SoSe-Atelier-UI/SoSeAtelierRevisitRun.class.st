"
Indicateurs macro d’une exécution. Le délai par état est une estimation à
vitesse de commande constante, calculée sur l’espacement le long de la boucle.
Le seuil d’évaluation peut changer pendant l’analyse de l’historique.
"
Class {
	#name : 'SoSeAtelierRevisitRun',
	#superclass : 'Object',
	#instVars : [ 'caption', 'target', 'delays', 'lastGap', 'lastSpeed', 'direct', 'bearing', 'outOfRange', 'unavailable' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierRevisitRun class >> on: simulator metrics: report tickSeconds: seconds [
	^ self new initializeOn: simulator metrics: report tickSeconds: seconds
]

{ #category : 'initialization' }
SoSeAtelierRevisitRun >> initializeOn: simulator metrics: report tickSeconds: seconds [
	| samples model law mode |
	samples := report history.
	model := simulator perceptionModel.
	law := (simulator behavior isKindOf: SoSeAtelierLocalBehavior)
		ifTrue: [ simulator behavior lawName ]
		ifFalse: [ SoSeAtelierSimulation commandChoices asDictionary at: simulator behavior policy
			ifAbsent: [ simulator behavior policy asString ] ].
	mode := (model isKindOf: MacroSimulatorSelectablePerception)
		ifTrue: [ SoSeAtelierSimulation perceptionChoices asDictionary at: model mode ]
		ifFalse: [ (model isKindOf: MacroSimulatorHybridPerception)
			ifTrue: [ 'Distance puis gisement' ] ifFalse: [ model class name asString ] ].
	caption := law, ' · ', mode.
	target := simulator parameters revisitTargetSeconds.
	delays := simulator history collect: [ :step | self delayIn: step tickSeconds: seconds ].
	lastGap := samples last stdGap.
	lastSpeed := samples last avgSpeed / seconds.
	direct := (samples collect: #directPerceptionRatio) average.
	bearing := (samples collect: #angularPerceptionRatio) average.
	outOfRange := (samples collect: #outOfRangePerceptionRatio) average.
	unavailable := (samples collect: #unobservablePerceptionRatio) average
]

{ #category : 'evaluation' }
SoSeAtelierRevisitRun >> delayIn: step tickSeconds: seconds [
	| drones |
	drones := step drones.
	drones ifEmpty: [ ^ Float infinity ].
	^ (drones collect: [ :drone |
		| arc speed |
		arc := drones size = 1 ifTrue: [ step range ] ifFalse: [ step gapAheadDrone: drone ].
		speed := drone currentSpeed.
		speed > 0 ifTrue: [ arc * seconds / speed ] ifFalse: [ Float infinity ] ]) max
]

{ #category : 'accessing' }
SoSeAtelierRevisitRun >> caption [
	^ caption
]

{ #category : 'accessing' }
SoSeAtelierRevisitRun >> target [
	^ target
]

{ #category : 'evaluation' }
SoSeAtelierRevisitRun >> indicatorsFor: seconds [
	| limit |
	limit := seconds + ((seconds abs max: 1.0) * 1.0e-9).
	^ { target. delays last. delays max. (delays count: [ :delay | delay > limit ]).
		lastGap. lastSpeed. direct * 100. bearing * 100. outOfRange * 100. unavailable * 100 }
]
