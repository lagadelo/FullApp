"
Index des passages encore frais pour un état du simulateur. Les positions
conservent leur abscisse exacte sur la boucle. Les lots expirés sont retirés
et les abscisses sont indexées à la première consultation après un tik.
"
Class {
	#name : 'MacroSimulatorPassageWindow',
	#superclass : 'Object',
	#instVars : [ 'maxDate', 'secondsPerTick', 'now', 'range', 'batches', 'byPosition', 'positions' ],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
MacroSimulatorPassageWindow class >> maxDate: limit secondsPerTick: duration [
	^ self new initializeMaxDate: limit secondsPerTick: duration
]

{ #category : 'initialization' }
MacroSimulatorPassageWindow >> initializeMaxDate: limit secondsPerTick: duration [
	maxDate := limit.
	secondsPerTick := duration.
	batches := OrderedCollection new
]

{ #category : 'recording' }
MacroSimulatorPassageWindow >> recordStep: step [
	| tick |
	tick := step timeStep.
	now := tick * secondsPerTick.
	range := step range.
	[ batches notEmpty and: [ (self includesTick: batches first key at: tick) not ] ]
		whileTrue: [ batches removeFirst ].
	step drones ifNotEmpty: [
		batches addLast: tick -> (step drones collect: [ :drone |
			PointDePassage
				position: (drone position \\ range)
				date: now
				droneId: drone id ]) ].
	byPosition := nil.
	positions := nil
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> includesTick: earlier at: current [
	^ (current - earlier) * secondsPerTick <= (maxDate + self ageTolerance)
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> ageTolerance [
	^ maxDate * 1.0e-9
]

{ #category : 'accessing' }
MacroSimulatorPassageWindow >> passages [
	^ (batches flatCollect: #value) asArray
]

{ #category : 'indexing' }
MacroSimulatorPassageWindow >> buildPositionIndex [
	positions ifNotNil: [ ^ self ].
	byPosition := Dictionary new.
	batches do: [ :batch |
		batch value do: [ :passage |
			byPosition at: passage position put: passage ] ].
	positions := byPosition keys sorted
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> firstPassageAheadOf: position [
	| origin low high middle |
	self buildPositionIndex.
	positions ifEmpty: [ ^ nil ].
	origin := position \\ range.
	low := 1.
	high := positions size + 1.
	[ low < high ] whileTrue: [
		middle := (low + high) // 2.
		(positions at: middle) <= origin
			ifTrue: [ low := middle + 1 ]
			ifFalse: [ high := middle ] ].
	low <= positions size ifTrue: [ ^ byPosition at: (positions at: low) ].
	positions first < origin ifTrue: [ ^ byPosition at: positions first ].
	^ nil
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> freshnessGapAheadOf: position [
	| passage |
	passage := self firstPassageAheadOf: position.
	^ passage
		ifNil: [ Float infinity ]
		ifNotNil: [ self distanceFrom: position to: passage ]
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> distanceFrom: position to: passage [
	^ (passage position - (position \\ range)) \\ range
]

{ #category : 'querying' }
MacroSimulatorPassageWindow >> freshnessOf: passage [
	| remaining |
	remaining := maxDate - (now - passage date).
	^ remaining > self ageTolerance ifTrue: [ remaining ] ifFalse: [ 0 ]
]
