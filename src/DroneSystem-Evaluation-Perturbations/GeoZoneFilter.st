Class {
	#name : 'GeoZoneFilter',
	#superclass : 'Object',
	#instVars : [
		'zoneName',
		'polygon',
		'targetDroneIds'
	],
	#category : 'DroneSystem-Evaluation-Perturbations',
	#package : 'DroneSystem-Evaluation-Perturbations'
}

{ #category : 'initialization' }
GeoZoneFilter >> initialize [
	super initialize.
	zoneName := 'UnnamedZone'.
	polygon := nil.
	targetDroneIds := Set new
]

{ #category : 'accessing' }
GeoZoneFilter >> zoneName: aString [
	zoneName := aString.
	^ self
]

{ #category : 'accessing' }
GeoZoneFilter >> polygon: aPolygon [
	polygon := aPolygon.
	^ self
]

{ #category : 'accessing' }
GeoZoneFilter >> addTargetDroneId: anId [
	targetDroneIds add: anId.
	^ self
]

{ #category : 'testing' }
GeoZoneFilter >> matchesDronePosition: aDronePosition [
	"Retourne true si la position du drone intersecte avec la zone"
	polygon notNil ifTrue: [
		^ polygon containsPoint: aDronePosition
	].
	^ false
]

{ #category : 'printing' }
GeoZoneFilter >> printOn: aStream [
	aStream nextPutAll: 'GeoZoneFilter('; nextPutAll: zoneName; nextPut: $)
]
