Class {
	#name : 'EventDependencyGraph',
	#superclass : 'Object',
	#instVars : [
		'nodes',
		'edges',
		'scheduler'
	],
	#category : 'DroneSystem-Simulation',
	#package : 'DroneSystem-Simulation'
}

{ #category : 'adding' }
EventDependencyGraph >> addEvent: anEvent withDependencies: dependencies [
    nodes add: anEvent.
    dependencies do: [:dep |
        nodes add: dep.
        (edges at: dep ifAbsentPut: [Set new]) add: anEvent.
    ].
]

{ #category : 'as yet unclassified' }
EventDependencyGraph >> allDescendantsOf: anEvent [
    | result queue current |
    result := Set new.
    queue := OrderedCollection with: anEvent.
    [ queue isEmpty ] whileFalse: [
        current := queue removeFirst.
        (edges at: current ifAbsent: [#()]) do: [:succ |
            (result includes: succ) ifFalse: [
                result add: succ.
                queue add: succ.
            ].
        ].
    ].
    ^ result.
]

{ #category : 'printing' }
EventDependencyGraph >> asDotString [
    | lines |
    lines := OrderedCollection new.
    lines add: 'digraph EventGraph {'.

    edges keysAndValuesDo: [:from :toSet |
        toSet do: [:to |
            lines add: '    "', from eventId, '" -> "', to eventId, '".'.
        ].
    ].

    lines add: '}'.
    ^ String join: lines with: String cr.
]

{ #category : 'accessing' }
EventDependencyGraph >> edges [

	^ edges
]

{ #category : 'accessing' }
EventDependencyGraph >> edges: anObject [

	edges := anObject
]

{ #category : 'as yet unclassified' }
EventDependencyGraph >> initialize [

nodes := OrderedCollection new.
edges := Dictionary new.

]

{ #category : 'as yet unclassified' }
EventDependencyGraph >> invalidateCascadeFrom: rootEvent [
    | toRemove |
    toRemove := self allDescendantsOf: rootEvent.
    toRemove add: rootEvent.

    toRemove do: [:e |
	
	self error:'attention a la visibilite du scheduler'.
   "     scheduler removeEvent: e.
        self removeEventFromEntityMap: e."
    ].
]

{ #category : 'testing' }
EventDependencyGraph >> isReady: anEvent [
    ^ (self dependenciesOf: anEvent) allSatisfy: [:dep | dep hasExecuted].

]

{ #category : 'accessing' }
EventDependencyGraph >> nodes [

	^ nodes
]

{ #category : 'accessing' }
EventDependencyGraph >> nodes: anObject [

	nodes := anObject
]
