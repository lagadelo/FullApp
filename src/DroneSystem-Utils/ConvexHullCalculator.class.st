Class {
	#name : 'ConvexHullCalculator',
	#superclass : 'Object',
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> convexHullGeoVerbose: drones [
    
    | sorted lower upper epsilon |

    epsilon := 0.0.
    sorted := drones sort: [:a :b | (a longitude) <= (b longitude)].
 
    lower := OrderedCollection new.
     sorted do: [:p | 
        [ lower size >= 2 and: [
            (self turnGeo: (lower at: lower size - 1) to: (lower last) to: p) <  epsilon 
        ]] whileTrue: [ lower removeLast ].
        lower add: p.
    ].
 
     
    upper := OrderedCollection new.
      sorted reversed  do: [:p |
        [ upper size >= 2 and: [  
            (self turnGeo: (upper at: upper size - 1) to: (upper last) to: p)  < epsilon  
        ]] whileTrue: [   upper removeLast    ].
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
    sorted := points sort: [:a :b | (a x) < (b x )].

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
ConvexHullCalculator >> hullForGeoPoints: points [
    
    | sorted lower upper epsilon |

    epsilon := 0.
    sorted := points asSet asOrderedCollection  sort: [:a :b | (a longitude) < (b longitude) | (a longitude = b longitude & (a latitude < b latitude))].
 
    lower := OrderedCollection new.
     sorted do: [:p | 
        [ lower size >= 2 and: [
            (self turnGeo: (lower at: lower size - 1) to: (lower last) to: p) <  epsilon 
        ]] whileTrue: [ lower removeLast ].
        lower add: p.
    ].
 
     
    upper := OrderedCollection new.
      sorted reversed  do: [:p |
        [ upper size >= 2 and: [  
            (self turnGeo: (upper at: upper size - 1) to: (upper last) to: p)  < epsilon  
        ]] whileTrue: [   upper removeLast    ].
         upper add: p.
    ].
 

    "Concatène lower et upper sans répéter les extrémités"
   lower removeLast.
    upper removeLast.

    ^ (lower , upper) asArray
]

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> hullForPoints: points [
    
    | sorted lower upper epsilon |

    epsilon := 0.0.
    sorted := points asSet asOrderedCollection sort: [:a :b | (a x) < (b x) | (a x = b x & (a y < b y))].
 
    lower := OrderedCollection new.
     sorted do: [:p | 
        [ lower size >= 2 and: [
            (self turn: (lower at: lower size - 1) to: (lower last) to: p) <  epsilon 
        ]] whileTrue: [ lower removeLast ].
        lower add: p.
    ].
 
     
    upper := OrderedCollection new.
      sorted reversed  do: [:p |
        [ upper size >= 2 and: [  
            (self turn: (upper at: upper size - 1) to: (upper last) to: p)  < epsilon  
        ]] whileTrue: [   upper removeLast    ].
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

	^ b x - a x * (c y - a y) - (b y - a y * (c x - a x))
]

{ #category : 'as yet unclassified' }
ConvexHullCalculator >> turnGeo: a to: b to: c [
  "Le signe du résultat indique l’orientation du triplet (a, b, c) :
Résultat	Signification
> 0	 c est à gauche de la droite a→b
< 0 	c est à droite de la droite a→b
= 0 	a, b et c sont alignés (colinéaires)"
 
    ^ ((b longitude) - (a longitude)) * ((c latitude) - (a latitude)) 
      - (((b latitude) - (a latitude)) * ((c longitude) - (a longitude)))

 
]
