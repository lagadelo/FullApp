Class {
	#name : 'StatisticalAnalysis',
	#superclass : 'Object',
	#instVars : [
		'metricsRuns',
		'comparisonResults'
	],
	#category : 'DroneSystem-Evaluation-Metrics',
	#package : 'DroneSystem-Evaluation-Metrics'
}

{ #category : 'adding' }
StatisticalAnalysis >> addMetricsRun: aMissionMetrics [
	metricsRuns add: aMissionMetrics.
	^ self
]

{ #category : 'private' }
StatisticalAnalysis >> approximatePValue: tValue withSampleSize: n [
	"Approximation simple de p-value pour test-t (deux queues)"
	| t abst |
	t := tValue.
	abst := t abs.
	
	abst < 0.5 ifTrue: [ ^ 0.6 ].
	abst < 1.0 ifTrue: [ ^ 0.3 ].
	abst < 2.0 ifTrue: [ ^ 0.05 ].
	abst < 3.0 ifTrue: [ ^ 0.01 ].
	^ 0.001
]

{ #category : 'comparison' }
StatisticalAnalysis >> compareWith: anotherAnalysis onMetric: metricSymbol [
	| thisValues otherValues tStatistic pValue |
	metricSymbol = #coverage ifTrue: [
		thisValues := metricsRuns collect: [ :m | m finalCoverage ].
		otherValues := anotherAnalysis metricsRuns collect: [ :m | m finalCoverage ].
	] ifFalse: [
		metricSymbol = #resilience ifTrue: [
			thisValues := metricsRuns collect: [ :m | m averageResilienceScore ].
			otherValues := anotherAnalysis metricsRuns collect: [ :m | m averageResilienceScore ].
		] ifFalse: [
			^ nil
		]
	].
	
	"Calcul approximatif du test-t"
	tStatistic := self computeTStatisticBetween: thisValues and: otherValues.
	pValue := self approximatePValue: tStatistic withSampleSize: (thisValues size + otherValues size).
	
	^ Dictionary new
		at: #tStatistic put: tStatistic;
		at: #pValue put: pValue;
		at: #significant put: (pValue < 0.05);
		yourself
]

{ #category : 'computing' }
StatisticalAnalysis >> computeMeanCoverage [
	metricsRuns isEmpty ifTrue: [ ^ 0.0 ].
	^ (metricsRuns inject: 0 into: [ :sum :m | sum + m finalCoverage ]) / metricsRuns size
]

{ #category : 'computing' }
StatisticalAnalysis >> computeMeanResilienceScore [
	metricsRuns isEmpty ifTrue: [ ^ 0.0 ].
	^ (metricsRuns inject: 0 into: [ :sum :m | sum + m averageResilienceScore ]) / metricsRuns size
]

{ #category : 'computing' }
StatisticalAnalysis >> computeStdDevCoverage [
	| mean variance |
	metricsRuns isEmpty ifTrue: [ ^ 0.0 ].
	mean := self computeMeanCoverage.
	variance := metricsRuns inject: 0 into: [ :sum :m | 
		sum + ((m finalCoverage - mean) squared)
	].
	^ (variance / metricsRuns size) sqrt
]

{ #category : 'computing' }
StatisticalAnalysis >> computeStdDevResilienceScore [
	| mean variance |
	metricsRuns isEmpty ifTrue: [ ^ 0.0 ].
	mean := self computeMeanResilienceScore.
	variance := metricsRuns inject: 0 into: [ :sum :m | 
		sum + ((m averageResilienceScore - mean) squared)
	].
	^ (variance / metricsRuns size) sqrt
]

{ #category : 'computing' }
StatisticalAnalysis >> computeSuccessRate [
	metricsRuns isEmpty ifTrue: [ ^ 0.0 ].
	^ ((metricsRuns select: [ :m | m missionSuccessful ]) size / metricsRuns size) * 100.0
]

{ #category : 'private' }
StatisticalAnalysis >> computeTStatisticBetween: values1 and: values2 [
	| mean1 mean2 var1 var2 n1 n2 pooledVariance |
	n1 := values1 size.
	n2 := values2 size.
	n1 = 0 ifTrue: [ ^ 0.0 ].
	n2 = 0 ifTrue: [ ^ 0.0 ].
	
	mean1 := values1 sum / n1.
	mean2 := values2 sum / n2.
	
	var1 := (values1 inject: 0 into: [ :sum :v | sum + ((v - mean1) squared) ]) / (n1 - 1 max: 1).
	var2 := (values2 inject: 0 into: [ :sum :v | sum + ((v - mean2) squared) ]) / (n2 - 1 max: 1).
	
	pooledVariance := ((n1 - 1 * var1) + (n2 - 1 * var2)) / (n1 + n2 - 2 max: 1).
	
	^ (mean1 - mean2) / ((pooledVariance * (1/n1 + 1/n2)) sqrt max: 0.001)
]

{ #category : 'initialization' }
StatisticalAnalysis >> initialize [
	super initialize.
	metricsRuns := OrderedCollection new.
	comparisonResults := Dictionary new
]

{ #category : 'accessing' }
StatisticalAnalysis >> metricsRuns [
	^ metricsRuns
]

{ #category : 'printing' }
StatisticalAnalysis >> printOn: aStream [
	aStream nextPutAll: 'StatisticalAnalysis(';
		nextPutAll: metricsRuns size asString;
		nextPutAll: ' runs, mean_coverage=';
		nextPutAll: (self computeMeanCoverage roundTo: 0.01) asString; nextPut: $)
]
