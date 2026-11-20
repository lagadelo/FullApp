Class {
	#name : 'PerceptionCoordinateTransform',
	#superclass : 'Object',
	#category : 'Drone-SystemCouplagePerceptionRoassal',
	#package : 'Drone-SystemCouplagePerceptionRoassal'
}

{ #category : 'projection' }
PerceptionCoordinateTransform class >> forMetadata: metadata [

	| input output origin direction converter |
	output := metadata at: 'crs'.
	input := metadata at: 'inputCrs' ifAbsent: [ output ].
	origin := (metadata at: 'inputOrigin' ifAbsent: [ nil ])
		          ifNil: [ 0 @ 0 ]
		          ifNotNil: [ :coords | coords first @ coords second ].
	direction := (metadata at: 'inputYDown' ifAbsent: [ false ])
		             ifTrue: [ -1 ]
		             ifFalse: [ 1 ].
	converter := self from: input to: output.
	^ [ :point |
	  converter value: origin + (point x @ (point y * direction)) ]
]

{ #category : 'projection' }
PerceptionCoordinateTransform class >> from: input to: output [

	| code |
	input = output ifTrue: [ ^ [ :point | point ] ].
	(#( 'EPSG:4326' 'OGC:CRS84' ) includes: input) ifFalse: [
			self error:
				'Pour ce changement de CRS, fournir le bloc de projection à PerceptionAdapter on:projection:.' ].
	output = 'EPSG:2154' ifTrue: [ ^ [ :point | self lambert93: point ] ].
	code := (output copyAfter: $:) asInteger.
	(code between: 32601 and: 32660) ifTrue: [
		^ [ :point | self utm: point zone: code - 32600 falseNorthing: 0.0 ] ].
	(code between: 32701 and: 32760) ifTrue: [
			^ [ :point |
			  self utm: point zone: code - 32700 falseNorthing: 10000000.0 ] ].
	self error:
		'Pour ce CRS de grille, fournir le bloc de projection à PerceptionAdapter on:projection:.'
]

{ #category : 'projection' }
PerceptionCoordinateTransform class >> lambert93: lonLat [
	"Lambert conformal conic 2SP, IGN constants for the RGF93 / Lambert-93 conversion."

	| latitude longitude e eSin isometric radius convergence |
	latitude := lonLat y * Float pi / 180.
	longitude := lonLat x - 3 * Float pi / 180.
	e := 0.0818191910428158.
	eSin := e * latitude sin.
	isometric := (Float pi / 4 + (latitude / 2)) tan ln
	             - (e / 2 * (1 + eSin / (1 - eSin)) ln).
	radius := 11754255.426096
	          * (0.7256077650532671 * isometric) negated exp.
	convergence := 0.7256077650532671 * longitude.
	^ 700000 + (radius * convergence sin)
	  @ (12655612.049876 - (radius * convergence cos))
]

{ #category : 'projection' }
PerceptionCoordinateTransform class >> utm: lonLat zone: zone falseNorthing: offset [
	"WGS 84 Transverse Mercator series, used within the UTM zone of the scene."

	| latitude longitude sine cosine tangent e2 e4 e6 secondEccentricity normal t c a a2 meridian easting northing |
	latitude := lonLat y * Float pi / 180.
	longitude := lonLat x - (6 * zone - 183) * Float pi / 180.
	sine := latitude sin.
	cosine := latitude cos.
	tangent := latitude tan.
	e2 := 0.0066943799901413165.
	e4 := e2 squared.
	e6 := e4 * e2.
	secondEccentricity := e2 / (1 - e2).
	normal := 6378137.0 / (1 - (e2 * sine squared)) sqrt.
	t := tangent squared.
	c := secondEccentricity * cosine squared.
	a := longitude * cosine.
	a2 := a squared.
	meridian := 6378137.0
	            *
		            (1 - (e2 / 4) - (3 * e4 / 64) - (5 * e6 / 256)
		             * latitude
		             -
		             (3 * e2 / 8 + (3 * e4 / 32) + (45 * e6 / 1024)
		              * (2 * latitude) sin)
		             +
		             (15 * e4 / 256 + (45 * e6 / 1024) * (4 * latitude) sin)
		             - (35 * e6 / 3072 * (6 * latitude) sin)).
	easting := 500000 + (0.9996 * normal * (a + (1 - t + c * a * a2 / 6)
	             +
		             (5 - (18 * t) + t squared + (72 * c)
		              - (58 * secondEccentricity) * a * a2 squared / 120))).
	northing := offset + (0.9996 * (meridian + (normal * tangent
	               *
		               (a2 / 2
		                +
		                (5 - t + (9 * c) + (4 * c squared) * a2 squared / 24)
		                +
			                (61 - (58 * t) + t squared + (600 * c)
			                 - (330 * secondEccentricity) * a2 squared * a2
			                 / 720))))).
	^ easting @ northing
]
