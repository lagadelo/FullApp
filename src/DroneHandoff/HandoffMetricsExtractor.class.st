Class {
	#name : 'HandoffMetricsExtractor',
	#superclass : 'Object',
	#instVars : [
		'handoffSim',
		'nRuns'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'instance creation' }
HandoffMetricsExtractor class >> on: aHandoffSim nRuns: n [

	^ self new
		  handoffSim: aHandoffSim;
		  nRuns: n;
		  yourself
]

{ #category : 'extracting' }
HandoffMetricsExtractor >> extractFrom: aSimulator [
	"Adapte les paramètres du handoff depuis l'état courant du simulateur,
     puis lance le Monte Carlo. Retourne un Dictionary de métriques."

	| avgSpeed result |
	"Vitesse moyenne courante → met à jour la vitesse intruder si on veut la coupler"
	avgSpeed := aSimulator metrics avgSpeed.

	"On peut surcharger la vitesse intruder depuis la simulation macro"
	"handoffSim perception ... (optionnel)"

	handoffSim nRuns: nRuns.
	handoffSim printReport: false.
	result := handoffSim run.
	^ result
]

{ #category : 'accessing' }
HandoffMetricsExtractor >> handoffSim [

	^ handoffSim
]

{ #category : 'accessing' }
HandoffMetricsExtractor >> handoffSim: anObject [

	handoffSim := anObject
]

{ #category : 'extracting' }
HandoffMetricsExtractor >> metricsKeys [ 
    ^ #( #mean #stddev #p50 #p95 #pSlaRespected #pWindowRespected )
]

{ #category : 'accessing' }
HandoffMetricsExtractor >> nRuns [

	^ nRuns
]

{ #category : 'accessing' }
HandoffMetricsExtractor >> nRuns: anObject [

	nRuns := anObject
]
