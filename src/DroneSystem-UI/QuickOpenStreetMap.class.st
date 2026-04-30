Class {
	#name : 'QuickOpenStreetMap',
	#superclass : 'QuickMap',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'fetching' }
QuickOpenStreetMap class >> fetchTileX: x y: y z: z [

	| client bytes |
	client := ZnClient new.
	client
		url: (self tileUrlX: x y: y z: z);
		headerAt: 'User-Agent' put: 'Pharo QuickMap';
		get.
	bytes := client contents.
	^ PNGReadWriter formFromStream: bytes readStream
]

{ #category : 'canvas drawing - general' }
QuickOpenStreetMap class >> formForMinLat: minLat minLon: minLon maxLat: maxLat maxLon: maxLon zoom: zoom [

	| topLeft bottomRight minX maxX minY maxY tileWidth tileHeight canvas |
	topLeft := self lon: minLon lat: maxLat toTileAtZoom: zoom.
	bottomRight := self lon: maxLon lat: minLat toTileAtZoom: zoom.

	minX := topLeft x.
	maxX := bottomRight x.
	minY := topLeft y.
	maxY := bottomRight y.

	tileWidth := 256.
	tileHeight := 256.

	canvas := Form
		          extent:
		          maxX - minX + 1 * tileWidth
		          @ (maxY - minY + 1 * tileHeight)
		          depth: 32.

	minX to: maxX do: [ :x |
			minY to: maxY do: [ :y |
					| tile dx dy |
					tile := self fetchTileX: x y: y z: zoom.
					dx := x - minX * tileWidth.
					dy := y - minY * tileHeight.
					tile displayOn: canvas at: dx @ dy ] ].

	^ canvas
]

{ #category : 'url' }
QuickOpenStreetMap class >> tileUrlX: x y: y z: z [

	^ 'https://tile.openstreetmap.org/' , z asString , '/' , x asString
	  , '/' , y asString , '.png'
]

{ #category : 'getter' }
QuickOpenStreetMap >> adjustZoom [

	| zoom topLeft bottomRight minX maxX minY maxY tileWidth tileHeight |
	zoom := 1.
	[
		topLeft := self lon: minLon lat: maxLat toTileAtZoom: zoom.
		bottomRight := self lon: maxLon lat: minLat toTileAtZoom: zoom.

		minX := topLeft x.
		maxX := bottomRight x.
		minY := topLeft y.
		maxY := bottomRight y.

		tileWidth := 256.
		tileHeight := 256.
		maxX - minX + 1 * tileWidth < 4000
		& (maxY - minY + 1 * tileWidth < 4000) ] whileTrue: [
		zoom := zoom + 1 ].
	self imageSize: maxX - minX + 1 * tileWidth@ (maxY - minY + 1 * tileWidth).
	Transcript
		show: zoom printString;
		cr.
	^ zoom
]

{ #category : 'getter' }
QuickOpenStreetMap >> buildBackground [

	| topLeft bottomRight minX maxX minY maxY tileWidth tileHeight zoom |
	zoom := self adjustZoom.
	topLeft := self lon: minLon lat: maxLat toTileAtZoom: zoom.
	bottomRight := self lon: maxLon lat: minLat toTileAtZoom: zoom.

	minX := topLeft x.
	maxX := bottomRight x.
	minY := topLeft y.
	maxY := bottomRight y.
	tileWidth := 256.
	tileHeight := 256.

	self origin: (self tileX: minX y: minY toTopLeftLonLatAtZoom: zoom).
	self corner:
		(self tileX: maxX + 1 y: maxY + 1 toTopLeftLonLatAtZoom: zoom).
self assert: self corner x > self maxLon.
 
self assert: self corner y < self minLat.
 
self assert: self origin x < self minLon.
 
self assert: self origin y > self maxLat.
 


	self minLon: origin x.
	self maxLon: corner x.
	self minLat: corner y.
	self maxLat: origin y.
	
	self halt. 
	self getExtend.
	background := Form
		              extent:
		              (maxX - minX + 1) * tileWidth
		              @ ((maxY - minY + 1) * tileHeight)
		              depth: 32.

	minX to: maxX do: [ :x |
			minY to: maxY do: [ :y |
					| tile dx dy |
					tile := self fetchTileX: x y: y z: zoom.
					dx := (x - minX) * tileWidth.
					dy := (y - minY) * tileHeight.
					tile displayOn: background at: dx @ dy ] ].





	^ background
]

{ #category : 'building' }
QuickOpenStreetMap >> buildFromOld: tmp [

tmp poi keysAndValuesDo: [ :k :v |  self  addModel: k withID: v ].
	tmp poi do: [ :m |
			 self 
				addShape: ((RSCircle size: 40)
						 position: ( self  cartesianCoordinates: m);
						 color: Color blue;
						 yourself)
				withModel: m ].
	tmp hull points do: [ :m |
			 self 
				addShape: ((RSCircle size: 30)
						 position: ( self  cartesianCoordinates: m);
						 color: Color red;
						 yourself)
				withModel: m ].
	tmp hull points keysAndValuesDo: [ :i :k |
			 self 
				addShape: ((RSLine
						  newFrom: ( self  getShapeFromModel: k)
						  to:
							  ( self  getShapeFromModel:
									   (tmp hull at: i \\ tmp hull size + 1)))
						 color: Color red;
						 yourself)
				withModel: 100 + i ]
]

{ #category : 'tiles' }
QuickOpenStreetMap >> fetchTileX: x y: y z: z [

	^ self readURL: (self tileUrlX: x y: y z: z)
]

{ #category : 'getter' }
QuickOpenStreetMap >> formForMinLat: minLat minLon: minLon maxLat: maxLat maxLon: maxLon zoom: zoom [

	| topLeft bottomRight minX maxX minY maxY tileWidth tileHeight |
	topLeft := self lon: minLon lat: maxLat toTileAtZoom: zoom.
	bottomRight := self lon: maxLon lat: minLat toTileAtZoom: zoom.

	minX := topLeft x.
	maxX := bottomRight x.
	minY := topLeft y.
	maxY := bottomRight y.

	tileWidth := 256.
	tileHeight := 256.

	background := Form
		              extent:
		              (maxX - minX + 1) * tileWidth
		              @ ((maxY - minY + 1) * tileHeight)
		              depth: 32.

	minX to: maxX do: [ :x |
			minY to: maxY do: [ :y |
					| tile dx dy |
					tile := self fetchTileX: x y: y z: zoom.
					dx := (x - minX) * tileWidth.
					dy := (y - minY) * tileHeight.
					tile displayOn: background at: dx @ dy ] ].

	^ background
]

{ #category : 'accessing' }
QuickOpenStreetMap >> lon: lon lat: lat toTileAtZoom: zoom [
    | n x y latRad |
    n := 2 raisedTo: zoom.
    x := ((lon + 180.0) / 360.0 * n) floor.
    latRad := lat degreesToRadians.
    y := ((1.0 - ((latRad tan + (1.0 / latRad cos)) ln / Float pi)) / 2.0 * n) floor.
    ^ x @ y
]

{ #category : 'tiles' }
QuickOpenStreetMap >> tileUrlX: x y: y z: z [

	^ 'https://tile.openstreetmap.org/' , z asString , '/' , x asString
	  , '/' , y asString , '.png'
]

{ #category : 'accessing' }
QuickOpenStreetMap >> tileX: x y: y toTopLeftLonLatAtZoom: zoom [
    | n lon arg lat |
    n := 2 raisedTo: zoom.
    lon := (x / n * 360.0) - 180.0.
    "sinh(x) = (exp(x) - exp(-x)) / 2"
    arg := Float pi * (1.0 - (2.0 * y / n)).
    lat := ((arg exp - arg negated exp) / 2.0) arcTan radiansToDegrees.
    ^ lon @ lat
]
