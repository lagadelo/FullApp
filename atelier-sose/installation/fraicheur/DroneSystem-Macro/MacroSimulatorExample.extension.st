Extension { #name : 'MacroSimulatorExample' }

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> withPassageFreshnessDo: block [
	^ MacroSimulatorFreshnessScope
		value: (MacroSimulatorFreshnessScope value ifNil: [ MacroSimulatorFreshnessScope defaultMaxDate ])
		during: block
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> freshnessExampleWith: parameters lossAt: lossTick steps: tickCount [
	^ self withPassageFreshnessDo: [
		| simulator |
		simulator := parameters initializeSimulator.
		lossTick ifNotNil: [ simulator loose: 1 at: lossTick ].
		simulator run: tickCount.
		self exportFreshnessExample: simulator.
		simulator ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exportFreshnessExample: simulator [
	^ (MacroExporter directoryName: self timeStampForNaming, '-freshness-', UUID new asString)
		visit: simulator
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example1WithFreshness [
	^ self freshnessExampleWith: MacroSimulatorParameters example1 lossAt: nil steps: 50
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example2WithFreshness [
	^ self freshnessExampleWith: MacroSimulatorParameters example1 lossAt: 20 steps: 50
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example3WithFreshness [
	^ self
		freshnessExampleWith: (MacroSimulatorParameters example1 policy: #capingPolicy; yourself)
		lossAt: 20 steps: 3000
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example4WithFreshness [
	^ self freshnessExampleWith: MacroSimulatorParameters example1 lossAt: 20 steps: 3000
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleBrittanyWithFreshness [
	^ self freshnessExampleWith: MacroSimulatorParameters example4 lossAt: nil steps: 50
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleISSEBaselineWithFreshness [
	^ self withPassageFreshnessDo: [
		| simulator |
		simulator := self generateScenario: 10.
		simulator run: 1500.
		self exportFreshnessExample: simulator.
		simulator ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example5WithFreshness [
	^ self withPassageFreshnessDo: [ self example5 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example6WithFreshness [
	^ self withPassageFreshnessDo: [ self example6 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example6bWithFreshness [
	^ self withPassageFreshnessDo: [ self example6b ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example7WithFreshness [
	^ self withPassageFreshnessDo: [ self example7 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example8WithFreshness [
	^ self withPassageFreshnessDo: [ self example8 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example8RevisedWithFreshness [
	^ self withPassageFreshnessDo: [ self example8Revised ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example8WithDilationWithFreshness [
	^ self withPassageFreshnessDo: [ self example8WithDilation ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example8bWithFreshness [
	^ self withPassageFreshnessDo: [ self example8b ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example9WithFreshness [
	^ self withPassageFreshnessDo: [ self example9 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> example10WithFreshness [
	^ self withPassageFreshnessDo: [ self example10 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleISSEWithFreshness [
	^ self withPassageFreshnessDo: [ self exampleISSE ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleISSE2WithFreshness [
	^ self withPassageFreshnessDo: [ self exampleISSE2 ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleISSE2bWithFreshness [
	^ self withPassageFreshnessDo: [ self exampleISSE2b ]
]

{ #category : '*DroneSystem-Macro' }
MacroSimulatorExample class >> exampleISSE3WithFreshness [
	^ self withPassageFreshnessDo: [ self exampleISSE3 ]
]
