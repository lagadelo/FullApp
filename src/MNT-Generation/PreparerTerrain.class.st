Class {
	#name : 'PreparerTerrain',
	#superclass : 'Object',
	#instVars : [
		'travail',
		'grille'
	],
	#category : 'MNT-Generation',
	#package : 'MNT-Generation'
}

{ #category : 'execution' }
PreparerTerrain class >> polygone: fichier sortie: dossier options: options [

	^ self new polygone: fichier sortie: dossier options: options
]

{ #category : 'example' }
PreparerTerrain class >> vercors [

	^ self
		  polygone: '/Users/llagadec/Downloads/parcours-vercors.geojson'
		  sortie: '/Users/llagadec/Downloads/terrain'
		  options: Dictionary new
]

{ #category : 'grille' }
PreparerTerrain >> bornes: tuile [

	| x y dx dy |
	x := tuile first.
	y := tuile second.
	dx := tuile third.
	dy := tuile fourth.
	^ {
		  x.
		  (y - (dy * tuile sixth)).
		  (x + (dx * tuile fifth)).
		  y }
]

{ #category : 'systeme' }
PreparerTerrain >> commande: arguments entree: entree sortie: sortie [

	| texte erreur statut |
	erreur := travail / 'erreur.txt'.
	texte := 'PATH=/opt/homebrew/bin:/usr/local/bin:$PATH LC_ALL=C '
	         ,
	         (' ' join: (arguments collect: [ :arg | self quote: arg ])).
	entree ifNotNil: [
		texte := texte , ' < ' , (self quote: entree fullName) ].
	texte := texte , ' > ' , (self quote: sortie fullName) , ' 2> '
	         , (self quote: erreur fullName).
	statut := self shell: texte.
	statut = 0 ifFalse: [
		self error: arguments first , ' a échoué. ' , erreur contents ]
]

{ #category : 'coordonnees' }
PreparerTerrain >> crsDeclare: objet [

	| crs props type |
	objet isDictionary ifFalse: [ ^ nil ].
	crs := objet at: 'crs' ifAbsent: [ ^ nil ].
	crs isString ifTrue: [ ^ crs ].
	crs isDictionary ifFalse: [ ^ nil ].
	props := crs at: 'properties' ifAbsent: [ Dictionary new ].
	type := (crs at: 'type' ifAbsent: [ '' ]) asUppercase.
	type = 'NAME' ifTrue: [ ^ props at: 'name' ].
	type = 'EPSG' ifTrue: [ ^ 'EPSG:' , (props at: 'code') asString ].
	self error: 'Déclaration de CRS inconnue'
]

{ #category : 'raster' }
PreparerTerrain >> decoder: octets colonnes: colonnes lignes: lignes ign: ign [

	| position |
	position := 1.
	^ (1 to: lignes) collect: [ :ligne |
			  | valeurs |
			  valeurs := Float32Array new: colonnes.
			  1 to: colonnes do: [ :colonne |
					  | bits valeur |
					  bits := octets unsignedLongAt: position bigEndian: false.
					  position := position + 4.
					  valeur := Float fromIEEE32Bit: bits.
					  (valeur isFinite not or: [
						   ign and: [ #( -99999 -32768 -999999 ) includes: valeur ] ])
						  ifTrue: [ valeur := -9999.0 ].
					  valeurs at: colonne put: valeur ].
			  valeurs ]
]

{ #category : 'coordonnees' }
PreparerTerrain >> descriptionCrs: crs [

	^ STONJSON fromString: (self
			   resultat: {
					   'gdalsrsinfo'.
					   '-o'.
					   'projjson'.
					   crs }
			   entree: nil)
]

{ #category : 'raster' }
PreparerTerrain >> ecrireCsv: raster dans: fichier [

	| valide |
	valide := false.
	fichier writeStreamDo: [ :flux |
			raster do: [ :ligne |
					ligne
						do: [ :v |
								v = -9999 ifFalse: [ valide := true ].
								flux nextPutAll: (v printShowingDecimalPlaces: 4) ]
						separatedBy: [ flux nextPut: $, ].
					flux lf ] ].
	valide ifFalse: [
		self error: 'Le raster ne contient aucune altitude valide' ]
]

{ #category : 'coordonnees' }
PreparerTerrain >> emprise: points [

	| x y |
	x := points collect: #first.
	y := points collect: #second.
	^ {
		  x min.
		  y min.
		  x max.
		  y max }
]

{ #category : 'coordonnees' }
PreparerTerrain >> epsgMetrique: description [

	| id axes |
	(description at: 'type') = 'ProjectedCRS' ifFalse: [ ^ nil ].
	id := description at: 'id' ifAbsent: [ ^ nil ].
	(id at: 'authority') = 'EPSG' ifFalse: [ ^ nil ].
	axes := (description at: 'coordinate_system') at: 'axis'.
	(axes size >= 2 and: [
			 (axes first at: 'unit') = 'metre' and: [
				 (axes second at: 'unit') = 'metre' ] ]) ifFalse: [ ^ nil ].
	^ 'EPSG:' , (id at: 'code') asString
]

{ #category : 'grille' }
PreparerTerrain >> grillePour: points pas: pas marge: marge ancien: ancien [

	| bornes dx dy ax ay gauche droite bas haut precedent |
	bornes := (self emprise: points)
		          with: { -1. -1. 1. 1 }
		          collect: [ :bord :sens | bord + (marge * sens) ].
	dx := pas first.
	dy := pas second.
	ax := 0.
	ay := 0.
	ancien ifNotNil: [
			ax := (ancien at: 'topLeft') first.
			ay := (ancien at: 'topLeft') second.
			precedent := self bornes: {
					             ax.
					             ay.
					             dx.
					             dy.
					             (ancien at: 'columns').
					             (ancien at: 'rows') }.
			bornes := {
				          (bornes first min: precedent first).
				          (bornes second min: precedent second).
				          (bornes third max: precedent third).
				          (bornes fourth max: precedent fourth) } ].
	gauche := (bornes first - ax / dx + 1e-9) floor.
	bas := (bornes second - ay / dy + 1e-9) floor.
	droite := (bornes third - ax / dx - 1e-9) ceiling.
	haut := (bornes fourth - ay / dy - 1e-9) ceiling.
	(gauche >= droite or: [ bas >= haut ]) ifTrue: [
		self error: 'Emprise vide' ].
	^ {
		  (ax + (gauche * dx)).
		  (ay + (haut * dy)).
		  dx.
		  dy.
		  (droite - gauche).
		  (haut - bas) }
]

{ #category : 'systeme' }
PreparerTerrain >> json: fichier [

	^ STONJSON fromString: fichier contents
]

{ #category : 'systeme' }
PreparerTerrain >> nombre: valeur [

	| nombre |
	nombre := valeur isNumber
		          ifTrue: [ valeur asFloat ]
		          ifFalse: [ Float readFrom: valeur ].
	nombre isFinite ifFalse: [ self error: 'Valeur non finie' ].
	^ nombre
]

{ #category : 'coordonnees' }
PreparerTerrain >> polygone: fichier [

	| objet crs sommets type |
	objet := self json: fichier.
	crs := self crsDeclare: objet.
	objet isDictionary ifTrue: [
			type := objet at: 'type'.
			type = 'FeatureCollection' ifTrue: [
					sommets := objet at: 'features'.
					sommets size = 1 ifFalse: [
						self error: 'Un seul polygone est attendu' ].
					objet := sommets first.
					crs := (self crsDeclare: objet) ifNil: [ crs ] ].
			(objet at: 'type') = 'Feature' ifTrue: [
					objet := objet at: 'geometry'.
					crs := (self crsDeclare: objet) ifNil: [ crs ] ].
			(objet at: 'type') = 'Polygon' ifFalse: [
				self error: 'Un Polygon est attendu' ].
			objet := (objet at: 'coordinates') first ].
	sommets := objet collect: [ :xy |
			           {
				           (self nombre: xy first).
				           (self nombre: xy second) } ].
	(sommets notEmpty and: [ sommets first = sommets last ]) ifTrue: [
		sommets := sommets allButLast ].
	sommets asSet size < 3 ifTrue: [
		self error: 'Trois sommets distincts sont requis' ].
	^ {
		  sommets.
		  crs }
]

{ #category : 'execution' }
PreparerTerrain >> polygone: fichier sortie: dossier options: options [

	| sortie staging |
	sortie := dossier asFileReference asAbsolute.
	sortie exists ifTrue: [
		self error: 'Choisir un nouveau dossier de sortie' ].
	sortie parent ensureCreateDirectory.
	staging := sortie parent / ('.terrain-' , UUID new asString).
	staging ensureCreateDirectory.
	[
		travail := staging / 'travail'.
		travail ensureCreateDirectory.
		self
			produire: fichier asFileReference
			dans: staging
			options: options.
		travail ensureDeleteAll.
		sortie exists ifTrue: [
			self error: 'Le dossier de sortie existe déjà' ].
		staging copy renameTo: sortie basename ] ensure: [
		staging ensureDeleteAll ].
	^ sortie
]

{ #category : 'execution' }
PreparerTerrain >> produire: fichier dans: dossier options: options [

	| polygone points crs sourceMetrique origine yBas localisation emprise region ancien cible epsg projetes dx dy marge mnt mns fournisseur raster meta |
	polygone := self polygone: fichier.
	points := polygone first.
	crs := options
		       at: #crsPoints
		       ifAbsent: [ polygone second ifNil: [ 'EPSG:4326' ] ].
	sourceMetrique := self epsgMetrique: (self descriptionCrs: crs).
	origine := options at: #origine ifAbsent: [ nil ].
	yBas := options at: #yVersLeBas ifAbsent: [ false ].
	origine
		ifNil: [
		yBas ifTrue: [ self error: '#yVersLeBas exige une origine' ] ]
		ifNotNil: [
				sourceMetrique ifNil: [
					self error: 'Une origine exige un CRS métrique' ].
				origine := origine collect: [ :x | self nombre: x ].
				points := points collect: [ :xy |
						          {
							          (origine first + xy first).
							          (origine second + (xy second * (yBas
								             ifTrue: [ -1 ]
								             ifFalse: [ 1 ]))) } ] ].
	localisation := self projeter: points de: crs vers: 'EPSG:4326'.
	emprise := self emprise: localisation.
	(emprise first >= -180 and: [
			 emprise third <= 180 and: [
				 emprise second >= -90 and: [ emprise fourth <= 90 ] ] ])
		ifFalse: [ self error: 'Sommets hors domaine' ].
	region := self region: emprise.
	ancien := (options at: #etendre ifAbsent: [ nil ]) ifNotNil: [
		          :chemin |
		          self json: chemin asFileReference / 'terrain.json' ].
	cible := options at: #crsGrille ifAbsent: [
			         ancien
				         ifNil: [
						         sourceMetrique ifNil: [
								         region = 'ign'
									         ifTrue: [ 'EPSG:2154' ]
									         ifFalse: [ self utm: localisation emprise: emprise ] ] ]
				         ifNotNil: [ ancien at: 'crs' ] ].
	epsg := self epsgMetrique: (self descriptionCrs: cible).
	epsg ifNil: [
		self error: 'La grille exige un CRS EPSG projeté en mètres' ].
	dx := self nombre: (options
			       at: #pas
			       ifAbsent: [
			       ancien
				       ifNil: [ 20 ]
				       ifNotNil: [ (ancien at: 'cellSize') first ] ]).
	dy := self nombre: (options at: #pasNord ifAbsent: [
				       (ancien isNil or: [ options includesKey: #pas ])
					       ifTrue: [ dx ]
					       ifFalse: [ (ancien at: 'cellSize') second ] ]).
	marge := self nombre: (options at: #marge ifAbsent: [ 700 ]).
	(dx > 0 and: [ dy > 0 and: [ marge >= 0 ] ]) ifFalse: [
		self error: 'Vérifier les pas et la marge' ].
	ancien ifNotNil: [
			((ancien at: 'crs') = epsg and: [
					 (ancien at: 'cellSize') asArray = {
						 dx.
						 dy } ]) ifFalse: [
				self error: 'Pour étendre, conserver le CRS et les deux pas' ] ].
	projetes := self projeter: points de: crs vers: epsg.
	grille := self
		          grillePour: projetes
		          pas: {
				          dx.
				          dy }
		          marge: marge
		          ancien: ancien.
	mnt := (options at: #mnt ifAbsent: [ nil ]) ifNotNil: [ :chemin |
		       chemin asFileReference asAbsolute ].
	mns := (options at: #mns ifAbsent: [ nil ]) ifNotNil: [ :chemin |
		       chemin asFileReference asAbsolute ].
	fournisseur := mnt
		               ifNil: [ options at: #source ifAbsent: [ 'auto' ] ]
		               ifNotNil: [ 'geotiff' ].
	fournisseur = 'auto' ifTrue: [ fournisseur := region ].
	(mnt isNil and: [ (#( 'ign' 'usgs' ) includes: fournisseur) not ])
		ifTrue: [
		self error: 'Choisir IGN ou USGS, ou fournir un MNT local' ].
	raster := mnt
		          ifNil: [ self relief: fournisseur epsg: epsg ]
		          ifNotNil: [ self raster: mnt grille: grille epsg: epsg ].
	self ecrireCsv: raster dans: dossier / 'mnt.csv'.
	mns ifNotNil: [
			self
				ecrireCsv: (self raster: mns grille: grille epsg: epsg)
				dans: dossier / 'mns.csv' ].
	meta := {
		        ('version' -> 1).
		        ('crs' -> epsg).
		        ('topLeft' -> {
			         grille first.
			         grille second }).
		        ('cellSize' -> {
			         dx.
			         dy }).
		        ('columns' -> grille fifth).
		        ('rows' -> grille sixth).
		        ('noData' -> -9999.0).
		        ('ground' -> 'mnt.csv').
		        ('surface' -> (mns ifNotNil: [ 'mns.csv' ])).
		        ('polygonProjected' -> projetes).
		        ('source' -> fournisseur).
		        ('inputCrs' -> crs).
		        ('inputOrigin' -> origine).
		        ('inputYDown' -> yBas) } asDictionary.
	dossier / 'terrain.json' writeStreamDo: [ :flux |
			flux
				nextPutAll: (STONJSON toString: meta);
				lf ]
]

{ #category : 'coordonnees' }
PreparerTerrain >> projeter: points de: source vers: cible [

	| entree lignes |
	entree := travail / 'points.txt'.
	entree writeStreamDo: [ :flux |
			points do: [ :xy |
					flux
						nextPutAll: (' ' join: (xy collect: #asString));
						lf ] ].
	lignes := (self
		           resultat: {
				           'gdaltransform'.
				           '-s_srs'.
				           source.
				           '-t_srs'.
				           cible }
		           entree: entree) lines.
	lignes size = points size ifFalse: [
		self error: 'Transformation incomplète' ].
	^ lignes collect: [ :ligne |
			  | champs |
			  champs := ligne substrings.
			  {
				  (self nombre: champs first).
				  (self nombre: champs second) } ]
]

{ #category : 'systeme' }
PreparerTerrain >> quote: valeur [

	| apostrophe |
	apostrophe := (Character value: 39) asString.
	^ apostrophe , (valeur asString
		   copyReplaceAll: apostrophe
		   with:
		   apostrophe , (Character value: 92) asString , apostrophe
		   , apostrophe) , apostrophe
]

{ #category : 'raster' }
PreparerTerrain >> raster: fichier grille: tuile epsg: epsg [

	| warp brut colonnes lignes octets entete |
	warp := travail / 'warp.tif'.
	brut := travail / 'altitudes.bin'.
	colonnes := tuile fifth.
	lignes := tuile sixth.
	{
		warp.
		brut.
		(travail / 'altitudes.hdr').
		(travail / 'altitudes.bin.aux.xml') } do: [ :ref | ref ensureDelete ].
	self
		resultat: {
				'gdalwarp'.
				'-q'.
				'-t_srs'.
				epsg.
				'-te' } , (self bornes: tuile) , {
				'-ts'.
				colonnes.
				lignes.
				'-ot'.
				'Float32'.
				'-dstnodata'.
				'-9999'.
				'-r'.
				'bilinear'.
				fichier fullName.
				warp fullName }
		entree: nil.
	self
		resultat: {
				'gdal_translate'.
				'-q'.
				'-b'.
				'1'.
				'-of'.
				'ENVI'.
				warp fullName.
				brut fullName }
		entree: nil.
	entete := (travail / 'altitudes.hdr') contents.
	((entete includesSubstring: 'byte order = 0') and: [
		 entete includesSubstring: 'header offset = 0' ]) ifFalse: [
		self error: 'ENVI Float32 little-endian attendu' ].
	octets := brut binaryReadStreamDo: [ :flux | flux upToEnd ].
	octets size = (colonnes * lignes * 4) ifFalse: [
		self error: 'Taille raster inattendue' ].
	^ self
		  decoder: octets
		  colonnes: colonnes
		  lignes: lignes
		  ign: false
]

{ #category : 'coordonnees' }
PreparerTerrain >> region: bornes [

	| ouest sud est nord |
	ouest := bornes first.
	sud := bornes second.
	est := bornes third.
	nord := bornes fourth.
	(ouest >= -6 and: [ est <= 10 and: [ sud >= 41 and: [ nord <= 52 ] ] ])
		ifTrue: [ ^ 'ign' ].
	(ouest >= -125.5 and: [
		 est <= -66 and: [ sud >= 24 and: [ nord <= 50 ] ] ]) ifTrue: [
		^ 'usgs' ].
	^ nil
]

{ #category : 'raster' }
PreparerTerrain >> relief: source epsg: epsg [

	| resultat dx dy largeur hauteur |
	dx := grille third.
	dy := grille fourth.
	largeur := grille fifth.
	hauteur := grille sixth.
	resultat := Array new: hauteur.
	0 to: hauteur - 1 by: 640 do: [ :y |
			| lignes |
			lignes := 640 min: hauteur - y.
			1 to: lignes do: [ :j |
			resultat at: y + j put: (Float32Array new: largeur) ].
			0 to: largeur - 1 by: 640 do: [ :x |
					| colonnes tuile valeurs |
					colonnes := 640 min: largeur - x.
					tuile := {
						         (grille first + (x * dx)).
						         (grille second - (y * dy)).
						         dx.
						         dy.
						         colonnes.
						         lignes }.
					valeurs := self tuile: tuile fournisseur: source epsg: epsg.
					1 to: lignes do: [ :j |
							(resultat at: y + j)
								replaceFrom: x + 1
								to: x + colonnes
								with: (valeurs at: j)
								startingAt: 1 ] ] ].
	^ resultat
]

{ #category : 'systeme' }
PreparerTerrain >> resultat: arguments entree: entree [

	| sortie |
	sortie := travail / 'commande.txt'.
	self commande: arguments entree: entree sortie: sortie.
	^ sortie contents
]

{ #category : 'systeme' }
PreparerTerrain >> shell: commande [
    ^ self
        ffiCall: #(int system(String commande))
        module: '/usr/lib/libSystem.B.dylib'
]

{ #category : 'raster' }
PreparerTerrain >> telecharger: url parametres: parametres [

	| arguments fichier |
	fichier := travail / 'reponse.bin'.
	arguments := OrderedCollection withAll:
		             #( 'curl' '--fail' '--silent' '--show-error'
		                '--compressed' '--max-time' '60' '--get' ).
	parametres keysAndValuesDo: [ :cle :valeur |
			arguments
				add: '--data-urlencode';
				add: cle , '=' , valeur asString ].
	arguments
		add: '--output';
		add: fichier fullName;
		add: url.
	self resultat: arguments entree: nil.
	^ fichier
]

{ #category : 'raster' }
PreparerTerrain >> tuile: tuile fournisseur: source epsg: epsg [
	| bbox colonnes lignes fichier octets numero |
	bbox := ',' join: ((self bornes: tuile) collect: #asString).
	colonnes := tuile fifth. lignes := tuile sixth.
	source = 'ign' ifTrue: [
		fichier := self telecharger: 'https://data.geopf.fr/wms-r/wms' parametres: {
			'SERVICE' -> 'WMS'. 'VERSION' -> '1.3.0'. 'REQUEST' -> 'GetMap'.
			'CRS' -> epsg. 'BBOX' -> bbox. 'WIDTH' -> colonnes. 'HEIGHT' -> lignes.
			'LAYERS' -> 'ELEVATION.ELEVATIONGRIDCOVERAGE.HIGHRES'. 'STYLES' -> 'normal'.
			'FORMAT' -> 'image/x-bil;bits=32'} asDictionary.
		octets := fichier binaryReadStreamDo: [:flux | flux upToEnd].
		octets size = (colonnes * lignes * 4) ifFalse: [self error: 'Réponse BIL IGN inattendue'].
		^ self decoder: octets colonnes: colonnes lignes: lignes ign: true].
	numero := epsg allButFirst: 5.
	fichier := self telecharger: 'https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer/exportImage'
		parametres: {'bbox' -> bbox. 'bboxSR' -> numero. 'imageSR' -> numero.
			'size' -> (colonnes asString , ',' , lignes asString). 'format' -> 'tiff'.
			'pixelType' -> 'F32'. 'adjustAspectRatio' -> 'false'. 'f' -> 'image'} asDictionary.
	^ self raster: fichier grille: tuile epsg: epsg

]

{ #category : 'coordonnees' }
PreparerTerrain >> utm: points emprise: bornes [

	| longitude latitude zone |
	longitude := (points collect: #first) sum / points size.
	latitude := (points collect: #second) sum / points size.
	(latitude > -80 and: [
		 latitude < 84 and: [ bornes third - bornes first <= 180 ] ])
		ifFalse: [ self error: 'Préciser le CRS métrique avec #crsGrille' ].
	zone := ((longitude + 180 / 6) floor + 1 max: 1) min: 60.
	^ 'EPSG:' , ((latitude >= 0
		    ifTrue: [ 32600 ]
		    ifFalse: [ 32700 ]) + zone) asString
]
