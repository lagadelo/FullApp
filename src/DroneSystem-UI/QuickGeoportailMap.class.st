Class {
	#name : 'QuickGeoportailMap',
	#superclass : 'QuickMap',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
QuickGeoportailMap class >> exampleRefactored [

	^ super exampleRefactored
]

{ #category : 'getter' }
QuickGeoportailMap >> buildBackground [

	| url response origin corner imageWidth imageHeight |
	imageWidth := 5000.
	origin := self toMercatorLongitude: minLon latitude: minLat.
	corner := self toMercatorLongitude: maxLon latitude: maxLat.
	width := (origin x - corner x) abs.
	height := (origin y - corner y) abs.
	imageHeight := (imageWidth * height / width) asInteger.
	url := 'https://data.geopf.fr/wms-r'
	       , '?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
	       , '&apikey=essentiels'
	       , '&LAYERS=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'
	       , '&CRS=EPSG:3857' , '&BBOX=' , origin x asInteger printString
	       , ',' , origin y asInteger printString , ','
	       , corner x asInteger printString , ','
	       , corner y asInteger printString , '&WIDTH='
	       , imageWidth printString , '&HEIGHT='
	       , imageHeight printString , '&FORMAT=image/png' , '&STYLES='
	       , '&TRANSPARENT=TRUE'.
	"   , '&BBOX=-566616,6120000,-185903,6180000'"

	response := ZnClient new
		            url: url;
		            headerAt: 'User-Agent' put: 'Pharo QuickMap';
		            timeout: 10;
		            get.


	background := PNGReadWriter formFromStream:
		              response contents readStream
]
