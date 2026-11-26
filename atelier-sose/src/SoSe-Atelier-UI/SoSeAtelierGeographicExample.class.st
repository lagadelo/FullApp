Class {
	#name : 'SoSeAtelierGeographicExample',
	#superclass : 'SoSeVercorsExample',
	#instVars : [ 'recipe' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'configuration' }
SoSeAtelierGeographicExample >> recipe: aRecipe [ recipe := aRecipe ]

{ #category : 'simulation' }
SoSeAtelierGeographicExample >> newSimulatorWith: configure [
	| simulator |
	simulator := super newSimulatorWith: configure.
	recipe configurerCommandeDe: simulator.
	^ simulator
]
