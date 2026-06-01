Class {
	#name : 'DroneDeploymentPlanner',
	#superclass : 'Object',
	#instVars : [
		'simulation',
		'assetDistanceKm',
		'intruderSpeedKmh',
		'interceptorSpeedKmh',
		'perimeterKm',
		'nPatrolDrones',
		'envelopeRadiusKm',
		'handoffExtractor'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'dimensionning' }
DroneDeploymentPlanner >> addHandoffExtractor: aHandoffMetricsExtractor [ 
    "Enregistre l'extracteur handoff — appelé lors de chaque addToSeries:"
    handoffExtractor := aHandoffMetricsExtractor
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> assetDistanceKm [

	^ assetDistanceKm
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> assetDistanceKm: anObject [

	assetDistanceKm := anObject
]

{ #category : 'computing' }
DroneDeploymentPlanner >> confirmationTimeSeconds [
	"Temps avant confirmation = espacement / vitesse drone"

	^ perimeterKm / nPatrolDrones / self dronePatrolSpeedKmh * 3600.0
]

{ #category : 'dimensionning' }
DroneDeploymentPlanner >> dilationKm [ 
    "Distance minimale de détection pour garantir T_sla :
     intruder à v_i doit être détecté avant de franchir ce seuil.
Cette valeur va permettre de dillater l'envellope convexe définie autour des assets"
    ^ intruderSpeedKmh * simulation slaSeconds / 3600.0

]

{ #category : 'computing' }
DroneDeploymentPlanner >> dronePatrolSpeedKmh [ 
    "Vitesse de patrouille = périmètre / tRevisit"
    ^ perimeterKm / (simulation perception tRevisit paramA / 3600.0)

]

{ #category : 'accessing' }
DroneDeploymentPlanner >> envelopeRadiusKm [

	^ envelopeRadiusKm
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> envelopeRadiusKm: anObject [

	envelopeRadiusKm := anObject
]

{ #category : 'initialization' }
DroneDeploymentPlanner >> initialize [ 
    simulation          := DroneHandoffSimulation new.
    assetDistanceKm     := 5.0.
    intruderSpeedKmh    := 80.0.
    interceptorSpeedKmh := 120.0.
    perimeterKm         := 20.0.
    nPatrolDrones       := 4.
    envelopeRadiusKm    := 3.0.
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> interceptorSpeedKmh [

	^ interceptorSpeedKmh
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> interceptorSpeedKmh: anObject [

	interceptorSpeedKmh := anObject
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> intruderSpeedKmh [

	^ intruderSpeedKmh
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> intruderSpeedKmh: anObject [

	intruderSpeedKmh := anObject
]

{ #category : 'computing' }
DroneDeploymentPlanner >> maxInterceptorDistanceKmAt: xPercent nRuns: n [
	"Retourne la distance maximale de déploiement de l'intercepteur
     pour garantir une interception avec probabilité xPercent.
     xPercent : ex. 0.95 pour 95%"

	| tAvailable samples sorted quantileIndex tReactionBudget |
	samples := self reactionTimeSamplesWithoutIntercept: n.
	sorted := samples asSortedCollection asArray.

	"Quantile (1 - x) de T_reaction → budget serré"
	quantileIndex := ((1.0 - xPercent) * n) ceiling max: 1.
	tReactionBudget := sorted at: quantileIndex.

	"Temps restant pour tIntercept"

	tAvailable := self tImpactSeconds - tReactionBudget.
	tAvailable <= 0 ifTrue: [
			Transcript
				show:
					'*** IMPOSSIBLE : T_reaction dépasse T_impact au quantile demandé';
				cr.
			^ 0.0 ].

	^ interceptorSpeedKmh * tAvailable / 3600.0
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> nPatrolDrones [

	^ nPatrolDrones
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> nPatrolDrones: anObject [

	nPatrolDrones := anObject
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> perimeterKm [

	^ perimeterKm
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> perimeterKm: anObject [

	perimeterKm := anObject
]

{ #category : 'computing' }
DroneDeploymentPlanner >> reactionTimeSamplesWithoutIntercept: n [
	"Tire n échantillons de T_reaction = T_perception + T_task + T_tx + T_launch"

	| p a samples |
	p := simulation perception.
	a := simulation action.
	samples := (Array new: n) collect: [
		           p sampleSeconds + a tTask sample + a tTx sample
		           + a tLaunch sample ].
	^ samples
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> simulation [

	^ simulation
]

{ #category : 'accessing' }
DroneDeploymentPlanner >> simulation: anObject [

	simulation := anObject
]

{ #category : 'computing' }
DroneDeploymentPlanner >> tImpactSeconds [

	^ assetDistanceKm / intruderSpeedKmh * 3600.0
]
