Class {
	#name : 'ConvexHullCalculator',
	#superclass : 'Object',
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> convexHullGeoVerbose: drones [
    
    | sorted lower upper epsilon |

    epsilon := 1e-10.
    sorted := drones sort: [:a :b | (a latitude) < (b latitude)].

    lower := OrderedCollection new.
    sorted do: [:p | 
        [ lower size >= 2 and: [
            (self turnGeo: (lower at: lower size - 1) to: (lower last) to: p) <  epsilon negated
        ]] whileTrue: [ lower removeLast ].
        lower add: p.
    ].

    upper := OrderedCollection new.
    sorted reversed do: [:p | 
        [ upper size >= 2 and: [
            (self turnGeo: (upper at: upper size - 1) to: (upper last) to: p) < epsilon negated
        ]] whileTrue: [ upper removeLast ].
        upper add: p.
    ].

    "Concatène lower et upper sans répéter les extrémités"
    lower removeLast.
    upper removeLast.

    ^ (lower , upper) asArray
]

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> convexHullVerbose: points [
    
    | sorted lower upper epsilon |

    epsilon := 1e-10.
    sorted := points sort: [:a :b | (a at: 1) < (b at: 1)].

    lower := OrderedCollection new.
    sorted do: [:p | 
        [ lower size >= 2 and: [
            (self turn: (lower at: lower size - 1) to: (lower last) to: p) <  epsilon negated
        ]] whileTrue: [ lower removeLast ].
        lower add: p.
    ].

    upper := OrderedCollection new.
    sorted reversed do: [:p | 
        [ upper size >= 2 and: [
            (self turn: (upper at: upper size - 1) to: (upper last) to: p) < epsilon negated
        ]] whileTrue: [ upper removeLast ].
        upper add: p.
    ].

    "Concatène lower et upper sans répéter les extrémités"
    lower removeLast.
    upper removeLast.

    ^ (lower , upper) asArray
]

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> turn: a to: b to: c [
  "Le signe du résultat indique l’orientation du triplet (a, b, c) :
Résultat	Signification
> 0	c est à gauche de la droite a→b
< 0	c est à droite de la droite a→b
= 0	a, b et c sont alignés (colinéaires)"
 
    ^ ((b at: 1) - (a at: 1)) * ((c at: 2) - (a at: 2)) 
      - ((b at: 2) - (a at: 2)) * ((c at: 1) - (a at: 1))
]

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> turnGeo: a to: b to: c [
  "Le signe du résultat indique l’orientation du triplet (a, b, c) :
Résultat	Signification
> 0	c est à gauche de la droite a→b
< 0	c est à droite de la droite a→b
= 0	a, b et c sont alignés (colinéaires)"
 
    ^ ((b latitude) - (a latitude)) * ((c longitude) - (a longitude)) 
      - ((b longitude) - (a longitude)) * ((c latitude) - (a latitude))
]
