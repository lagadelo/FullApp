"
Âge maximal en secondes pour les variantes des exemples legacy, pendant
leur exécution. Permet de réutiliser les séquences d'événements et de réglages
des exemples alors qu'ils construisent leurs propres paramètres.
"
Class {
	#name : 'MacroSimulatorFreshnessScope',
	#superclass : 'DynamicVariable',
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'defaults' }
MacroSimulatorFreshnessScope class >> defaultMaxDate [
	^ 75
]
