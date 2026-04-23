Class {
	#name : 'QuickMap',
	#superclass : 'Object',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'facilities' }
QuickMap class >> commaSeparated: aCollection [
    ^ String streamContents: [ :s |
        aCollection doWithIndex: [ :each :i |
            i > 1 ifTrue: [ s nextPut: $, ].
            s nextPutAll: each asString ] ].
]

{ #category : 'canvas drawing - general' }
QuickMap class >> compositeBase: baseForm withOverlay: overlayForm [
    "Draw overlay (with alpha) on top of base and return the composite."
    | composite |
    composite := baseForm deepCopy.
    composite
        copy: overlayForm boundingBox
        from: overlayForm
        to: 0@0
        rule: Form blend.   "alpha-aware"
    ^ composite
]

{ #category : 'facilities' }
QuickMap class >> emptyStylesFor: layerNames [
    "Return a STYLES string with one empty style per layer, e.g. ',' for 2 layers."
    ^ String streamContents: [ :s |
        layerNames doWithIndex: [ :each :i | i > 1 ifTrue: [ s nextPut: $, ] ] ].
]

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
QuickMap class >> exampleOuessantLeFaouComposite [
    "Ouessant → Le Faou area with coastal/maritime overlays."
    | minLat minLon maxLat maxLon toMercator minXY maxXY bbox size epsg wmsEndpoint base overlay composite |

    "Approx extent: 10 miles (~16 km) west of Ouessant to Le Faou."
    minLat := 48.25.
    maxLat := 48.50.
    minLon := -5.35.
    maxLon := -4.10.

    toMercator := [ :lat :lon |
        | r latRad |
        r := 6378137.0.
        latRad := ((lat max: -85.05112878) min: 85.05112878) degreesToRadians.
        (r * lon degreesToRadians)
            @ (r * ((Float pi / 4 + latRad / 2) tan ln))
    ].

    minXY := toMercator value: minLat value: minLon.
    maxXY := toMercator value: maxLat value: maxLon.
    bbox := { minXY x. minXY y. maxXY x. maxXY y }.

    size := 256@256.
    epsg := '3857'.
    wmsEndpoint := 'https://data.geopf.fr/wms-r?apikey=essentiels'.

    "Base: plan; overlay: coastal + hydro + roads (all PNG transparent)."
    base := self
        fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2' }
        bbox: bbox
        size: size
        epsg: epsg
        format: 'image/png'
        "wmsEndpoint: wmsEndpoint".

    overlay := self
        fetchWmsLayers: {
            'GEOGRAPHICALGRIDSYSTEMS.COASTALMAPS'".
            'IGNF_HYDROGRAPHY.HYDROGRAPHY'.
            'TRANSPORTNETWORKS.ROADS'"
        }
        bbox: bbox
        size: size
        epsg: epsg
        format: 'image/png'
       " wmsEndpoint: wmsEndpoint".

    composite := self compositeBase: base withOverlay: overlay.
    ^ composite
]

{ #category : 'examples' }
QuickMap class >> exampleOuessantLeFaouCompositeSmall [
    | minLat minLon maxLat maxLon toMercator minXY maxXY bbox size epsg wmsEndpoint base overlay |
    "Shrunk extent (~50%): centered between Ouessant and Le Faou."
    minLat := 48.3125.
    maxLat := 48.4375.
    minLon := -5.0375.
    maxLon := -4.4125.

    toMercator := [ :lat :lon |
        | r latRad |
        r := 6378137.0.
        latRad := ((lat max: -85.05112878) min: 85.05112878) degreesToRadians.
        (r * lon degreesToRadians) @ (r * ((Float pi / 4 + latRad / 2) tan ln))
    ].

    minXY := toMercator value: minLat value: minLon.
    maxXY := toMercator value: maxLat value: maxLon.
    bbox := { minXY x. minXY y. maxXY x. maxXY y }.

    size := 768@768.  "smaller than 1024 to speed up"
    epsg := '3857'.
    wmsEndpoint := 'https://data.geopf.fr/wms-r?apikey=essentiels'.

    base := self
        fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2' }
        bbox: bbox size: size epsg: epsg format: 'image/png'
        wmsEndpoint: wmsEndpoint.

    overlay := self
        fetchWmsLayers: {
            'GEOGRAPHICALGRIDSYSTEMS.COASTALMAPS'".
            'IGNF_HYDROGRAPHY.HYDROGRAPHY'.
            'TRANSPORTNETWORKS.ROADS'"
        }
        bbox: bbox size: size epsg: epsg format: 'image/png'
        wmsEndpoint: wmsEndpoint.

    ^ self compositeBase: base withOverlay: overlay
]

{ #category : 'examples' }
QuickMap class >> exampleParis [


"open streetmap example"
	| mapForm |
	mapForm := QuickMap
		           formForMinLat: 48.80
		           minLon: 2.20
		           maxLat: 48.92
		           maxLon: 2.42
		           zoom: 14.

	^mapForm inspect
]

{ #category : 'examples' }
QuickMap class >> exampleParisComposite [
	"Small Paris window: base + roads composited locally."

	| bbox base size wmsEndpoint roads epsg |
	bbox := { 258000. 6251000. 259000. 6252000 }.
	size := 512 @ 512.
	epsg := '3857'.
	wmsEndpoint := 'https://data.geopf.fr/wms-r?apikey=essentiels'.


	base := self
		        fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2' }
		        bbox: bbox
		        size: size
		        epsg: epsg
		        format: 'image/png'.
	"wmsEndpoint: wmsEndpoint"

	roads := self
		         fetchWmsLayers: { 'TRANSPORTNETWORKS.ROADS' }
		         bbox: bbox
		         size: size
		         epsg: epsg
		         format: 'image/png'.
	" wmsEndpoint: wmsEndpoint"

	^ self compositeBase: base withOverlay: roads
]

{ #category : 'examples' }
QuickMap class >> exampleParisPlanIGN [
    "Small Paris window; roads + plan in the order that worked for you."
    | bbox size |
    bbox := { 258000. 6251000. 259000. 6252000 }.  "EPSG:3857 small window"
    size := 512@512.
    ^ self
        fetchWmsLayers: {
            'TRANSPORTNETWORKS.ROADS'.               "overlay"
            'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'      "base"
        }
        bbox: bbox
        size: size
        epsg: '3857'
        format: 'image/png'
]

{ #category : 'examples' }
QuickMap class >> exampleParisTinyIGN [
    | url response body |
    url := 'https://data.geopf.fr/wms-r?apikey=essentiels'
        , '&SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
        , '&LAYERS=TRANSPORTNETWORKS.ROADS'
        , '&CRS=EPSG:3857'
        , '&BBOX=258000,6251000,259000,6252000'
        , '&WIDTH=512&HEIGHT=512'
        , '&FORMAT=image/png'
        , '&STYLES='
        , '&TRANSPARENT=TRUE'.

    response := ZnClient new
        url: url;
        headerAt: 'User-Agent' put: 'Pharo QuickMap';
        timeout: 10;
        get.
 
    body := response contents.
    ^ PNGReadWriter formFromStream: body readStream
]

{ #category : 'canvas drawing - general' }
QuickMap class >> fetchBaseAndRoadsAtBBox: bbox size: size epsg: epsg wmsEndpoint: wmsEndpoint [
    | base roads |
    base := self
        fetchWmsLayers: { 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2' }
        bbox: bbox
        size: size
        epsg: epsg
        format: 'image/png'
        wmsEndpoint: wmsEndpoint. base inspect.
    roads := self
        fetchWmsLayers: { 'TRANSPORTNETWORKS.ROADS' }
        bbox: bbox
        size: size
        epsg: epsg
        format: 'image/png'
        wmsEndpoint: wmsEndpoint. roads inspect.
    ^ self compositeBase: base withOverlay: roads
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
QuickMap class >> fetchWmsLayers: layerNames bbox: bbox size: size epsg: epsg format: aFormat [
    "Convenience using the default endpoint."
    ^ self
        fetchWmsLayers: layerNames
        bbox: bbox
        size: size
        epsg: epsg
        format: aFormat
        wmsEndpoint: self geoportailEndpoint

]

{ #category : 'canvas drawing - general' }
QuickMap class >> fetchWmsLayers: layerNames bbox: bbox size: size epsg: epsg format: aFormat wmsEndpoint: wmsEndpoint [
    | url response body stylesString |
    "Assumes wmsEndpoint already has a '?' (e.g., .../wms-r?apikey=xxx),
     so we append parameters with '&'. If your endpoint has no '?', replace
     the first '&SERVICE=...' with '?SERVICE=...'."
  
    stylesString := self emptyStylesFor: layerNames.
    url := String streamContents: [ :s |
        s
            nextPutAll: wmsEndpoint;  "e.g., https://data.geopf.fr/wms-r?apikey=essentiels"
            nextPutAll: '&SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap';
            nextPutAll: '&LAYERS=', (self commaSeparated: layerNames);
            nextPutAll: '&CRS=EPSG:', epsg;
            nextPutAll: '&BBOX=', (self commaSeparated: bbox);
            nextPutAll: '&WIDTH=', size x asString;
            nextPutAll: '&HEIGHT=', size y asString;
            nextPutAll: '&FORMAT=', aFormat;
            nextPutAll: '&STYLES=', stylesString;
            nextPutAll: '&TRANSPARENT=', (aFormat = 'image/png' ifTrue: [ 'TRUE' ] ifFalse: [ 'FALSE' ]) ].

    response := ZnClient new
        url: url;
        headerAt: 'User-Agent' put: 'Pharo QuickMap';
        timeout: 10;
        get.
    "response isSuccess ifFalse: [ self error: response statusLine ]."
    body := response contents.
    ^ PNGReadWriter formFromStream: body readStream
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
	" ^ 'https://wxs.ign.fr/essentiels/geoportail/r/wms'"

	"^ 'https://gpp3-wxs.ign.fr/essentiels/geoportail/r/wms'"

	"Default GeoPF WMS endpoint with the public key; adjust the key if needed."

	^ 'https://data.geopf.fr/wms-r?apikey=essentiels'
	

"see | url response canvas morph  image |
url := 'https://data.geopf.fr/wms-r'
    , '?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
    , '&apikey=essentiels'
    , '&LAYERS=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'
    , '&CRS=EPSG:3857'
    , '&BBOX=-566616,6120000,-185903,6180000'
    , '&WIDTH=5000&HEIGHT=747'
    , '&FORMAT=image/png'
    , '&STYLES=' 
    , '&TRANSPARENT=TRUE'.

response := ZnClient new
    url: url;
    headerAt: 'User-Agent' put: 'Pharo QuickMap';
    timeout: 10;
    get.
 
 
image := (PNGReadWriter formFromStream: response contents readStream)  .
canvas := RSCanvas new.
canvas add:  (RSBitmap new form: image)  .
canvas @ RSCanvasController.
 
morph := canvas createMorph.
morph extent: image extent. 

scroll := ScrollPane new.
scroll scroller addMorph: morph.
scroll extent: 700@600.
scroll openInWindowLabeled: 'WMS (scroll)'.
"
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

{ #category : 'examples' }
QuickMap class >> lowLevelExample [

	| url response canvas morph image scroll |
	url := 'https://data.geopf.fr/wms-r'
	       , '?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
	       , '&apikey=essentiels'
	       , '&LAYERS=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'
	       , '&CRS=EPSG:3857' , '&BBOX=-566616,6120000,-185903,6180000'
	       , '&WIDTH=5000&HEIGHT=747' , '&FORMAT=image/png' , '&STYLES='
	       , '&TRANSPARENT=TRUE'.

	response := ZnClient new
		            url: url;
		            headerAt: 'User-Agent' put: 'Pharo QuickMap';
		            timeout: 10;
		            get.
	url inspect.
	"Transcript
    show: response statusLine; cr;
    show: (response contents size asString); cr."

	"Inspect the image"
	image := PNGReadWriter formFromStream: response contents readStream.
	canvas := RSCanvas new.
	canvas add: (RSBitmap new form: image).
	canvas @ RSCanvasController.

	morph := canvas createMorph.
	morph extent: image extent. "important: sinon pas de scroll"

	scroll := ScrollPane new.
	scroll scroller addMorph: morph.
	scroll extent: 700 @ 600.
	scroll openInWindowLabeled: 'WMS (scroll)'
]

{ #category : 'url' }
QuickMap class >> osmWmsEndpoint [
    ^ 'https://ows.terrestris.de/osm/service'
]

{ #category : 'url' }
QuickMap class >> tileUrlX: x y: y z: z [

	^ 'https://tile.openstreetmap.org/' , z asString , '/' , x asString
	  , '/' , y asString , '.png'
]

{ #category : 'examples' }
QuickMap class >> wrapExampleWithScrollers: aSymbol [
"self wrapExampleWithScrollers: #exampleParis"
| image canvas morph scroll |
image := self perform: aSymbol.

 
	canvas := RSCanvas new.
	canvas add: (RSBitmap new form: image).
	canvas @ RSCanvasController.

	morph := canvas createMorph.
	morph extent: image extent. "important: sinon pas de scroll"

	scroll := ScrollPane new.
	scroll scroller addMorph: morph.
	scroll extent: 700 @ 600.
	scroll inspect.
	scroll openInWindowLabeled: 'DuickMap with scrolelrs'
]

{ #category : 'examples' }
QuickMap class >> wrapWithScrollers: aForm [
	"self wrapWithScrollers: self exampleParis"

	| canvas morph scroll |
	canvas := RSCanvas new.
	canvas add: (RSBitmap new form: aForm).
	canvas @ RSCanvasController.

	morph := canvas createMorph.
	morph extent: aForm extent. "required for scroll"

	scroll := ScrollPane new.
	scroll scroller addMorph: morph.
	scroll extent: 700 @ 600.
	scroll inspect.
	scroll openInWindowLabeled: 'DuickMap with scrollers'
]
