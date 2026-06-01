Class {
	#name : 'DronePerceptionChain',
	#superclass : 'Object',
	#instVars : [
		'tRevisit',
		'tDetect',
		'tTrackInit',
		'tClass',
		'tQualif',
		'tEvidence',
		'tQueueEdge',
		'tTx',
		'tFuse',
		'tDecide',
		'cholesky',
		'rng',
		'params'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'accessing' }
DronePerceptionChain >> cholesky [

	^ cholesky
]

{ #category : 'accessing' }
DronePerceptionChain >> cholesky: anObject [

	cholesky := anObject
]

{ #category : 'accessing' }
DronePerceptionChain >> correlationMatrix: aMatrix [
	"Installe une CholeskyMatrix à partir d'une matrice de corrélation 10x10.
     Mettre à nil pour revenir aux tirages indépendants."

	cholesky := CholeskyMatrix from: aMatrix
]

{ #category : 'initializing' }
DronePerceptionChain >> initialize [

	rng := Random new.
	cholesky := nil.
	"Ordre canonique des 10 paramètres avec valeurs par défaut N(mean, 20% stddev)"
	params := OrderedCollection new.
	#( 4.0 0.5 2.0 1.5 1.0 2.0 0.3 0.2 3.0 5.0 ) do: [ :mean |
		params add: (StochasticParam normal: mean stddev: mean * 0.2) ] "1  tRevisit" "2  tDetect" "3  tTrackInit" "4  tClass" "5  tQualif" "6  tEvidence" "7  tQueueEdge" "8  tTx" "9  tFuse" "10 tDecide"
]

{ #category : 'accessing' }
DronePerceptionChain >> paramAt: index [

	^ params at: index
]

{ #category : 'accessing' }
DronePerceptionChain >> paramAt: index put: aStochasticParam [

	params at: index put: aStochasticParam
]

{ #category : 'printing' }
DronePerceptionChain >> printBreakdownOn: aStream [ 
    | names |
    names := #( 'tRevisit' 'tDetect' 'tTrackInit' 'tClass' 'tQualif'
                'tEvidence' 'tQueueEdge' 'tTx' 'tFuse' 'tDecide' ).
    aStream nextPutAll: '=== Perception Chain ==='; nl.
    params keysAndValuesDo: [ :p :i |
        aStream
            nextPutAll: ('  ', (names at: i), ' : μ=', p paramA printString,
                         ' s  σ=', p paramB printString, ' s');
            cr.
    ].
    aStream
        nextPutAll: ('  Cholesky : ', (cholesky isNil ifTrue: ['off'] ifFalse: ['ON']));
        cr.

]

{ #category : 'accessing' }
DronePerceptionChain >> removeCorrelation [ 
    cholesky := nil
]

{ #category : 'accessing' }
DronePerceptionChain >> rng [

	^ rng
]

{ #category : 'accessing' }
DronePerceptionChain >> rng: anObject [

	rng := anObject
]

{ #category : 'computing' }
DronePerceptionChain >> sampleSeconds [

	| z x total |
	cholesky ifNil: [
		^ params inject: 0.0 into: [ :sum :p | sum + p sample ] ].
	z := (1 to: params size) collect: [ :_ | self sampleStandardNormal ].
	x := cholesky correlate: z asArray.
	total := 0.0.
	params keysAndValuesDo: [ :i :p |
		total := total + (p paramA + (p paramB * (x at: i)) max: 0.0) ].
	^ total
]

{ #category : 'running' }
DronePerceptionChain >> sampleStandardNormal [

	| u1 u2 |
	u1 := rng next max: 1e-12. "évite log(0)"
	u2 := rng next.
	^ (-2.0 * u1 ln) sqrt * (2.0 * Float pi * u2) cos
]

{ #category : 'accessing' }
DronePerceptionChain >> tClass [

	^ self paramAt: 4
]

{ #category : 'accessing' }
DronePerceptionChain >> tClass: p [

	^ self paramAt: 4 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tDecide [

	^ self paramAt: 10
]

{ #category : 'accessing' }
DronePerceptionChain >> tDecide: p [

	^ self paramAt: 10 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tDetect [

	^ self paramAt: 2
]

{ #category : 'accessing' }
DronePerceptionChain >> tDetect: p [

	^ self paramAt: 2 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tEvidence [

	^ self paramAt: 6
]

{ #category : 'accessing' }
DronePerceptionChain >> tEvidence: p [

	^ self paramAt: 6 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tFuse [

	^ self paramAt: 9
]

{ #category : 'accessing' }
DronePerceptionChain >> tFuse: p [

	^ self paramAt: 9 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tQualif [

	^ self paramAt: 5
]

{ #category : 'accessing' }
DronePerceptionChain >> tQualif: p [

	^ self paramAt: 5 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tQueueEdge [

	^ self paramAt: 7
]

{ #category : 'accessing' }
DronePerceptionChain >> tQueueEdge: p [

	^ self paramAt: 7 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tRevisit [

	^ self paramAt: 1
]

{ #category : 'accessing' }
DronePerceptionChain >> tRevisit: p [

	^ self paramAt: 1 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tTrackInit [

	^ self paramAt: 3
]

{ #category : 'accessing' }
DronePerceptionChain >> tTrackInit: p [

	^ self paramAt: 3 put: p
]

{ #category : 'accessing' }
DronePerceptionChain >> tTx [

	^ self paramAt: 8
]

{ #category : 'accessing' }
DronePerceptionChain >> tTx: p [

	^ self paramAt: 8 put: p
]

{ #category : 'computing' }
DronePerceptionChain >> totalSeconds [
	"Somme de tous les délais de la chaîne de perception"

	^ tRevisit + tDetect + tTrackInit + tClass + tQualif + tEvidence
	  + tQueueEdge + tTx + tFuse + tDecide
]
