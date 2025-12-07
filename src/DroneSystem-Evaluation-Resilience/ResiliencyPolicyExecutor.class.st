Class {
	#name : 'ResiliencyPolicyExecutor',
	#superclass : 'Object',
	#instVars : [
		'policy',
		'simulator',
		'perturbationEngine'
	],
	#category : 'DroneSystem-Evaluation-Resilience',
	#package : 'DroneSystem-Evaluation-Resilience'
}

{ #category : 'accessing' }
ResiliencyPolicyExecutor >> bindPerturbationEngine: aPerturbationEngine [
	perturbationEngine := aPerturbationEngine.
	^ self
]

{ #category : 'accessing' }
ResiliencyPolicyExecutor >> bindSimulator: aSimulator [
	simulator := aSimulator.
	^ self
]

{ #category : 'execution' }
ResiliencyPolicyExecutor >> executePolicy [
	| currentResilience clusters |
	policy isNil ifTrue: [ ^ self ].
	simulator isNil ifTrue: [ ^ self ].
	
	"Évaluer la résilience actuelle"
	currentResilience := simulator activeDroneCount / (simulator totalDroneCount max: 1).
	
	"Vérifier les actions de la politique"
	(policy shouldActivateSpare: currentResilience) ifTrue: [
		clusters := simulator allClusters ifNil: [ #() ].
		clusters do: [ :cluster |
			cluster activateSpareIfAvailable
		]
	].
	
	(policy shouldContinueMission: currentResilience) ifFalse: [
		"Mission compromise"
		policy rollbackOnFailure ifTrue: [
			"Essayer un rollback de code"
			simulator codeReloader notNil ifTrue: [
				simulator codeReloader rollbackStrategy: #nextWayPointFor:
			]
		] ifFalse: [
			"Abort mission"
			simulator abortMission
		]
	]
]

{ #category : 'initialization' }
ResiliencyPolicyExecutor >> initialize [
	super initialize.
	policy := nil.
	simulator := nil.
	perturbationEngine := nil
]

{ #category : 'accessing' }
ResiliencyPolicyExecutor >> policy: aResiliencyPolicy [
	policy := aResiliencyPolicy.
	^ self
]

{ #category : 'printing' }
ResiliencyPolicyExecutor >> printOn: aStream [
	aStream nextPutAll: 'ResiliencyPolicyExecutor(';
		nextPutAll: (policy notNil ifTrue: [ policy policyName ] ifFalse: [ 'NilPolicy' ]);
		nextPut: $)
]
