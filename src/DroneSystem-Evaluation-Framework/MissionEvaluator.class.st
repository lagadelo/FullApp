Class {
	#name : 'MissionEvaluator',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'evaluationScenarios',
		'results',
		'metricsCollector',
		'perturbationEngine',
		'codeReloader',
		'policyExecutor'
	],
	#category : 'DroneSystem-Evaluation-Framework',
	#package : 'DroneSystem-Evaluation-Framework'
}

{ #category : 'adding' }
MissionEvaluator >> addEvaluationScenario: aMissionEvaluationScenario [
	evaluationScenarios add: aMissionEvaluationScenario.
	^ self
]

{ #category : 'accessing' }
MissionEvaluator >> bindSimulator: aSimulator [
	simulator := aSimulator.
	metricsCollector bindSimulator: simulator.
	perturbationEngine bindSimulator: simulator.
	codeReloader bindSimulator: simulator.
	policyExecutor bindSimulator: simulator.
	^ self
]

{ #category : 'comparison' }
MissionEvaluator >> compareScenarios: scenario1Name with: scenario2Name onMetric: metricSymbol [
	| analysis1 analysis2 comparison |
	analysis1 := results at: scenario1Name ifAbsent: [ ^ nil ].
	analysis2 := results at: scenario2Name ifAbsent: [ ^ nil ].
	
	comparison := analysis1 compareWith: analysis2 onMetric: metricSymbol.
	^ comparison
]

{ #category : 'execution' }
MissionEvaluator >> evaluateAllScenarios [
	evaluationScenarios do: [ :scenario |
		self evaluateScenario: scenario
	].
	^ results
]

{ #category : 'execution' }
MissionEvaluator >> evaluateScenario: aMissionEvaluationScenario [
	| scenarioMetrics |
	scenarioMetrics := OrderedCollection new.
	
	aMissionEvaluationScenario numberOfRuns timesRepeat: [
		| runMetrics |
		aMissionEvaluationScenario randomSeed notNil ifTrue: [
			Random seed: aMissionEvaluationScenario randomSeed
		].
		
		runMetrics := self executeEvaluationRun: aMissionEvaluationScenario.
		scenarioMetrics add: runMetrics
	].
	
	self storeResults: aMissionEvaluationScenario withMetrics: scenarioMetrics
]

{ #category : 'private' }
MissionEvaluator >> executeEvaluationRun: aMissionEvaluationScenario [
	| perturbationScenario policy codeDeployments missionName successCrit |
	perturbationScenario := aMissionEvaluationScenario perturbationScenario.
	policy := aMissionEvaluationScenario resiliencyPolicy.
	codeDeployments := aMissionEvaluationScenario codeDeployments.
	missionName := aMissionEvaluationScenario scenarioName.
	successCrit := aMissionEvaluationScenario successCriteria.
	
	"Initialiser la run"
	simulator initialize.
	
	"Setup perturbation engine"
	perturbationScenario notNil ifTrue: [
		perturbationEngine loadScenario: perturbationScenario
	].
	
	"Setup policy"
	policy notNil ifTrue: [
		policyExecutor policy: policy
	].
	
	"Deployer les codes si spécifiés"
	codeDeployments do: [ :deployment |
		codeReloader deployStrategy: deployment methodBlock 
			forDroneIds: deployment droneIds 
			named: deployment strategyName
	].
	
	"Démarrer la collecte des métriques"
	metricsCollector startRun: missionName 
		withScenario: perturbationScenario 
		successCriteria: successCrit.
	
	"Exécuter la simulation"
	[ simulator isRunning ] whileTrue: [
		perturbationEngine step.
		policyExecutor executePolicy.
		simulator step.
		metricsCollector captureSnapshot
	].
	
	"Finaliser"
	metricsCollector endRun.
	^ metricsCollector runs last
]

{ #category : 'initialization' }
MissionEvaluator >> initialize [
	super initialize.
	simulator := nil.
	evaluationScenarios := OrderedCollection new.
	results := Dictionary new.
	metricsCollector := MetricsCollector new.
	perturbationEngine := PerturbationEngine new.
	codeReloader := DynamicCodeReloader new.
	policyExecutor := ResiliencyPolicyExecutor new
]

{ #category : 'printing' }
MissionEvaluator >> printOn: aStream [
	aStream nextPutAll: 'MissionEvaluator(';
		nextPutAll: evaluationScenarios size asString;
		nextPutAll: ' scenarios, ';
		nextPutAll: results size asString;
		nextPutAll: ' results)')
]

{ #category : 'reporting' }
MissionEvaluator >> printReport [
	| stream |
	stream := String new writeStream.
	
	stream nextPutAll: '=== MISSION EVALUATION REPORT ==='; cr; cr.
	
	results keysAndValuesDo: [ :scenarioName :analysis |
		stream nextPutAll: 'Scenario: '; nextPutAll: scenarioName; cr.
		stream nextPutAll: '  Runs: '; nextPutAll: analysis metricsRuns size asString; cr.
		stream nextPutAll: '  Mean Coverage: '; 
			nextPutAll: (analysis computeMeanCoverage roundTo: 0.01) asString; 
			nextPutAll: ' % ± '; 
			nextPutAll: (analysis computeStdDevCoverage roundTo: 0.01) asString; cr.
		stream nextPutAll: '  Success Rate: '; 
			nextPutAll: (analysis computeSuccessRate roundTo: 0.1) asString; 
			nextPutAll: ' %'; cr.
		stream nextPutAll: '  Mean Resilience Score: '; 
			nextPutAll: (analysis computeMeanResilienceScore roundTo: 0.01) asString; 
			nextPutAll: ' ± '; 
			nextPutAll: (analysis computeStdDevResilienceScore roundTo: 0.01) asString; cr; cr
	].
	
	^ stream contents
]

{ #category : 'accessing' }
MissionEvaluator >> results [
	^ results
]

{ #category : 'accessing' }
MissionEvaluator >> resultsFor: scenarioName [
	^ results at: scenarioName ifAbsent: [ nil ]
]

{ #category : 'private' }
MissionEvaluator >> storeResults: scenario withMetrics: metrics [
	| analysisResults |
	analysisResults := StatisticalAnalysis new.
	metrics do: [ :m | analysisResults addMetricsRun: m ].
	
	results at: scenario scenarioName put: analysisResults
]
