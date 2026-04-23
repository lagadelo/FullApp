Class {
	#name : 'QuickOpenStreetMap',
	#superclass : 'QuickMap',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

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
