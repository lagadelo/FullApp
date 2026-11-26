"
Construit un raster virtuel à partir des dalles publiques Copernicus GLO-30.
GDAL lit les parties utiles des GeoTIFF et le générateur habituel produit la grille.
"
Class {
	#name : 'SoSeAtelierCopernicusSource',
	#superclass : 'Object',
	#instVars : [ 'sourceUrls' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'source' }
SoSeAtelierCopernicusSource >> baseUrl [
	^ 'https://copernicus-dem-30m.s3.amazonaws.com/'
]

{ #category : 'source' }
SoSeAtelierCopernicusSource >> mosaicFor: bounds padding: margin into: directory [
	| index list names raster |
	index := directory / 'copernicus-index.txt'.
	SoSeAtelierTerrain runGeographicTool: { 'curl'. '--fail'. '--silent'. '--show-error'. '--location'. '--max-time'. '30'.
		'--output'. index fullName. self baseUrl, 'tileList.txt' } in: directory.
	names := self tilesFor: bounds padding: margin available: index contents lines asSet.
	names ifEmpty: [ self error: 'Le catalogue Copernicus GLO-30 ne contient pas de dalle publique pour cette emprise.' ].
	sourceUrls := names collect: [ :name | self baseUrl, name, '/', name, '.tif' ].
	list := directory / 'copernicus-sources.txt'.
	list writeStreamDo: [ :stream | sourceUrls do: [ :url | stream nextPutAll: '/vsicurl/', url; lf ] ].
	raster := directory / 'copernicus.vrt'.
	SoSeAtelierTerrain runGeographicTool: { 'gdalbuildvrt'. '-q'. '-resolution'. 'highest'. '-vrtnodata'. '-9999'.
		'-input_file_list'. list fullName. raster fullName } in: directory.
	raster isFile ifFalse: [ self error: 'GDAL n’a pas pu assembler les dalles Copernicus.' ].
	^ raster
]

{ #category : 'source' }
SoSeAtelierCopernicusSource >> tilesFor: bounds padding: margin available: names [
	| latPad lonPad maxLatitude south north west east tiles |
	latPad := margin / 110000.0.
	south := (bounds second - latPad) max: -90.
	north := (bounds fourth + latPad) min: 90.
	maxLatitude := (south abs max: north abs) min: 89.99.
	lonPad := latPad / (maxLatitude degreesToRadians cos).
	west := (bounds first - lonPad) max: -180.
	east := (bounds third + lonPad) min: 180.
	tiles := OrderedCollection new.
	south floor to: north ceiling - 1 do: [ :latitude |
		west floor to: east ceiling - 1 do: [ :longitude |
			| tile |
			tile := self tileAtLongitude: longitude latitude: latitude.
			(names includes: tile) ifTrue: [ tiles add: tile ] ] ].
	^ tiles
]

{ #category : 'source' }
SoSeAtelierCopernicusSource >> tileAtLongitude: longitude latitude: latitude [
	^ 'Copernicus_DSM_COG_10_', (latitude < 0 ifTrue: [ 'S' ] ifFalse: [ 'N' ]),
		(latitude abs printString padLeftTo: 2 with: $0), '_00_',
		(longitude < 0 ifTrue: [ 'W' ] ifFalse: [ 'E' ]),
		(longitude abs printString padLeftTo: 3 with: $0), '_00_DEM'
]

{ #category : 'source' }
SoSeAtelierCopernicusSource >> recordSourceIn: output [
	| manifest metadata |
	manifest := output / 'terrain.json'.
	metadata := STONJSON fromString: manifest contents.
	metadata at: 'source' put: 'Copernicus DEM GLO-30 Public';
		at: 'sourceTiles' put: sourceUrls asArray;
		at: 'attribution' put: 'Produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved.'.
	manifest writeStreamDo: [ :stream | stream truncate; nextPutAll: (STONJSON toStringPretty: metadata) ]
]
