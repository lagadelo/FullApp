Class {
	#name : 'DynamicCodeReloader',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'activeVersions',
		'versionHistory',
		'nextVersionId',
		'deploymentLog'
	],
	#category : 'DroneSystem-Evaluation-CodeReload',
	#package : 'DroneSystem-Evaluation-CodeReload'
}

{ #category : 'accessing' }
DynamicCodeReloader >> bindSimulator: aSimulator [
	simulator := aSimulator.
	^ self
]

{ #category : 'accessing' }
DynamicCodeReloader >> currentVersionOf: aStrategyName [
	^ activeVersions at: aStrategyName ifAbsent: [ nil ]
]

{ #category : 'deployment' }
DynamicCodeReloader >> deployStrategy: aBlockOrSelector 
	forDroneIds: droneIdCollection 
	named: aStrategyName [
	"Déploie une nouvelle stratégie à des drones spécifiques"
	| version drone |
	version := CodeVersion new
		versionId: nextVersionId;
		strategyName: aStrategyName;
		methodBlock: aBlockOrSelector;
		description: ('Deployed at ' , DateAndTime now asString).
	
	droneIdCollection = #all 
		ifTrue: [ version forAllDrones ]
		ifFalse: [ version forDroneIds: droneIdCollection ].
	
	"Récupérer la version précédente si elle existe"
	(activeVersions at: aStrategyName ifAbsent: [ nil ]) notNil ifTrue: [
		version linkedToPrevious: (activeVersions at: aStrategyName)
	].
	
	"Enregistrer la nouvelle version"
	activeVersions at: aStrategyName put: version.
	versionHistory add: version.
	
	"Appliquer la stratégie aux drones"
	droneIdCollection = #all 
		ifTrue: [ 
			simulator allDrones do: [ :d | 
				self installStrategyOnDrone: d strategy: aBlockOrSelector name: aStrategyName 
			]
		]
		ifFalse: [
			droneIdCollection do: [ :droneId |
				drone := simulator findDroneWithId: droneId.
				drone notNil ifTrue: [ 
					self installStrategyOnDrone: drone strategy: aBlockOrSelector name: aStrategyName
				]
			]
		].
	
	nextVersionId := nextVersionId + 1.
	self logDeployment: version.
	^ version
]

{ #category : 'accessing' }
DynamicCodeReloader >> deploymentLog [
	^ deploymentLog
]

{ #category : 'initialization' }
DynamicCodeReloader >> initialize [
	super initialize.
	simulator := nil.
	activeVersions := Dictionary new.
	versionHistory := OrderedCollection new.
	nextVersionId := 1.
	deploymentLog := OrderedCollection new
]

{ #category : 'private' }
DynamicCodeReloader >> installStrategyOnDrone: aDrone strategy: aBlockOrSelector name: aStrategyName [
	"Installe dynamiquement la stratégie sur un drone"
	aDrone strategies notNil ifTrue: [
		aDrone strategies at: aStrategyName put: aBlockOrSelector
	] ifFalse: [
		aDrone strategies: (Dictionary with: aStrategyName -> aBlockOrSelector)
	]
]

{ #category : 'logging' }
DynamicCodeReloader >> logDeployment: aCodeVersion [
	| log |
	log := Dictionary new
		at: #timestamp put: DateAndTime now;
		at: #event put: #deployment;
		at: #version put: aCodeVersion;
		yourself.
	deploymentLog add: log
]

{ #category : 'logging' }
DynamicCodeReloader >> logRollback: strategyName from: oldVersion to: newVersion [
	| log |
	log := Dictionary new
		at: #timestamp put: DateAndTime now;
		at: #event put: #rollback;
		at: #strategy put: strategyName;
		at: #from put: oldVersion;
		at: #to put: newVersion;
		yourself.
	deploymentLog add: log
]
