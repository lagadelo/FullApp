"
Fonds cartographiques d’affichage partagés entre Leaflet et la lecture Pharo.
Un fond distant est reprojeté sur l’emprise du MNT à la résolution de la vidéo.
Le relief et la géométrie optique continuent à provenir du terrain.
"
Class {
	#name : 'SoSeAtelierBasemap',
	#superclass : 'Object',
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'sources' }
SoSeAtelierBasemap class >> sources [
	^ {
		{ 'id' -> 'planIgn'. 'label' -> 'Plan IGN'. 'maxNativeZoom' -> 19.
			'url' -> 'https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal&FORMAT=image/png&TILEMATRIXSET=PM_0_19&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}'.
			'credit' -> #('© IGN · Plan IGN · Licence Ouverte 2.0').
			'homepage' -> 'https://www.data.gouv.fr/datasets/plan-ign'.
			'coverage' -> 'Cartographie détaillée des territoires français.' } asDictionary.
		{ 'id' -> 'usgsTopo'. 'label' -> 'USGS Topo'. 'maxNativeZoom' -> 16.
			'url' -> 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}'.
			'credit' -> #('Source: U.S. Geological Survey, National Geospatial Program' 'The National Map · USGS Topo').
			'homepage' -> 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer'.
			'coverage' -> 'Cartographie détaillée des États-Unis et de leurs territoires.' } asDictionary.
		{ 'id' -> 'sentinel2'. 'label' -> 'Sentinel-2 (mosaïque 2016)'. 'maxNativeZoom' -> 14.
			'url' -> 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless_3857/default/GoogleMapsCompatible/{z}/{y}/{x}.jpg'.
			'credit' -> #('EOxCloudless cloudless.eox.at by EOX IT Services GmbH · CC BY 4.0' 'Contains modified Copernicus Sentinel data 2016 & 2017').
			'homepage' -> 'https://cloudless.eox.at/'.
			'coverage' -> 'Mosaïque mondiale en couleurs naturelles, archive 2016–2017.' } asDictionary }
]

{ #category : 'sources' }
SoSeAtelierBasemap class >> sourceNamed: mode [
	^ self sources detect: [ :source | (source at: 'id') = mode asString ] ifNone: [ nil ]
]

{ #category : 'sources' }
SoSeAtelierBasemap class >> choices [
	^ self sources collect: [ :source | (source at: 'id') asSymbol -> (source at: 'label') ]
]

{ #category : 'loading' }
SoSeAtelierBasemap class >> formOf: source on: terrain [
	| id metadata grid bounds expected storedFile storedDescription temp image |
	id := source at: 'id'.
	metadata := terrain metadata.
	grid := SoSeAtelierTerrain gridOf: metadata.
	bounds := terrain projectedBoundsFor: metadata.
	expected := self rasterExtentFor: bounds.
	storedFile := terrain directory / 'fonds' / (id, '.png').
	storedDescription := storedFile withExtension: 'json'.
	(storedFile isFile and: [ storedDescription isFile ]) ifTrue: [
		| archive |
		archive := STONJSON fromString: storedDescription contents.
		((archive at: 'grid') = grid and: [ (archive at: 'url') = (source at: 'url') ]) ifTrue: [
			image := PNGReadWriter formFromFileNamed: storedFile.
			image extent = expected ifTrue: [ ^ image ] ] ].
	temp := (FileLocator temp / ('sose-fond-', UUID new asString)) ensureCreateDirectory.
	[ [ image := self fetch: source crs: (grid at: 'crs') bounds: bounds size: expected in: temp ]
		on: Error do: [ :error |
			self error: 'Fond ', (source at: 'label'), ' indisponible. ', (source at: 'coverage'),
				' Vérifie la connexion et la disponibilité de GDAL (gdalwarp et gdal_translate). ',
				error messageText ] ] ensure: [ temp ensureDeleteAll ].
	^ image
]

{ #category : 'loading' }
SoSeAtelierBasemap class >> rasterExtentFor: bounds [
	| span scale |
	span := bounds extent.
	scale := (924.0 / span x) min: (640.0 / span y).
	^ (1 max: (span x * scale) rounded) @ (1 max: (span y * scale) rounded)
]

{ #category : 'loading' }
SoSeAtelierBasemap class >> fetch: source crs: crs bounds: bounds size: size in: directory [
	| input warped png |
	input := directory / 'tuiles.xml'.
	warped := directory / 'grille.vrt'.
	png := directory / 'grille.png'.
	input writeStreamDo: [ :stream | stream nextPutAll: (self tmsFor: source) ].
	SoSeAtelierTerrain runGeographicTool: { 'gdalwarp'. '-q'. '-of'. 'VRT'. '-r'. 'bilinear'.
		'-t_srs'. crs. '-te'. bounds left. bounds top. bounds right. bounds bottom.
		'-ts'. size x. size y. input fullName. warped fullName } in: directory.
	SoSeAtelierTerrain runGeographicTool: { 'gdal_translate'. '-q'. '-of'. 'PNG'.
		warped fullName. png fullName } in: directory.
	^ PNGReadWriter formFromFileNamed: png
]

{ #category : 'loading' }
SoSeAtelierBasemap class >> tmsFor: source [
	| url |
	url := ((source at: 'url') copyReplaceAll: '&' with: '&amp;') copyReplaceAll: '{' with: '${'.
	^ '<GDAL_WMS><Service name="TMS"><ServerUrl>', url, '</ServerUrl></Service>',
		'<DataWindow><UpperLeftX>-20037508.342789244</UpperLeftX><UpperLeftY>20037508.342789244</UpperLeftY>',
		'<LowerRightX>20037508.342789244</LowerRightX><LowerRightY>-20037508.342789244</LowerRightY>',
		'<TileLevel>', (source at: 'maxNativeZoom') asString, '</TileLevel>',
		'<TileCountX>1</TileCountX><TileCountY>1</TileCountY><YOrigin>top</YOrigin></DataWindow>',
		'<Projection>EPSG:3857</Projection><BlockSizeX>256</BlockSizeX><BlockSizeY>256</BlockSizeY>',
		'<BandsCount>3</BandsCount><MaxConnections>4</MaxConnections><Timeout>12</Timeout></GDAL_WMS>'
]
