Class {
	#name : 'QuickGeoportailMap',
	#superclass : 'QuickMap',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'examples' }
QuickGeoportailMap class >> minLat: minLat maxLat: maxLat minLon: minLon maxLon: maxLon [

	^ self new
		  minLat: minLat;
		  maxLat: maxLat;
		  minLon: minLon;
		  maxLon: maxLon;
		  yourself
]

{ #category : 'examples' }
QuickGeoportailMap class >> openOn:aSimulator [

	| wp latitudes mapForm longitudes |
	wp := aSimulator wayPoints.

	latitudes := (wp collect: [ :a | a y ]) asSortedCollection.

	longitudes := (wp collect: [ :a | a x ]) asSortedCollection.


	mapForm := self new
		           minLat: latitudes first;
		           maxLat: latitudes last;
		           minLon: longitudes first;
		           maxLon: longitudes last;
		           yourself.


	mapForm openWithScroller.
	wp keysAndValuesDo: [ :k :v | mapForm addModel: k withID: ('WP_',v printString) asSymbol ].
	wp do: [ :m |
			mapForm
				addShape: ((RSBox  new extent: 10@10)
						 position: (mapForm cartesianLongitude: m x latitude: m y);
						 color: Color blue;
						 yourself)
				withModel: m ].
			
		aSimulator drones do: [ :m |
			mapForm
				addShape: ((RSCircle  size: 20)
						 position: (mapForm cartesianLongitude: m x latitude: m y);
						 color: Color blue;
						 yourself)
				withModel: m ].
			
		^mapForm 
]

{ #category : 'getter' }
QuickGeoportailMap >> buildBackground [

	| url response     imageWidth imageHeight |
	imageWidth := 4000.
	self getExtend.
	imageHeight := (imageWidth * self height / self width) asInteger.
	self imageSize: imageWidth @ imageHeight.
	url := 'https://data.geopf.fr/wms-r'
	       , '?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap'
	       , '&apikey=essentiels'
	       , '&LAYERS=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2'
	       , '&CRS=EPSG:3857' , '&BBOX=' , origin x asInteger printString
	       , ',' , origin y asInteger printString , ','
	       , corner x asInteger printString , ','
	       , corner y asInteger printString , '&WIDTH='
	       , self imageSize x printString , '&HEIGHT='
	       , self imageSize y printString , '&FORMAT=image/png'
	       , '&STYLES=' , '&TRANSPARENT=TRUE'.
	"   , '&BBOX=-566616,6120000,-185903,6180000'"

	response := ZnClient new
		            url: url;
		            headerAt: 'User-Agent' put: 'Pharo QuickMap';
		            timeout: 10;
		            get.


	background := PNGReadWriter formFromStream:
		              response contents readStream
]
