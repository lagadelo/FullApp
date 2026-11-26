"Adapte les classes macro de l’image aux champs de revisite et aux hypothèses de perception."
{ MacroSimulatorDrone. MacroSimulatorParameters } do: [ :classe |
    #('revisitTargetSeconds' 'secondsPerTick') do: [ :nom |
        (classe instVarNames includes: nom) ifFalse: [ classe addInstVarNamed: nom ] ] ].
!

MacroSimulatorHybridPerception subclass: #MacroSimulatorSelectablePerception
    instanceVariableNames: 'mode'
    classVariableNames: ''
    package: 'DroneSystem-Macro'!

MacroSimulatorDrone compile: 'revisitTargetSeconds
	^ revisitTargetSeconds' classified: 'accessing - revisit'.
!

MacroSimulatorDrone compile: 'revisitTargetSeconds: seconds
	revisitTargetSeconds := seconds' classified: 'accessing - revisit'.
!

MacroSimulatorDrone compile: 'secondsPerTick
	^ secondsPerTick ifNil: [ 1 ]' classified: 'accessing - revisit'.
!

MacroSimulatorDrone compile: 'secondsPerTick: seconds
	secondsPerTick := seconds' classified: 'accessing - revisit'.
!

MacroSimulatorParameters compile: 'generateDrone
	"Generate a drone with no meaning id nor position"

	| tmp |
	tmp := MacroSimulatorDrone new.
	tmp id: Float infinity.
	tmp nominalSpeed: self nominalSpeed.
	tmp maxSpeed: self maxSpeed.
	tmp minSpeed: self minSpeed.
	tmp currentSpeed: self nominalSpeed.
	tmp sensingRadius: self sensingRadius.
	tmp captureRadius: self captureRadius.
	tmp position: Float infinity.
	tmp revisitTargetSeconds: self revisitTargetSeconds.
	tmp secondsPerTick: self secondsPerTick.
	^ tmp' classified: 'simulator  generation'.
!

MacroSimulatorParameters compile: 'revisitTargetSeconds
	^ revisitTargetSeconds' classified: 'accessing - revisit'.
!

MacroSimulatorParameters compile: 'revisitTargetSeconds: seconds
	(seconds isNil or: [ seconds isNumber and: [ seconds asFloat isFinite and: [ seconds > 0 ] ] ])
		ifFalse: [ self error: ''Le délai de revisite doit être strictement positif et fini.'' ].
	revisitTargetSeconds := seconds' classified: 'accessing - revisit'.
!

MacroSimulatorParameters compile: 'secondsPerTick
	^ secondsPerTick ifNil: [ 1 ]' classified: 'accessing - revisit'.
!

MacroSimulatorParameters compile: 'secondsPerTick: seconds
	(seconds isNumber and: [ seconds asFloat isFinite and: [ seconds > 0 ] ])
		ifFalse: [ self error: ''La durée du tik doit être strictement positive et finie.'' ].
	secondsPerTick := seconds' classified: 'accessing - revisit'.
!

MacroSimulatorBehavior compile: 'capingPolicy
	^ self capingCommandsUsing: #capingPolicy' classified: 'policies'.
!

MacroSimulatorBehavior compile: 'revisedCapingPolicy
	^ self capingCommandsUsing: #revisedCapingPolicy' classified: 'policies'.
!

MacroSimulatorBehavior compile: 'revisitCapingPolicy
	^ self capingCommandsUsing: #revisitCapingPolicy' classified: 'policies - revisit'.
!

MacroSimulatorBehavior compile: 'capingCommandsUsing: selector
	^ [ :step | step drones do: [ :drone |
		self withObservedGapsOf: drone in: step do: [ :ahead :behind |
			drone currentSpeed: (self capingCommandFor: drone ahead: ahead behind: behind using: selector) ] ] ]' classified: 'policies - revisit'.
!

MacroSimulatorBehavior compile: 'capingCommandFor: drone ahead: ahead behind: behind using: selector
	"All speeds in this method are displacements in metres per tik."
	| maximumGap error ratio reference command |
	maximumGap := ahead max: behind.
	error := maximumGap = 0 ifTrue: [ 0.0 ] ifFalse: [ ((ahead - behind) / maximumGap) asFloat ].
	(error abs < self sensibility and: [ selector ~= #capingPolicy ]) ifTrue: [
		reference := drone nominalSpeed.
		selector = #revisitCapingPolicy ifTrue: [
			drone revisitTargetSeconds ifNotNil: [ :seconds |
				reference := (reference max: maximumGap / seconds * drone secondsPerTick) min: drone maxSpeed ] ].
		command := drone currentSpeed + ((reference - drone currentSpeed) * self pacingRate).
		^ selector = #revisitCapingPolicy
			ifTrue: [ (command min: drone maxSpeed) max: drone minSpeed ]
			ifFalse: [ command ] ].
	ratio := error abs < self sensibility ifTrue: [ self pacingRate ] ifFalse: [ error * 2 + 1 ].
	^ ((drone currentSpeed * ratio roundUpTo: 0.1) min: drone maxSpeed) max: drone minSpeed' classified: 'policies - revisit'.
!

MacroSimulatorHybridPerception compile: 'observationOf: aDrone target: targetDrone side: aSide in: aStep
	| parameters observerPoint targetPoint targetVector targetUnit heading relativeAngle ray trueGap euclidean candidatesInfo candidates collinear status estimated |
	parameters := aStep simulator parameters.
	parameters wayPoints ifNil: [
		self error: ''MacroSimulatorHybridPerception requires ordered wayPoints on the simulator parameters'' ].
	observerPoint := aStep realPositionOfDrone: aDrone.
	targetPoint := aStep realPositionOfDrone: targetDrone.
	targetVector := parameters localXYOf: targetPoint relativeTo: observerPoint.
	euclidean := self normOf: targetVector.
	trueGap := aSide = #ahead
		ifTrue: [ aStep gapAheadDrone: aDrone ]
		ifFalse: [ aStep gapBackwardDrone: aDrone ].
	targetUnit := self normalized: targetVector.
	targetUnit ifNil: [
		^ MacroSimulatorPerceptionObservation
			status: #unobservableNoIntersection
			trueGap: trueGap distance: euclidean bearing: 0.0 estimatedGap: nil candidates: 0 ].
	heading := parameters headingVectorAtArcPosition: aDrone position relativeTo: observerPoint.
	relativeAngle := (self cross: heading with: targetUnit)
		arcTan: (self dot: heading with: targetUnit).
	euclidean > aDrone sensingRadius ifTrue: [
		^ MacroSimulatorPerceptionObservation
			status: #outOfRange
			trueGap: trueGap distance: euclidean bearing: relativeAngle radiansToDegrees estimatedGap: nil candidates: 0 ].
	(self allowsDistanceFor: aDrone) ifTrue: [
		^ MacroSimulatorPerceptionObservation
			status: #direct
			trueGap: trueGap distance: euclidean bearing: relativeAngle radiansToDegrees estimatedGap: trueGap candidates: 1 ].
	(self allowsBearingFor: aDrone) ifFalse: [
		^ MacroSimulatorPerceptionObservation
			status: #noVision
			trueGap: trueGap distance: euclidean bearing: relativeAngle radiansToDegrees estimatedGap: nil candidates: 0 ].
	ray := self rotate: heading byRadians: relativeAngle.
	candidatesInfo := self candidateGapsFrom: aDrone side: aSide ray: ray in: aStep.
	candidates := candidatesInfo first.
	collinear := candidatesInfo second.
	collinear ifTrue: [
		status := #unobservableAlignment.
		estimated := nil ] ifFalse: [
		candidates size = 1
			ifTrue: [ status := #angular. estimated := candidates first ]
			ifFalse: [
				status := candidates isEmpty
					ifTrue: [ #unobservableNoIntersection ]
					ifFalse: [ #unobservableAmbiguous ].
				estimated := nil ] ].
	^ MacroSimulatorPerceptionObservation
		status: status
		trueGap: trueGap
		distance: euclidean
		bearing: relativeAngle radiansToDegrees
		estimatedGap: estimated
		candidates: candidates size' classified: 'observing'.
!

MacroSimulatorHybridPerception compile: 'allowsDistanceFor: drone
	^ drone distanceMeasurementAvailable' classified: 'observing'.
!

MacroSimulatorHybridPerception compile: 'allowsBearingFor: drone
	^ drone visionAvailable' classified: 'observing'.
!

MacroSimulatorSelectablePerception class compile: 'mode: selector
	^ self new initializeMode: selector' classified: 'instance creation'.
!

MacroSimulatorSelectablePerception compile: 'initializeMode: selector
	(#(distance bearing) includes: selector) ifFalse: [ self error: ''Hypothèse de perception inconnue.'' ].
	mode := selector' classified: 'initialization'.
!

MacroSimulatorSelectablePerception compile: 'mode
	^ mode' classified: 'accessing'.
!

MacroSimulatorSelectablePerception compile: 'allowsDistanceFor: drone
	^ mode = #distance and: [ super allowsDistanceFor: drone ]' classified: 'observing'.
!

MacroSimulatorSelectablePerception compile: 'allowsBearingFor: drone
	^ mode = #bearing and: [ super allowsBearingFor: drone ]' classified: 'observing'.
!
