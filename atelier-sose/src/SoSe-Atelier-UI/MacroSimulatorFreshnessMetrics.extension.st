Extension { #name : 'MacroSimulatorFreshnessMetrics' }

{ #category : '*SoSe-Atelier-UI' }
MacroSimulatorFreshnessMetrics >> includePassageMetrics: aMetrics [
	freshness at: #passageMetrics put: aMetrics
]

{ #category : '*SoSe-Atelier-UI' }
MacroSimulatorFreshnessMetrics >> minFreshness [
	^ freshness at: #passageMetrics ifPresent: [ :row | row minFreshness ]
]

{ #category : '*SoSe-Atelier-UI' }
MacroSimulatorFreshnessMetrics >> maxFreshnessGap [
	^ freshness at: #passageMetrics ifPresent: [ :row | row maxFreshnessGap ]
]

{ #category : '*SoSe-Atelier-UI' }
MacroSimulatorFreshnessMetrics >> freshnessRuptureCount [
	^ freshness at: #passageMetrics ifPresent: [ :row | row freshnessRuptureCount ]
]

{ #category : '*SoSe-Atelier-UI' }
MacroSimulatorFreshnessMetrics >> freshnessRupture [
	^ freshness at: #passageMetrics ifPresent: [ :row | row freshnessRupture ]
]
