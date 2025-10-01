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
GeoPoint >> - aPoint [

^self class with: (Array with:  self latitude - aPoint latitude with:  self longitude - aPoint longitude with: self altitude - aPoint altitude )
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
GeoPoint >> distanceTo: aGeoPoint [  "Calcule la distance approximative en km entre la position actuelle et une nouvelle coordonnée."
    | dLat dLon meanLat earthRadius horizDist altDiff |
    earthRadius := 6371.0. "km, rayon moyen Terre"
    dLat := (aGeoPoint latitude - self latitude) degreesToRadians.
    dLon := (aGeoPoint longitude - self longitude) degreesToRadians.
    meanLat := ((aGeoPoint latitude + self latitude) / 2) degreesToRadians.
    horizDist := earthRadius * ((dLat squared + ((dLon * meanLat cos) squared)) sqrt).
    altDiff := (aGeoPoint altitude  - self altitude) / 1000.0. "convertir mètres → km"
    ^ (horizDist squared + altDiff squared) sqrt.
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

{ #category : 'arithmetic' }
GeoPoint >> normalize [

| r |
r := self radius.
latitude := latitude / r.
longitude := longitude /r.
altitude := altitude /r

]

{ #category : 'printing' }
GeoPoint >> printOn: aStream [
aStream nextPut:$(;nextPutAll: self longitude printString;nextPut:$,;nextPutAll: self latitude printString; nextPut:$,; nextPutAll: self altitude printString;nextPut:$)
]

{ #category : 'accessing' }
GeoPoint >> radius [ 
^(latitude squared + longitude squared + altitude squared) sqrt

]
