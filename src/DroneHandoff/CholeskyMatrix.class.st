"
On part d'une matrice de corrélation 
La décomposition de Cholesky factorise 
Σ = L. T(L) avec L la triangulaire inférieure.

On tire n variables indépendantes puis on les corrèle  
Les composantes de 
x sont alors distribuées selon N(0,Σ),  corrélées comme voulu.
"
Class {
	#name : 'CholeskyMatrix',
	#superclass : 'Object',
	#instVars : [
		'l',
		'n'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'instance cre' }
CholeskyMatrix class >> from: corrMatrix [ 
    "corrMatrix : Array2D ou Array of Arrays, valeurs dans [-1,1]"
    ^ self new initFrom: corrMatrix
]

{ #category : 'running' }
CholeskyMatrix >> correlate: zArray [ 
    "zArray : n tirages indépendants N(0,1)
     retourne x = L·z avec corrélations"
    | x |
    x := Array new: n withAll: 0.0.
    1 to: n do: [ :i |
        | sum |
        sum := (1 to: i) inject: 0.0
            into: [ :acc :j | acc + (((l at: i) at: j) * (zArray at: j)) ].
        x at: i put: sum.
    ].
    ^ x
]

{ #category : 'initialize' }
CholeskyMatrix >> initFrom: corr [

	self n: corr size.
	self l: ((Array new: n) collect: [ :x | Array new: n ]).
	1 to: n do: [ :i |
			1 to: i do: [ :j |
					| sum val |
					sum := (1 to: j - 1)
						       inject: 0.0
						       into: [ :acc :k |
						       acc + (((l at: i) at: k) * ((l at: j) at: k)) ].
					val := i = j
						       ifTrue: [ (((corr at: i) at: i) - sum) sqrt ]
						       ifFalse: [
						       ((corr at: i) at: j) - sum / ((l at: j) at: j) ].
					(l at: i) at: j put: val ] ]
]

{ #category : 'accessing' }
CholeskyMatrix >> l [

	^ l
]

{ #category : 'accessing' }
CholeskyMatrix >> l: anObject [

	l := anObject
]

{ #category : 'accessing' }
CholeskyMatrix >> n [

	^ n
]

{ #category : 'accessing' }
CholeskyMatrix >> n: anObject [

	n := anObject
]
