Class {
	#name : 'QuickMap',
	#superclass : 'Object',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
QuickMap class >> example [

	| mapForm |
	mapForm := QuickMap
		           formForMinLat: 48.80
		           minLon: 2.20
		           maxLat: 48.92
		           maxLon: 2.42
		           zoom: 12.

	mapForm inspect
]

{ #category : 'examples' }
QuickMap class >> example2 [

	| img myBbox3857 |
	img := QuickMap
		       fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2' }
		       bbox: myBbox3857
		       size: 1024 @ 1024
		       epsg: '3857'
		       format: 'image/jpeg'
]

{ #category : 'examples' }
QuickMap class >> exampleParis [

	| mapForm |
	mapForm := QuickMap
		           formForMinLat: 48.80
		           minLon: 2.20
		           maxLat: 48.92
		           maxLon: 2.42
		           zoom: 13.

	mapForm inspect
]

{ #category : 'examples' }
QuickMap class >> exampleParisPlanIGN [
	"Return a Form with Plan IGN + roads over Paris area."

	| minLat minLon maxLat maxLon toMercator minXY maxXY bbox size |
	minLat := 48.80.
	minLon := 2.20.
	maxLat := 48.92.
	maxLon := 2.42.

	toMercator := [ :lat :lon |
		              | r latRad |
		              r := 6378137.0.
		              latRad := ((lat max: -85.05112878) min: 85.05112878)
			                        degreesToRadians.
		              r * lon degreesToRadians
		              @ (r * (Float pi / 4 + latRad / 2) tan ln) ].

	minXY := toMercator value: minLat value: minLon.
	maxXY := toMercator value: maxLat value: maxLon.
	bbox := {
		        minXY x.
		        minXY y.
		        maxXY x.
		        maxXY y }.

	size := 1024 @ 1024.

	^ self
		  fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'.
			  'TRANSPORTNETWORKS.ROADS' }
		  bbox: bbox
		  size: size
		  epsg: '3857'
		  format: 'image/png' "keeps roads transparent"
]

{ #category : 'fetching' }
QuickMap class >> fetchTileX: x y: y z: z [

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
QuickMap class >> fetchWmsLayers: layerNames bbox: bbox size: size epsg: epsg format: format [

	^ self
		  fetchWmsLayers: layerNames
		  bbox: bbox
		  size: size
		  epsg: epsg
		  format: format
		  wmsEndpoint: self geoportailEndpoint
]

{ #category : 'canvas drawing - general' }
QuickMap class >> fetchWmsLayers: layerNames bbox: bbox size: size epsg: epsg format: format wmsEndpoint: wmsEndpoint [
    | client url |
    url := String streamContents: [ :s |
        s
            nextPutAll: '<WMS_ENDPOINT>?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap';
            nextPutAll: '&LAYERS=', (layerNames joinSeparatedBy: ',');
            nextPutAll: '&CRS=EPSG:', epsg;
            nextPutAll: '&BBOX=', (bbox collect: #asString) joinSeparatedBy: ',';
            nextPutAll: '&WIDTH=', size x asString;
            nextPutAll: '&HEIGHT=', size y asString;
            nextPutAll: '&FORMAT=', format;
            nextPutAll: '&STYLES=';
            nextPutAll: '&TRANSPARENT=', (format = 'image/png' ifTrue: [ 'TRUE' ] ifFalse: [ 'FALSE' ]) ].

    client := ZnClient new
        url: url;
        headerAt: 'User-Agent' put: 'Pharo QuickMap';
        get.
    ^ PNGReadWriter formFromStream: client contents readStream
]

{ #category : 'canvas drawing - general' }
QuickMap class >> formForMinLat: minLat minLon: minLon maxLat: maxLat maxLon: maxLon zoom: zoom [

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
QuickMap class >> geoportailEndpoint [
    ^ 'https://wxs.ign.fr/essentiels/geoportail/r/wms'
]

{ #category : 'converting' }
QuickMap class >> lon: lon lat: lat toTileAtZoom: zoom [
    | n x y latRad |
    n := 2 raisedTo: zoom.
    x := ((lon + 180.0) / 360.0 * n) floor.
    latRad := lat degreesToRadians.
    y := ((1.0 - ((latRad tan + (1.0 / latRad cos)) ln / Float pi)) / 2.0 * n) floor.
    ^ x @ y
]

{ #category : 'url' }
QuickMap class >> tileUrlX: x y: y z: z [

	^ 'https://tile.openstreetmap.org/' , z asString , '/' , x asString
	  , '/' , y asString , '.png'
]
