Class {
	#name : 'PerceptionDronePose',
	#superclass : 'Object',
	#instVars : [
		'identifier',
		'position',
		'altitude',
		'heightAboveGround'
	],
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'instance creation' }
PerceptionDronePose class >> id: id position: point elevation: meters [

	^ self new
		  initializeId: id
		  position: point
		  altitude: meters
		  aboveGround: false
]

{ #category : 'instance creation' }
PerceptionDronePose class >> id: id position: point heightAboveGround: meters [

	meters > 0 ifFalse: [
		self error: 'La hauteur au-dessus du sol doit être positive.' ].
	^ self new
		  initializeId: id
		  position: point
		  altitude: meters
		  aboveGround: true
]

{ #category : 'accessing' }
PerceptionDronePose >> altitude [

	^ altitude
]

{ #category : 'accessing' }
PerceptionDronePose >> id [

	^ identifier
]

{ #category : 'accessing' }
PerceptionDronePose >> initializeId: id position: point altitude: meters aboveGround: useAgl [

	(id notNil and: [
		 point isPoint and: [
			 meters isNumber and: [ meters asFloat isFinite ] ] ]) ifFalse: [
		self error: 'Identifiant, position ou altitude de drone invalide.' ].
	identifier := id.
	position := point x @ point y.
	altitude := meters asFloat.
	heightAboveGround := useAgl
]

{ #category : 'accessing' }
PerceptionDronePose >> position [

	^ position
]

{ #category : 'accessing' }
PerceptionDronePose >> usesHeightAboveGround [

	^ heightAboveGround
]

{ #category : 'accessing' }
PerceptionDronePose >> withPosition: projectedPoint [

	^ self class new
		  initializeId: identifier
		  position: projectedPoint
		  altitude: altitude
		  aboveGround: heightAboveGround
]
