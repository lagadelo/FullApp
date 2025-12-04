Class {
	#name : 'Drone',
	#superclass : 'AbstractDrone',
	#instVars : [
		'behavior',
		'type',
		'cluster'
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

{ #category : 'examples' }
Drone class >> exampleAngers [
^self new initializeWithId: #Angers
            latitude: 47.45
            longitude: 0.5 
        altitude:  20
]

{ #category : 'visiting' }
Drone >> accept: aVisitor [

^aVisitor visitDrone: self 
]

{ #category : 'facilities' }
Drone >> altitude [

	^ self geoPoint altitude
]

{ #category : 'facilities' }
Drone >> altitude: anObject [

	self geoPoint altitude: anObject
]

{ #category : 'damages' }
Drone >> applyDamage: damage to: aCapacity [

	self capacities consume: damage of: aCapacity
]

{ #category : 'damages' }
Drone >> applyPercentageDamage: damage to: aCapacity [

	self capacities consumePercent: damage of: aCapacity
]

{ #category : 'converting' }
Drone >> asCluster [
self shouldBeImplemented 
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

{ #category : 'accessing' }
Drone >> behavior [

	^ behavior
]

{ #category : 'accessing' }
Drone >> behavior: anObject [

	behavior := anObject
]

{ #category : 'facilities' }
Drone >> canCommunicateWith: anObject [
 
	^ (self position distanceTo: anObject position)
	  <= self capabilities communicationRange
]

{ #category : 'facilities' }
Drone >> canPerceive: anObject [

	^ (self position distanceTo: anObject position)
	  <= self capabilities perceptionRange
]

{ #category : 'accessing' }
Drone >> cluster [

	^ cluster
]

{ #category : 'accessing' }
Drone >> cluster: anObject [

	cluster := anObject
]

{ #category : 'action' }
Drone >> communicateWithConsensus: consensus [
    consensus receiveStatusMessage: self statusMessage.

]

{ #category : 'copying' }
Drone >> deepCopy [
    | d |
    d := self class new initialize.
    
    "If direct slot assignment available, use it; otherwise use moveToLatitude:..."
    "d moveToLatitude: latitude longitude: longitude altitude: altitude."
d geoPoint: d geoPoint copy.
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

{ #category : 'testing' }
Drone >> destroy [ 
self capabilities destroy
]

{ #category : 'computing' }
Drone >> distanceToLatitude: lat longitude: lon altitude: alt [
    "Calcule la distance approximative en km entre la position actuelle et une nouvelle coordonnée."
    | dLat dLon meanLat earthRadius horizDist altDiff |
    earthRadius := 6371.0. "km, rayon moyen Terre"
    dLat := (lat - self latitude) degreesToRadians.
    dLon := (lon - self longitude) degreesToRadians.
    meanLat := ((lat + self latitude) / 2) degreesToRadians.
    horizDist := earthRadius * ((dLat squared + ((dLon * meanLat cos) squared)) sqrt).
    altDiff := (alt - self altitude) / 1000.0. "convertir mètres → km"
    ^ (horizDist squared + altDiff squared) sqrt.
]

{ #category : 'messages processing' }
Drone >> emitHelpRequest [

	^ Message broadcastHelpRequest: self
]

{ #category : 'messages processing' }
Drone >> emitQueryRequest: aPayload to: receivers [

 
	^ Message
		  intent: #Query
		  from: self
		  to: receivers
		  payload: aPayload
]

{ #category : 'accessing' }
Drone >> geoPoint [ 

 ^geoPoint 
]

{ #category : 'accessing' }
Drone >> geoPoint: a [

geoPoint := a
]

{ #category : 'coloring' }
Drone >> getColor [

self isDestroyed ifTrue:[^Color black].
self isHostile ifTrue:[^Color red].
self isHostile ifTrue:[^Color green].
^Color blue 
]

{ #category : 'accessing' }
Drone >> health [

	^ self capabilities computeHealth
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

	| r |
	super initialize.
	geoPoint := self class LandingBase.
	capabilities := Capabilities new.
	r := Random new.

	capabilities define: #energy maxValue: 100.
	capabilities define: #ammunitions maxValue: 1000.

	capabilities define: #perceptionRange maxValue: 50.
	capabilities define: #communicationRange maxValue: 50.

	capabilities consumePercent: r next * 100 of: #energy.
	capabilities consumePercent: r next * 100 of: #ammunitions.
	capabilities consumePercent: r next * 50 of: #communicationRange.
	 
	behavior := nil.
	id := UUID new asString.
	type := 'standard'.

	hostile := false
]

{ #category : 'initialization' }
Drone >> initializeWithId: anID
            latitude: aLatitude
            longitude: aLongiture
            altitude: anAltitude [ 

  
self latitude: aLatitude .
self longitude: aLongiture .
self altitude: anAltitude .
id :=  anID.
]

{ #category : 'testing' }
Drone >> isDestroyed [

	^ self capabilities isDestroyed
]

{ #category : 'facilities' }
Drone >> latitude [

	^ self position latitude
]

{ #category : 'facilities' }
Drone >> latitude: anObject [

	self position latitude: anObject
]

{ #category : 'facilities' }
Drone >> longitude [

	^ self position longitude
]

{ #category : 'facilities' }
Drone >> longitude: anObject [

	self position longitude: anObject
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

{ #category : 'facilities' }
Drone >> perceivedElemnts [

	^ DroneFleet allElements select: [ :a | self canPerceive: a ]
]

{ #category : 'accessing' }
Drone >> position [
	 

	^ self status get:#geoPoint
]

{ #category : 'accessing' }
Drone >> position: aValue [
	 

	^ self status set:#geoPoint to: aValue
]

{ #category : 'facilities' }
Drone >> reachableElemnts [

	^ DroneFleet allElements select: [ :a | self canCommunicateWith: a ]
]

{ #category : 'messages processing' }
Drone >> receiveQueryRequest: aMessage [

	aMessage emiter isHostile ifTrue: [ "ignore message" ^ self ].

	^ Message
		  intent: #Information
		  from: self
		  to: aMessage emiter
		  payload: (aMessage value: aMessage emiter value: self)
]

{ #category : 'consumption' }
Drone >> sendHelpRequest [

 ^Message emiter: self 
]

{ #category : 'action' }
Drone >> sendHelpRequestToConsensus: consensus [
    consensus receiveMessage: self helpRequestMessage.
]

{ #category : 'accessing' }
Drone >> setBehavior: aBehavior [
    behavior := aBehavior.
]

{ #category : 'status' }
Drone >> statusMessage [
    ^ Dictionary new
        at: #id put: uniqueId;
        at: #position put: self position;
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
        nextPutAll: self position printString;nextPut:$).
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
