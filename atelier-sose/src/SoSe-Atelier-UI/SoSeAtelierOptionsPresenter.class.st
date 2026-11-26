Class {
	#name : 'SoSeAtelierOptionsPresenter',
	#superclass : 'SoSeAtelierFormPresenter',
	#instVars : [ 'notebook', 'rateLabel', 'pendingDroneChoices' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierOptionsPresenter >> initializePresenters [
	super initializePresenters.
	pendingDroneChoices := Dictionary new.
	self initializeViewControls.
	self initializePlaybackControls.
	self class metricChoices do: [ :each |
		self check: each key label: each value initial: (#(fleetSize avgSpeed maxGap stdGap coverageRatio) includes: each key) ].
	self check: #useMetricZone label: 'Mesurer dans la zone GPS de Lecture' initial: false.
	self number: #minimumFreshPercent initial: 75.0 from: 0 to: 100.
	notebook := self newNotebook
		addPageTitle: 'Affichage' provider: [ self scrollPage: self displayLayout ];
		addPageTitle: 'Lecture' provider: [ self scrollPage: self playbackLayout ];
		addPageTitle: 'CSV' provider: [ self scrollPage: self metricsLayout ];
		yourself
]

{ #category : 'initialization' }
SoSeAtelierOptionsPresenter >> initializeViewControls [
	self choice: #background labels:
		{ #hillshade -> 'Relief ombré'. #elevation -> 'Altitude'. #none -> 'Aucun' }, SoSeAtelierBasemap choices.
	self choice: #droneColorMode labels: { #acceleration -> 'Accélération'. #speed -> 'Vitesse'. #none -> 'Uniforme' }.
	self choice: #focusDrone labels: { nil -> 'Aucun' }.
	self number: #height initial: 180.0 from: 1 to: 10000.
	self number: #fieldOfView initial: 53.13 from: 1 to: 170.
	self number: #accelerationThreshold initial: 0.05 from: 0 to: 100.
	self number: #fadeAfterSeconds initial: 40.0 from: 0 to: 1000000.
	self number: #transparentAfterSeconds initial: 75.0 from: 0.01 to: 1000000.
	self check: #trackPassages label: 'Suivre la fraîcheur des passages' initial: false.
	self number: #lossMarkerSeconds initial: 40.0 from: 0 to: 1000000.
	self class displayLayers do: [ :each |
		self check: each key label: each value
			initial: (#(showDroneNames showDroneStatus) includes: each key) not ]
]

{ #category : 'initialization' }
SoSeAtelierOptionsPresenter >> initializePlaybackControls [
	self number: #stride initial: 5 from: 1 to: 10000.
	rateLabel := self newLabel label: '20×'; yourself.
	(self slider: #normalRate initial: 20 from: 1 to: 120)
		whenValueChangedDo: [ :value | rateLabel label: value rounded printString, '×' ].
	self number: #slowRate initial: 4.0 from: 0.05 to: 120.
	self check: #slowInterval label: 'Ralentir un intervalle de tiks' initial: true.
	self number: #fromTick initial: 45 from: 0 to: 1000000.
	self number: #toTick initial: 70 from: 0 to: 1000000.
	self check: #hotspot label: 'Ralentir dans la zone GPS' initial: false.
	self choice: #hotspotDrone labels: { nil -> 'Tous les drones' }.
	self number: #west initial: 5.35 from: -180 to: 180.
	self number: #south initial: 44.87 from: -90 to: 90.
	self number: #east initial: 5.36 from: -180 to: 180.
	self number: #north initial: 44.88 from: -90 to: 90
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter class >> displayLayers [
	^ { #showRoute -> 'Tracer le parcours'. #showCoverage -> 'Afficher la couverture'.
		#showMasks -> 'Hachurer les masques'. #showDrones -> 'Afficher les drones'.
		#showDroneNames -> 'Afficher les identifiants'. #showDroneStatus -> 'Afficher les statuts'.
		#showLossMarkers -> 'Afficher les retraits'. #showFocusFootprint -> 'Surligner le champ du drone suivi' }
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter class >> metricChoices [
	^ { #fleetSize -> 'Effectif'. #avgSpeed -> 'Vitesse moyenne · m/tik'.
		#stdGap -> 'Écart type des espacements'. #maxGap -> 'Espacement maximal'.
		#coverageRatio -> 'Couverture macro'. #directPerceptionRatio -> 'Perception directe'.
		#angularPerceptionRatio -> 'Perception angulaire'.
		#unobservablePerceptionRatio -> 'Perception indisponible'.
		#outOfRangePerceptionRatio -> 'Observation hors portée'.
		#avgGapEstimationError -> 'Erreur moyenne d’écart · m'.
		#minFreshness -> 'Fraîcheur minimale avant · s'.
		#maxFreshnessGap -> 'Écart maximal au prochain passage · m'.
		#freshnessRuptureCount -> 'Drones en rupture au tik'.
		#freshnessRupture -> 'Rupture au tik'.
		#opticalCoverageRatio -> 'Couverture optique instantanée'.
		#freshCoverageRatio -> 'Fraction de cases fraîches'.
		#freshnessStatus -> 'Verdict de fraîcheur' }
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter class >> opticalFields [
	^ #(opticalCoverageRatio freshCoverageRatio freshnessStatus)
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter class >> passageFields [
	^ #(minFreshness maxFreshnessGap freshnessRuptureCount freshnessRupture)
]

{ #category : 'layout' }
SoSeAtelierOptionsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom add: notebook; yourself
]

{ #category : 'layout' }
SoSeAtelierOptionsPresenter >> displayLayout [
	| panel |
	panel := self column
		add: (self row: 'Fond de carte' field: #background) height: 29;
		add: (self row: 'Couleurs des drones' field: #droneColorMode) height: 29;
		add: (self row: 'Hauteur sol · m' field: #height) height: 29;
		add: (self row: 'Champ optique · °' field: #fieldOfView) height: 29;
		add: (self row: 'Seuil accél. · m/s²' field: #accelerationThreshold) height: 29;
		add: (self row: 'Blanc complet · s' field: #fadeAfterSeconds) height: 29;
		add: (self row: 'Effacement · s' field: #transparentAfterSeconds) height: 29;
		add: (self field: #trackPassages) height: 26;
		add: (self row: 'Durée du retrait · s' field: #lossMarkerSeconds) height: 29;
		add: (self row: 'Incruster le drone' field: #focusDrone) height: 29;
		yourself.
	self class displayLayers do: [ :each | panel add: (self field: each key) height: 24 ].
	^ panel
]

{ #category : 'layout' }
SoSeAtelierOptionsPresenter >> playbackLayout [
	^ self column
		add: (self row: 'Un PNG tous les' field: #stride) height: 29;
		add: (SpBoxLayout newLeftToRight
			add: (self newLabel label: 'Vitesse normale'; yourself);
			add: rateLabel width: 50; yourself) height: 24;
		add: (self field: #normalRate) height: 29;
		add: (self row: 'Vitesse ralentie · ×' field: #slowRate) height: 29;
		add: (self field: #slowInterval) height: 26;
		add: (self row: 'Tik de début' field: #fromTick) height: 29;
		add: (self row: 'Tik de fin' field: #toTick) height: 29;
		add: (self field: #hotspot) height: 26;
		add: (self row: 'Déclenchement par' field: #hotspotDrone) height: 29;
		add: (self row: 'Longitude ouest · °' field: #west) height: 29;
		add: (self row: 'Latitude sud · °' field: #south) height: 29;
		add: (self row: 'Longitude est · °' field: #east) height: 29;
		add: (self row: 'Latitude nord · °' field: #north) height: 29;
		yourself
]

{ #category : 'layout' }
SoSeAtelierOptionsPresenter >> metricsLayout [
	| panel |
	panel := self column
		add: (self newLabel label: 'Colonnes du CSV · une ligne par tik'; yourself) height: 25;
		yourself.
	self class metricChoices do: [ :each | panel add: (self field: each key) height: 25 ].
	panel
		add: (self field: #useMetricZone) height: 27;
		add: (self row: 'Cible fraîcheur · %' field: #minimumFreshPercent) height: 29.
	^ panel
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter >> setDroneIds: ids [
	| choices previous |
	choices := (ids asSortedCollection collect: [ :id | id -> ('Drone ', id printString) ]) asArray.
	{ #focusDrone -> 'Aucun'. #hotspotDrone -> 'Tous les drones' } do: [ :setting |
		| menu items |
		menu := self field: setting key.
		previous := pendingDroneChoices at: setting key ifAbsent: [ menu selectedItem key ].
		items := { nil -> setting value }, choices.
		menu items: items;
			selectItem: (items detect: [ :item | item key = previous ] ifNone: [ items first ]).
		ids ifNotEmpty: [ pendingDroneChoices removeKey: setting key ifAbsent: [ ] ] ]
]

{ #category : 'serializing' }
SoSeAtelierOptionsPresenter >> configuration [
	| settings |
	settings := Dictionary new.
	self class numericalSettings do: [ :key | settings at: key asString put: (self field: key) number ].
	self class checkboxSettings do: [ :key | settings at: key asString put: (self field: key) state ].
	#(background droneColorMode) do: [ :key | settings at: key asString put: (self choiceValue: key) asString ].
	#(focusDrone hotspotDrone) do: [ :key |
		settings at: key asString put: (pendingDroneChoices at: key ifAbsent: [ self choiceValue: key ]) ].
	settings at: 'normalRate' put: (self field: #normalRate) value.
	^ settings
]

{ #category : 'serializing' }
SoSeAtelierOptionsPresenter >> loadConfiguration: settings [
	self class numericalSettings do: [ :key |
		settings at: key asString ifPresent: [ :value | (self field: key) number: value ] ].
	self class checkboxSettings do: [ :key |
		settings at: key asString ifPresent: [ :value | (self field: key) state: value ] ].
	#(background droneColorMode) do: [ :key |
		settings at: key asString ifPresent: [ :value | self selectChoice: value asSymbol ofField: key ] ].
	#(focusDrone hotspotDrone) do: [ :key |
		settings at: key asString ifPresent: [ :id |
			self selectChoice: id ofField: key.
			pendingDroneChoices at: key put: id ] ].
	settings at: 'normalRate' ifPresent: [ :value | (self field: #normalRate) value: value ]
]

{ #category : 'serializing' }
SoSeAtelierOptionsPresenter class >> numericalSettings [
	^ #(height fieldOfView accelerationThreshold fadeAfterSeconds transparentAfterSeconds lossMarkerSeconds
		stride slowRate fromTick toTick west south east north minimumFreshPercent)
]

{ #category : 'serializing' }
SoSeAtelierOptionsPresenter class >> checkboxSettings [
	^ #(slowInterval hotspot useMetricZone trackPassages), (self displayLayers collect: #key), (self metricChoices collect: #key)
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> passageMaxDateFor: scenario [
	((self field: #trackPassages) state or: [ scenario asString endsWith: 'WithFreshness' ])
		ifFalse: [ ^ nil ].
	^ (self field: #transparentAfterSeconds) number
]

{ #category : 'configuration' }
SoSeAtelierOptionsPresenter >> useScenario: scenario [
	| from to |
	from := scenario = #vercors ifTrue: [ 45 ] ifFalse: [ 190 ].
	to := scenario = #vercors ifTrue: [ 70 ] ifFalse: [ 215 ].
	(self field: #fromTick) number: from.
	(self field: #toTick) number: to.
	(self field: #slowInterval) state: (#(vercors sose) includes: scenario)
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> displaySettings [
	| options angle |
	options := Dictionary new.
	self class displayLayers do: [ :each | options at: each key put: (self field: each key) state ].
	#(height accelerationThreshold fadeAfterSeconds transparentAfterSeconds lossMarkerSeconds)
		do: [ :key | options at: key put: (self field: key) number ].
	#(background droneColorMode focusDrone)
		do: [ :key | options at: key put: (self choiceValue: key) ].
	angle := (self field: #fieldOfView) number * Float pi / 360.0.
	options at: #camera put: { angle tan. 2000 }.
	^ options
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> playbackSettings [
	| from to interval |
	from := (self field: #fromTick) number.
	to := (self field: #toTick) number.
	interval := (self field: #slowInterval) state
		ifTrue: [
			from > to ifTrue: [ self error: 'Le tik de fin doit suivre le tik de début.' ].
			from to: to ]
		ifFalse: [ #() ].
	^ { #stride -> (self field: #stride) number.
		#normalRate -> (self field: #normalRate) value. #slowRate -> (self field: #slowRate) number.
		#interval -> interval. #hotspot -> self hotspotCorners. #hotspotDrone -> (self choiceValue: #hotspotDrone) } asDictionary
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> metricFields [
	^ #(timeStep), (self class metricChoices
		select: [ :each | (self field: each key) state ] thenCollect: #key)
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> hotspotCorners [
	^ (self field: #hotspot) state ifTrue: [ self zoneCorners ]
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> metricZoneCorners [
	^ (self field: #useMetricZone) state ifTrue: [ self zoneCorners ]
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> zoneCorners [
	^ { (self field: #west) number @ (self field: #south) number.
		(self field: #east) number @ (self field: #north) number }
]

{ #category : 'accessing' }
SoSeAtelierOptionsPresenter >> minimumFreshRatio [
	^ (self field: #minimumFreshPercent) number / 100.0
]
