Class {
	#name : 'GeoPoint',
	#superclass : 'Object',
	#instVars : [
		'latitude',
		'longitude',
		'altitude'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'instance creation' }
GeoPoint class >> latitude: lat longitude: lon altitude: alt [
  
	| tmp |
	tmp := self new.
	tmp latitude: lat.
	tmp longitude: lon.
	tmp altitude: alt.
	^ tmp
]

{ #category : 'instance creation' }
GeoPoint class >> with: anArray [

	^self latitude: anArray first longitude: (anArray at:2) altitude: anArray last
]

{ #category : 'arithmetic' }
GeoPoint >> * aNumber [

^self class with: (Array with:  self latitude * aNumber  with:  self longitude * aNumber with: self altitude * aNumber)
]

{ #category : 'arithmetic' }
GeoPoint >> + aPoint [

^self class with: (Array with:  self latitude + aPoint latitude with:  self longitude + aPoint longitude with: self altitude + aPoint altitude )
]

{ #category : 'arithmetic' }
GeoPoint >> - aPoint [

^self class with: (Array with:  self latitude - aPoint latitude with:  self longitude - aPoint longitude with: self altitude - aPoint altitude )
]

{ #category : 'arithmetic' }
GeoPoint >> / aNumber [

	^ self * (1 / aNumber)
]

{ #category : 'visiting' }
GeoPoint >> accept: aVisitor [

^aVisitor visitGeoPoint: self 
]

{ #category : 'accessing' }
GeoPoint >> altitude [

	^ altitude
]

{ #category : 'accessing' }
GeoPoint >> altitude: anObject [

	altitude := anObject
]

{ #category : 'distance functions' }
GeoPoint >> bearingTo: aGeoPoint [
    "Calcule le cap (bearing/azimut) en degrés de la position actuelle vers aGeoPoint.
    Retourne un angle entre 0° (Nord) et 360° dans le sens horaire.
    Est = 90°, Sud = 180°, Ouest = 270°"
    
    | dLon lat1 lat2 y x bearing |
    lat1 := self latitude degreesToRadians.
    lat2 := aGeoPoint latitude degreesToRadians.
    dLon := (aGeoPoint longitude - self longitude) degreesToRadians.
    
    "Formule bearing: atan2(sin(ΔLon)·cos(lat2), cos(lat1)·sin(lat2) - sin(lat1)·cos(lat2)·cos(ΔLon))"
    y := dLon sin * lat2 cos.
    x := (lat1 cos * lat2 sin) - (lat1 sin * lat2 cos * dLon cos).
    bearing := y arcTan: x. "résultat en radians"
    
    "Convertir en degrés et normaliser [0, 360)"
    bearing := bearing radiansToDegrees.
    ^ (bearing + 360) \\ 360
]

{ #category : 'distance functions' }
GeoPoint >> destinationPoint: distanceKm bearing: bearingDegrees [
    "Calcule le point de destination à partir de la position actuelle,
    d'une distance (en km) et d'un cap (en degrés, 0°=Nord).
    Utilise la formule haversine pour projeter sur une sphère.
    
    Example:
      brest := GeoPoint latitude: 48.39 longitude: -4.49 altitude: 0.
      destination := brest destinationPoint: 100 bearing: 90.  'East 100km'
    "
    
    | earthRadius angularDistance bearingRad lat1 lon1 lat2 lon2 |
    earthRadius := 6371.0. "km"
    
    "Convertir en radians"
    angularDistance := distanceKm / earthRadius.
    bearingRad := bearingDegrees degreesToRadians.
    lat1 := self latitude degreesToRadians.
    lon1 := self longitude degreesToRadians.
    
    "Formules de projection sphérique:
     lat2 = asin(sin(lat1)·cos(d) + cos(lat1)·sin(d)·cos(θ))
     lon2 = lon1 + atan2(sin(θ)·sin(d)·cos(lat1), cos(d) - sin(lat1)·sin(lat2))"
    
    lat2 := ((lat1 sin * angularDistance cos) 
             + (lat1 cos * angularDistance sin * bearingRad cos)) arcSin.
    
    lon2 := lon1 + (
        (bearingRad sin * angularDistance sin * lat1 cos)
        arcTan: (angularDistance cos - (lat1 sin * lat2 sin))
    ).
    
    "Retourner nouveau GeoPoint (même altitude)"
    ^ self class  
        latitude: lat2 radiansToDegrees 
        longitude: lon2 radiansToDegrees 
        altitude: self altitude
]

{ #category : 'distance functions' }
GeoPoint >> distanceTo: aGeoPoint [
	"Calcule la distance approximative en km entre la position actuelle et une nouvelle coordonnée."

	| dLat dLon meanLat earthRadius horizDist altDiff |
	earthRadius := 6371.0. "km, rayon moyen Terre"
	dLat := (aGeoPoint latitude - self latitude) degreesToRadians.
	dLon := (aGeoPoint longitude - self longitude) degreesToRadians.
	meanLat := (aGeoPoint latitude + self latitude / 2) degreesToRadians.
	horizDist := earthRadius
	             * (dLat squared + (dLon * meanLat cos) squared) sqrt.
	altDiff := aGeoPoint altitude - self altitude / 1000.0. "convertir mètres → km"
	^ (horizDist squared + altDiff squared) sqrt
]

{ #category : 'accessing' }
GeoPoint >> latitude [

	^ latitude
]

{ #category : 'accessing' }
GeoPoint >> latitude: anObject [

	latitude := anObject
]

{ #category : 'accessing' }
GeoPoint >> longitude [

	^ longitude
]

{ #category : 'accessing' }
GeoPoint >> longitude: anObject [

	longitude := anObject
]

{ #category : 'distance functions' }
GeoPoint >> newPointByMovingBy: aDelta [
    "Calcule un nouveau point géoréférencé en se déplaçant de deltaX km vers l'Est
    et deltaY km vers le Nord à partir du point actuel."

    | earthRadius newLat newLon deltaLat deltaLon |

    earthRadius := 6371.0. "km, rayon moyen de la Terre"

    "Conversion déplacement en latitude (deltaY) et longitude (deltaX)"
    deltaLat := (aDelta y / earthRadius) * 180 / Float pi.
    "Correction de la longitude selon la latitude courante"
    deltaLon := (aDelta x / (earthRadius * (self latitude degreesToRadians cos))) * 180 / Float pi.

    newLat := self latitude + deltaLat.
    newLon := self longitude + deltaLon.

    ^ self class latitude: newLat longitude: newLon altitude: self altitude

]

{ #category : 'arithmetic' }
GeoPoint >> normalize [

| r |
r := self radius.
r = 0 ifFalse:[
latitude := latitude / r.
longitude := longitude /r.
altitude := altitude /r]

]

{ #category : 'printing' }
GeoPoint >> printOn: aStream [
aStream nextPut:$(;nextPutAll: self longitude printString;nextPut:$,;nextPutAll: self latitude printString; nextPut:$,; nextPutAll: self altitude printString;nextPut:$)
]

{ #category : 'accessing' }
GeoPoint >> radius [ 
^(latitude squared + longitude squared + altitude squared) sqrt

]
