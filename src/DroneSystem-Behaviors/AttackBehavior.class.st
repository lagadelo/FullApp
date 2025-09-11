Class {
	#name : 'AttackBehavior',
	#superclass : 'Object',
	#instVars : [
		'weaponName',
		'quantity',
		'probability',
		'impact',
		'targetSelector'
	],
	#category : 'DroneSystem-Behaviors',
	#package : 'DroneSystem-Behaviors'
}

{ #category : 'initialization' }
AttackBehavior >> executeFor: aDrone atTime: t [
    | enemies nearest |
    SimulationState current ifNil: [ ^ self ].
    enemies := SimulationState current allAlliedDrones select: [:a | a isDestroyed not].
    enemies isEmpty ifTrue: [ ^ self ].
    nearest := enemies first.
    enemies do: [:e | ((aDrone distanceToLatitude: e latitude longitude: e longitude altitude: e altitude) < (aDrone distanceToLatitude: nearest latitude longitude: nearest longitude altitude: nearest altitude)) ifTrue: [ nearest := e ] ].
    aDrone moveToLatitude: ((aDrone latitude + nearest latitude) / 2) longitude: ((aDrone longitude + nearest longitude) / 2) altitude: ((aDrone altitude + nearest altitude) / 2).
    (aDrone canPerceiveDrone: nearest) ifTrue: [
        | impact hits |
        impact := 10.
        hits := (Random new next) <= 0.6 ifTrue: [ 1 ] ifFalse: [ 0 ].
        nearest applyDamage: hits * impact.
        Transcript show: 'Aggressive: ', aDrone uniqueId, ' attacked ', nearest uniqueId, ' hits=', hits asString; cr.
    ].
    ^ self.

]

{ #category : 'accessing' }
AttackBehavior >> impact [

	^ impact
]

{ #category : 'accessing' }
AttackBehavior >> impact: anObject [

	impact := anObject
]

{ #category : 'initialization' }
AttackBehavior >> initializeWithWeapon: w qty: q prob: p impact: i targetSelector: sel [
    weaponName := w. quantity := q. probability := p. impact := i. targetSelector := sel. ^ self.

]

{ #category : 'accessing' }
AttackBehavior >> probability [

	^ probability
]

{ #category : 'accessing' }
AttackBehavior >> probability: anObject [

	probability := anObject
]

{ #category : 'accessing' }
AttackBehavior >> quantity [

	^ quantity
]

{ #category : 'accessing' }
AttackBehavior >> quantity: anObject [

	quantity := anObject
]

{ #category : 'accessing' }
AttackBehavior >> targetSelector [

	^ targetSelector
]

{ #category : 'accessing' }
AttackBehavior >> targetSelector: anObject [

	targetSelector := anObject
]

{ #category : 'accessing' }
AttackBehavior >> weaponName [

	^ weaponName
]

{ #category : 'accessing' }
AttackBehavior >> weaponName: anObject [

	weaponName := anObject
]

{ #category : 'initialization' }
AttackBehavior >> xecuteFor: aDrone atTime: t [
    | targets target  available hits totalImpact |
    targets := targetSelector value: aDrone.
    targets isEmpty ifTrue: [ ^ self ].
    target := targets first.
    (aDrone canPerceiveDrone: target) ifFalse: [ ^ self ].
    
    available := aDrone consumables at: weaponName ifAbsent: [ 0 ].
    (available >= quantity) ifFalse: [ ^ self ].
    aDrone consumables at: weaponName put: (available - quantity).
    hits := (1 to: quantity) count: [:each | (Random new next) <= probability ].
    totalImpact := hits * impact.
    target applyDamage: totalImpact.
    Transcript show: 'Time ', t printString, ' - ', aDrone uniqueId, ' attacked ', target uniqueId, ' hits=', hits asString, ' impact=', totalImpact asString; cr.
    ^ self.

]
