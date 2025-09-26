Class {
	#name : 'Drone',
	#superclass : 'Object',
	#instVars : [
		'geoPoint',
		'fuel',
		'consumables',
		'speed',
		'perceptionRange',
		'behavior',
		'uniqueId',
		'type',
		'currentMission',
		'needsHelp',
		'detectedEnemy',
		'health',
		'isHostile'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'as yet unclassified' }
Drone class >> LandingBase [

^GeoPoint with: {44.1483  . 4.8597 . 0} 
]

{ #category : 'examples' }
Drone class >> example [
^self new initializeWithId: (Random new next *10000000) ceiling
            latitude: (Random new next *4)+41
            longitude: (Random new next *8)-    4
        altitude: (Random new next *100) 
]

{ #category : 'visiting' }
Drone >> accept: aVisitor [

^aVisitor visitDrone: self 
]

{ #category : 'accessing' }
Drone >> altitude [

	^ self geoPoint altitude
]

{ #category : 'accessing' }
Drone >> altitude: anObject [

	self geoPoint altitude: anObject
]

{ #category : 'damages' }
Drone >> applyDamage: damage [
    fuel := (fuel - damage) max: 0.
    speed := (speed - (damage / 10)) max: 0.
    perceptionRange := (perceptionRange - (damage / 20)) max: 0.
    ^ self.
]

{ #category : 'action' }
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

{ #category : 'initialization' }
Drone >> beAlly [

isHostile := false
]

{ #category : 'initialization' }
Drone >> beHostile [

isHostile := true
]

{ #category : 'accessing' }
Drone >> behavior [

	^ behavior
]

{ #category : 'accessing' }
Drone >> behavior: anObject [

	behavior := anObject
]

{ #category : 'testing' }
Drone >> canPerceiveDrone: otherDrone [
    ^ (self distanceToLatitude: otherDrone latitude longitude: otherDrone longitude altitude: otherDrone altitude) <= perceptionRange.


]

{ #category : 'action' }
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

{ #category : 'action' }
Drone >> consumeFuel: amount [
	"Réduit le niveau de carburant/énergie"

	fuel := fuel - amount.
	fuel := fuel max: 0
]

{ #category : 'accessing' }
Drone >> currentMission [

	^ currentMission
]

{ #category : 'accessing' }
Drone >> currentMission: anObject [

	currentMission := anObject
]

{ #category : 'copying' }
Drone >> deepCopy [
    | d |
    d := self class new initialize.
    d latitude: latitude . "for slot setter compatibility"
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

{ #category : 'computing' }
Drone >> distanceToLatitude: lat longitude: lon altitude: alt [
    "Calcule la distance approximative en km entre la position actuelle et une nouvelle coordonnée."
    | dLat dLon meanLat earthRadius horizDist altDiff |
    earthRadius := 6371.0. "km, rayon moyen Terre"
    dLat := (lat - latitude) degreesToRadians.
    dLon := (lon - longitude) degreesToRadians.
    meanLat := ((lat + latitude) / 2) degreesToRadians.
    horizDist := earthRadius * ((dLat squared + ((dLon * meanLat cos) squared)) sqrt).
    altDiff := (alt - altitude) / 1000.0. "convertir mètres → km"
    ^ (horizDist squared + altDiff squared) sqrt.
]

{ #category : 'accessing' }
Drone >> fuel [

	^ fuel
]

{ #category : 'accessing' }
Drone >> fuel: anObject [

	fuel := anObject
]

{ #category : 'accessing' }
Drone >> geoPoint [ 

 ^geoPoint 
]

{ #category : 'accessing' }
Drone >> geoPoint: a [

geoPoint := a
]

{ #category : 'accessing' }
Drone >> health [

	^ health
]

{ #category : 'accessing' }
Drone >> health: anObject [

	health := anObject
]

{ #category : 'action' }
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
 	geoPoint := self class LandingBase.
    fuel := 100.
    consumables := Dictionary new.
    consumables at:#munitions put:1000.
    speed := 10.
	 health := 100.
    perceptionRange := 50.
    behavior := nil.
    uniqueId := UUID new asString.
    type := 'standard'.
    currentMission := nil.
    needsHelp := false.
    detectedEnemy := false.
	isHostile:= false.
]

{ #category : 'initialization' }
Drone >> initializeWithId: id
            latitude: aLatitude
            longitude: aLongiture
            altitude: anAltitude [ 

  
self latitude: aLatitude .
self longitude: aLongiture .
self altitude: anAltitude .
uniqueId :=  id.
]

{ #category : 'initialization' }
Drone >> isAlly [

^isHostile not
]

{ #category : 'testing' }
Drone >> isDestroyed [
    ^ fuel = 0 or: [speed = 0].
]

{ #category : 'testing' }
Drone >> isHostile [

	^ isHostile
]

{ #category : 'testing' }
Drone >> isHostile: anObject [

	isHostile := anObject
]

{ #category : 'testing' }
Drone >> isInDanger [
    ^ (health < 50) or: [ fuel < 20 ].
]

{ #category : 'accessing' }
Drone >> latitude [

	^ self geoPoint latitude
]

{ #category : 'accessing' }
Drone >> latitude: anObject [

	self geoPoint latitude: anObject
]

{ #category : 'accessing' }
Drone >> longitude [

	^ self geoPoint longitude
]

{ #category : 'accessing' }
Drone >> longitude: anObject [

	self geoPoint longitude: anObject
]

{ #category : 'moving' }
Drone >> moveTo:aGeoPoint [
    "Déplace le drone et consomme de l’énergie proportionnellement au trajet."
    | distance baseCost altitudeFactor totalCost |
    distance := self position distanceTo: aGeoPoint.
    baseCost := distance * 0.005.          "0.5% par km"
    altitudeFactor := (aGeoPoint altitude - self altitude / 1000.0) * 0.2.  "pénalité altitude"
    totalCost := baseCost + altitudeFactor.

    self consumeFuel: totalCost.
    "Mettre à jour la position uniquement si le drone est encore actif"
    self isDestroyed ifFalse: [
        self position: aGeoPoint]
]

{ #category : 'moving' }
Drone >> moveToLatitude: lat longitude: lon altitude: alt [


"legacy - should refactor"

^self moveTo: (GeoPoint with: (Array with: lat with: lon with: alt))
]

{ #category : 'moving' }
Drone >> moveTowardGeoPoint: aGeoPoint [
    "Se rapproche d'une cible (pas fixe en degrés/altitude)"
    | step dLat dLon dAlt |
    step := 0.01. "environ 1 km en latitude/longitude"
aGeoPoint - self position.

"
    latitude := latitude + (dLat sign * (step min: dLat abs)).
    longitude := longitude + (dLon sign * (step min: dLon abs)).
    altitude := altitude + (dAlt sign * (5 min: dAlt abs)). ""5 m par pas"
]

{ #category : 'moving' }
Drone >> moveTowardLatitude: targetLat longitude: targetLon altitude: targetAlt [
    "Se rapproche d'une cible (pas fixe en degrés/altitude)"
    | step dLat dLon dAlt |
    step := 0.01. "environ 1 km en latitude/longitude"
    dLat := targetLat - latitude.
    dLon := targetLon - longitude.
    dAlt := targetAlt - altitude.

    latitude := latitude + (dLat sign * (step min: dLat abs)).
    longitude := longitude + (dLon sign * (step min: dLon abs)).
    altitude := altitude + (dAlt sign * (5 min: dAlt abs)). "5 m par pas"
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

{ #category : 'accessing' }
Drone >> position [

^self geoPoint 
]

{ #category : 'accessing' }
Drone >> position:a [ 
"facility - should refactor" 
^self geoPoint: a 

]

{ #category : 'action' }
Drone >> refuel [

	fuel := 100
]

{ #category : 'action' }
Drone >> sendHelpRequestToConsensus: consensus [
    consensus receiveMessage: self helpRequestMessage.
]

{ #category : 'accessing' }
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

{ #category : 'status' }
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

{ #category : 'status' }
Drone >> statusString [
    "Retourne une chaîne lisible pour monitoring"
    ^ String streamContents: [:s |
        s nextPutAll: 'Drone '; nextPutAll: uniqueId;
        nextPutAll: ' fuel='; nextPutAll: fuel asString;
        nextPutAll: '% pos=('; 
        nextPutAll: latitude asString; nextPutAll: ','; nextPutAll: longitude asString;
        nextPutAll: ') alt='; nextPutAll: altitude asString
    ].
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
