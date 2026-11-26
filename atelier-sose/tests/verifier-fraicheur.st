| verify makeStep window parameters legacy tracked samples extractor data output simulator |
verify := [ :condition :message | condition ifFalse: [ Error signal: message ] ].
makeStep := [ :tick :positions |
	MacroSimulatorStep new
		timeStep: tick;
		range: 100;
		drones: ((1 to: positions size) collect: [ :id |
			MacroSimulatorDrone new id: id; position: (positions at: id); yourself ]);
		yourself ].
verify value: PointDePassage package = MacroSimulatorDrone package value: 'Package des passages'.
window := MacroSimulatorPassageWindow maxDate: 0.3 secondsPerTick: 0.1.
window recordStep: (makeStep value: 0 value: #(3)).
verify value: (window freshnessGapAheadOf: 3) = Float infinity value: 'Exclusion du point courant'.
window recordStep: (makeStep value: 1 value: #(95)).
verify value: (window freshnessGapAheadOf: 95) = 8 value: 'Passage par l’origine'.
window recordStep: (makeStep value: 3 value: #()).
verify value: (window passages anySatisfy: [ :passage | passage position = 3 ])
	value: 'Un point à la limite d’âge est encore présent'.
window recordStep: (makeStep value: 4 value: #()).
verify value: (window passages collect: #position) = #(95) value: 'Expiration après disparition'.
window recordStep: (makeStep value: 5 value: #()).
verify value: (window freshnessGapAheadOf: 95) = Float infinity value: 'Boucle sans passage valide'.

parameters := MacroSimulatorParameters example1 seed: 351; yourself.
legacy := parameters copy initializeSimulator.
tracked := (parameters copy maxDate: 2; yourself) initializeSimulator.
legacy run: 5; runSingleUpdate: 5.
tracked run: 5; runSingleUpdate: 5.
verify value: legacy class = MacroSimulator value: 'Le réglage par défaut utilise le simulateur legacy'.
verify value: ((legacy history collect: [ :state | state drones collect: #position ]) =
	(tracked history collect: [ :state | state drones collect: #position ]))
	value: 'Même trajectoire avec et sans suivi'.
verify value: (tracked current freshPassages allSatisfy: [ :passage | passage date between: 8 and: 10 ])
	value: 'Fenêtre courante bornée'.
verify value: (tracked history first freshPassages allSatisfy: [ :passage | passage date = 0 ])
	value: 'Reconstitution au tik 0'.

samples := #(4 0 0 3 0).
extractor := MacroSimulatorExtractor label: 'tiks' chain: {
	[ :ages | ages collect: [ :age | age <= 0 ] ].
	[ :flags | flags count: #yourself ] }.
verify value: (extractor evaluateOn: samples) = 3 value: 'Chaîne de blocs'.
extractor := MacroSimulatorExtractor process: [ :serie :values | serie average = values average ]
	overField: #yourself.
verify value: (extractor evaluateOn: samples) value: 'Bloc legacy à deux arguments'.

output := (FileLocator temp / ('recette-fraicheur-', UUID new asString)) ensureCreateDirectory.
data := (MacroExporter directoryName: output fullName) visit: tracked.
verify value: data size = 11 value: 'Une ligne par état'.
verify value: ((output files detect: [ :file | file basename = (tracked behavior exportName, '.csv') ])
	contents includesSubstring: 'freshnessRuptureCount') value: 'Colonnes fraîcheur présentes'.
verify value: ((output / (tracked behavior exportName, '-freshness.csv')) contents
	includesSubstring: 'episodesDeRupture') value: 'CSV agrégé'.
simulator := MacroSimulatorFreshnessScope value: 7 during: [ MacroSimulatorExample example2WithFreshness ].
verify value: simulator parameters maxDate = 7 value: 'Seuil propagé aux exemples'.
verify value: simulator history size = 51 value: 'Variante legacy réellement jouée'.
verify value: (MacroSimulatorExample class includesSelector: #example5WithFreshness) value: 'Sélecteur de la variante example5'.
Stdio stdout nextPutAll: 'Fraîcheur, historique, legacy et exporteur vérifiés. '; nextPutAll: output fullName; lf; flush.
!
