"
Variante optionnelle du MacroSimulator. Le moteur legacy effectue les
mouvements. La fenêtre active enregistre ensuite les positions du nouvel état.
Les états anciens permettent de reconstruire une fenêtre à une date donnée.
"
Class {
	#name : 'MacroSimulatorWithFreshness',
	#superclass : 'MacroSimulator',
	#instVars : [ 'passageWindow', 'passageMaxDate', 'passageSecondsPerTick' ],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'initialization' }
MacroSimulatorWithFreshness >> startWith: parameters [
	super startWith: parameters.
	passageMaxDate := parameters maxDate.
	passageSecondsPerTick := parameters secondsPerTick.
	passageWindow := self newPassageWindow.
	passageWindow recordStep: self current.
	^ self
]

{ #category : 'stepping' }
MacroSimulatorWithFreshness >> step [
	super step.
	passageWindow recordStep: self current.
	^ self
]

{ #category : 'stepping' }
MacroSimulatorWithFreshness >> stepSingleUpdate [
	super stepSingleUpdate.
	passageWindow recordStep: self current.
	^ self
]

{ #category : 'freshness' }
MacroSimulatorWithFreshness >> newPassageWindow [
	^ MacroSimulatorPassageWindow maxDate: passageMaxDate secondsPerTick: passageSecondsPerTick
]

{ #category : 'freshness' }
MacroSimulatorWithFreshness >> passageWindowAt: step [
	| lastIndex firstIndex window |
	step == self current ifTrue: [ ^ passageWindow ].
	lastIndex := self history indexOf: step.
	lastIndex = 0 ifTrue: [ self error: 'Cet état ne fait pas partie de l’historique.' ].
	window := self newPassageWindow.
	firstIndex := lastIndex.
	[ firstIndex > 1 and: [
		window includesTick: (self history at: firstIndex - 1) timeStep at: step timeStep ] ]
		whileTrue: [ firstIndex := firstIndex - 1 ].
	firstIndex to: lastIndex do: [ :index | window recordStep: (self history at: index) ].
	^ window
]

{ #category : 'reporting' }
MacroSimulatorWithFreshness >> evaluateMetrics [
	| window |
	window := self newPassageWindow.
	^ MacroSimulatorMetricsHistory from: (self history collect: [ :step |
		window recordStep: step.
		MacroSimulatorPassageMetrics on: step passageWindow: window ])
]

{ #category : 'visiting' }
MacroSimulatorWithFreshness >> accept: visitor [
	(visitor respondsTo: #visitMacroSimulatorWithFreshness:)
		ifTrue: [ ^ visitor visitMacroSimulatorWithFreshness: self ].
	^ super accept: visitor
]
