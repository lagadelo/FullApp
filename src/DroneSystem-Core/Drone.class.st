Class {
	#name : 'Drone',
	#superclass : 'Object',
	#instVars : [
		'latitude',
		'longitude',
		'altitude',
		'fuel',
		'consumables',
		'speed',
		'perceptionRange',
		'behavior',
		'uniqueId',
		'type',
		'currentMission',
		'needsHelp',
		'detectedEnemy'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'accessing' }
Drone >> altitude [

	^ altitude
]

{ #category : 'accessing' }
Drone >> altitude: anObject [

	altitude := anObject
]

{ #category : 'as yet unclassified' }
Drone >> applyDamage: damage [
    fuel := (fuel - damage) max: 0.
    speed := (speed - (damage / 10)) max: 0.
    perceptionRange := (perceptionRange - (damage / 20)) max: 0.
    ^ self.
]

{ #category : 'as yet unclassified' }
Drone >> attackDrone: targetDrone withWeapon: weaponName quantity: qty probability: prob impact: impactValue [
   | availableQty hits totalImpact |  (self canPerceiveDrone: targetDrone)
        ifFalse: [ ^'Cible hors de portée' ].
   
    availableQty := consumables at: weaponName ifAbsent: [0].
    (availableQty >= qty)
        ifTrue: [
            consumables at: weaponName put: (availableQty - qty).
            hits := (1 to: qty) count: [:each | (Random new next <= prob)].
            totalImpact := hits * impactValue.
            targetDrone applyDamage: totalImpact.
            ^'Attaque effectuée: ', hits asString, ' coups au but, impact total: ', totalImpact asString
        ]
        ifFalse: [ ^'Pas assez de munitions disponibles' ].

]

{ #category : 'accessing' }
Drone >> behavior [

	^ behavior
]

{ #category : 'accessing' }
Drone >> behavior: anObject [

	behavior := anObject
]

{ #category : 'as yet unclassified' }
Drone >> canPerceiveDrone: otherDrone [
    ^ (self distanceToLatitude: otherDrone latitude longitude: otherDrone longitude altitude: otherDrone altitude) <= perceptionRange.


]

{ #category : 'as yet unclassified' }
Drone >> communicateWithConsensus: consensus [
    consensus receiveStatusMessage: self statusMessage.

]

{ #category : 'accessing' }
Drone >> consumables [

	^ consumables
]

{ #category : 'accessing' }
Drone >> consumables: anObject [

	consumables := anObject
]

{ #category : 'accessing' }
Drone >> currentMission [

	^ currentMission
]

{ #category : 'accessing' }
Drone >> currentMission: anObject [

	currentMission := anObject
]

{ #category : 'as yet unclassified' }
Drone >> deepCopy [
    | d |
    d := self class new initialize.
    d latitude: latitude ifResponds: [] ifFalse: []. "for slot setter compatibility"
    "If direct slot assignment available, use it; otherwise use moveToLatitude:..."
    d moveToLatitude: latitude longitude: longitude altitude: altitude.
    d fuel: fuel.
    d consumables: consumables copy.
    d speed: speed.
    d perceptionRange: perceptionRange.
    d behavior: behavior. "behaviors can be shared or re-instantiated if needed"
    d uniqueId: UUID new asString.
    d type: type.
    d currentMission: currentMission. "will be remapped at cluster copy stage if needed"
    d needsHelp: needsHelp.
    d detectedEnemy: detectedEnemy.
    ^ d.

]

{ #category : 'accessing' }
Drone >> detectedEnemy [

	^ detectedEnemy
]

{ #category : 'accessing' }
Drone >> detectedEnemy: anObject [

	detectedEnemy := anObject
]

{ #category : 'as yet unclassified' }
Drone >> distanceToLatitude: lat longitude: lon altitude: alt [
    ^ ((latitude - lat) squared + (longitude - lon) squared + (altitude - alt) squared) sqrt.

]

{ #category : 'accessing' }
Drone >> fuel [

	^ fuel
]

{ #category : 'accessing' }
Drone >> fuel: anObject [

	fuel := anObject
]

{ #category : 'as yet unclassified' }
Drone >> helpRequestMessage [
    ^ Dictionary new
        at: #type put: #helpRequest;
        at: #from put: uniqueId;
        at: #position put: { latitude. longitude. altitude };
        at: #reason put: 'Low fuel or under attack';
        yourself.
]

{ #category : 'initialization' }
Drone >> initialize [
    latitude := 0.
    longitude := 0.
    altitude := 0.
    fuel := 100.
    consumables := Dictionary new.
    speed := 10.
    perceptionRange := 50.
    behavior := nil.
    uniqueId := UUID new asString.
    type := 'standard'.
    currentMission := nil.
    needsHelp := false.
    detectedEnemy := false.
]

{ #category : 'as yet unclassified' }
Drone >> isDestroyed [
    ^ fuel = 0 or: [speed = 0].
]

{ #category : 'accessing' }
Drone >> latitude [

	^ latitude
]

{ #category : 'accessing' }
Drone >> latitude: anObject [

	latitude := anObject
]

{ #category : 'accessing' }
Drone >> longitude [

	^ longitude
]

{ #category : 'accessing' }
Drone >> longitude: anObject [

	longitude := anObject
]

{ #category : 'initialization' }
Drone >> moveToLatitude: lat longitude: lon altitude: alt [
    | distance fuelConsumed |
    distance := self distanceToLatitude: lat longitude: lon altitude: alt.
    fuelConsumed := distance * (speed / 10).
    (fuel >= fuelConsumed)
        ifTrue: [
            latitude := lat.
            longitude := lon.
            altitude := alt.
            fuel := fuel - fuelConsumed.
        ]
        ifFalse: [ needsHelp := true. Transcript show: 'Drone ', uniqueId, ' low fuel'; cr ].


]

{ #category : 'accessing' }
Drone >> needsHelp [

	^ needsHelp
]

{ #category : 'accessing' }
Drone >> needsHelp: anObject [

	needsHelp := anObject
]

{ #category : 'accessing' }
Drone >> perceptionRange [

	^ perceptionRange
]

{ #category : 'accessing' }
Drone >> perceptionRange: anObject [

	perceptionRange := anObject
]

{ #category : 'as yet unclassified' }
Drone >> sendHelpRequestToConsensus: consensus [
    consensus receiveMessage: self helpRequestMessage.
]

{ #category : 'as yet unclassified' }
Drone >> setBehavior: aBehavior [
    behavior := aBehavior.
]

{ #category : 'accessing' }
Drone >> speed [

	^ speed
]

{ #category : 'accessing' }
Drone >> speed: anObject [

	speed := anObject
]

{ #category : 'as yet unclassified' }
Drone >> statusMessage [
    ^ Dictionary new
        at: #id put: uniqueId;
        at: #position put: { latitude. longitude. altitude };
        at: #fuel put: fuel;
        at: #isDestroyed put: self isDestroyed;
        at: #needsHelp put: needsHelp;
        at: #detectedEnemy put: detectedEnemy;
        yourself.

]

{ #category : 'accessing' }
Drone >> type [

	^ type
]

{ #category : 'accessing' }
Drone >> type: anObject [

	type := anObject
]

{ #category : 'accessing' }
Drone >> uniqueId [

	^ uniqueId
]

{ #category : 'accessing' }
Drone >> uniqueId: anObject [

	uniqueId := anObject
]
