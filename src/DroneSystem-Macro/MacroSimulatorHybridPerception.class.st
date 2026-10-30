Class {
	#name : 'MacroSimulatorHybridPerception',
	#superclass : 'MacroSimulatorPerceptionModel',
	#instVars : [
		'intersectionEpsilon'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'private - candidates' }
MacroSimulatorHybridPerception >> addCandidateGap: aGap to: aCollection [
	| duplicate |
	duplicate := aCollection anySatisfy: [ :existing |
		(existing - aGap) abs <= (self intersectionEpsilon * 100.0) ].
	duplicate ifFalse: [ aCollection add: aGap ]
]

{ #category : 'private - candidates' }
MacroSimulatorHybridPerception >> candidateGapsFrom: aDrone side: aSide ray: rayDirection in: aStep [
	| parameters origin candidates collinear n |
	parameters := aStep simulator parameters.
	origin := aStep realPositionOfDrone: aDrone.
	candidates := OrderedCollection new.
	collinear := false.
	n := parameters wayPoints size.
	1 to: n do: [ :i |
		| q q2 result candidateArc gap |
		q := parameters localXYOf: (parameters wayPoints at: i) relativeTo: origin.
		q2 := parameters
			localXYOf: (parameters wayPoints at: i \ n + 1)
			relativeTo: origin.
		result := self
			rayDirection: rayDirection
			intersectionWithSegmentFrom: q
			to: q2
			maxDistance: aDrone sensingRadius.
		result = #collinear
			ifTrue: [ collinear := true ]
			ifFalse: [ result ifNotNil: [
				candidateArc := parameters arcPositionAtSegment: i fraction: result second.
				gap := aSide = #ahead
					ifTrue: [ candidateArc - aDrone position \ aStep range ]
					ifFalse: [ aDrone position - candidateArc \ aStep range ].
				gap > self intersectionEpsilon ifTrue: [
					self addCandidateGap: gap to: candidates ] ] ] ].
	^ Array with: candidates with: collinear
]

{ #category : 'private - vectors' }
MacroSimulatorHybridPerception >> cross: firstVector with: secondVector [
	^ (firstVector x * secondVector y) - (firstVector y * secondVector x)
]

{ #category : 'private - vectors' }
MacroSimulatorHybridPerception >> dot: firstVector with: secondVector [
	^ (firstVector x * secondVector x) + (firstVector y * secondVector y)
]

{ #category : 'observing' }
MacroSimulatorHybridPerception >> gapAheadDrone: aDrone in: aStep [
	^ (self observationAheadDrone: aDrone in: aStep) estimatedGap
]

{ #category : 'observing' }
MacroSimulatorHybridPerception >> gapBackwardDrone: aDrone in: aStep [
	^ (self observationBackwardDrone: aDrone in: aStep) estimatedGap
]

{ #category : 'accessing' }
MacroSimulatorHybridPerception >> intersectionEpsilon [
	^ intersectionEpsilon ifNil: [ 1.0e-7 ]
]

{ #category : 'accessing' }
MacroSimulatorHybridPerception >> intersectionEpsilon: aNumber [
	intersectionEpsilon := aNumber abs
]

{ #category : 'private - vectors' }
MacroSimulatorHybridPerception >> normOf: aVector [
	^ ((aVector x * aVector x) + (aVector y * aVector y)) sqrt
]

{ #category : 'private - vectors' }
MacroSimulatorHybridPerception >> normalized: aVector [
	| n |
	n := self normOf: aVector.
	n <= self intersectionEpsilon ifTrue: [ ^ nil ].
	^ (aVector x / n) @ (aVector y / n)
]

{ #category : 'observing' }
MacroSimulatorHybridPerception >> observationAheadDrone: aDrone in: aStep [
	^ self
		observationOf: aDrone
		target: (aStep predecessorOf: aDrone)
		side: #ahead
		in: aStep
]

{ #category : 'observing' }
MacroSimulatorHybridPerception >> observationBackwardDrone: aDrone in: aStep [
	^ self
		observationOf: aDrone
		target: (aStep successorOf: aDrone)
		side: #backward
		in: aStep
]

{ #category : 'observing' }
MacroSimulatorHybridPerception >> observationOf: aDrone target: targetDrone side: aSide in: aStep [
	| parameters observerPoint targetPoint targetVector targetUnit heading relativeAngle ray trueGap euclidean candidatesInfo candidates collinear status estimated |
	parameters := aStep simulator parameters.
	parameters wayPoints ifNil: [
		self error: 'MacroSimulatorHybridPerception requires ordered wayPoints on the simulator parameters' ].
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
	aDrone distanceMeasurementAvailable ifTrue: [
		^ MacroSimulatorPerceptionObservation
			status: #direct
			trueGap: trueGap distance: euclidean bearing: relativeAngle radiansToDegrees estimatedGap: trueGap candidates: 1 ].
	aDrone visionAvailable ifFalse: [
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
		candidates: candidates size
]

{ #category : 'private - intersection' }
MacroSimulatorHybridPerception >> rayDirection: rayDirection intersectionWithSegmentFrom: q to: q2 maxDistance: maxDistance [
	"Observer is the origin. Return #collinear, nil or {rayDistance . segmentFraction}."
	| s denominator qCrossS qCrossR t u projection1 projection2 minProjection maxProjection |
	s := (q2 x - q x) @ (q2 y - q y).
	denominator := self cross: rayDirection with: s.
	denominator abs <= self intersectionEpsilon ifTrue: [
		((self cross: q with: rayDirection) abs <= self intersectionEpsilon) ifFalse: [ ^ nil ].
		projection1 := self dot: q with: rayDirection.
		projection2 := self dot: q2 with: rayDirection.
		minProjection := projection1 min: projection2.
		maxProjection := projection1 max: projection2.
		(maxProjection > self intersectionEpsilon and: [ minProjection < maxDistance ])
			ifTrue: [ ^ #collinear ].
		^ nil ].
	qCrossS := self cross: q with: s.
	qCrossR := self cross: q with: rayDirection.
	t := qCrossS / denominator.
	u := qCrossR / denominator.
	(t > self intersectionEpsilon
		and: [ t <= maxDistance + self intersectionEpsilon
		and: [ u >= 0.0 - self intersectionEpsilon
		and: [ u <= 1.0 + self intersectionEpsilon ] ] ]) ifFalse: [ ^ nil ].
	^ Array with: t with: ((u max: 0.0) min: 1.0)
]

{ #category : 'private - vectors' }
MacroSimulatorHybridPerception >> rotate: aVector byRadians: anAngle [
	| c s |
	c := anAngle cos.
	s := anAngle sin.
	^ ((aVector x * c) - (aVector y * s))
		@ ((aVector x * s) + (aVector y * c))
]
