Class {
	#name : 'AggressiveBehavior',
	#superclass : 'Object',
	#category : 'DroneSystem-Behaviors',
	#package : 'DroneSystem-Behaviors'
}

{ #category : 'as yet unclassified' }
AggressiveBehavior >> computeHullFrom: points [
    | sorted hull |
    sorted := points sort: [:a :b | (a at: 1) < (b at: 1) ].
    hull := OrderedCollection new.
    sorted do: [:p |
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ] whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    sorted reversed do: [:p |
        [ hull size >= 2 and: [ self turn: (hull at: hull size - 1) to: (hull last) to: p ] <= 0 ] whileTrue: [ hull removeLast ].
        hull add: p.
    ].
    ^ hull asArray.
]
