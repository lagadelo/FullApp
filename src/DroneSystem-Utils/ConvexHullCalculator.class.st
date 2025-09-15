Class {
	#name : 'ConvexHullCalculator',
	#superclass : 'Object',
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> computeHullFrom: points [
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

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> turn: a to: b to: c [
    ^ ((b at: 1) - (a at: 1)) * ((c at: 2) - (a at: 2)) - ((b at: 2) - (a at: 2)) * ((c at: 1) - (a at: 1)).
            

]
