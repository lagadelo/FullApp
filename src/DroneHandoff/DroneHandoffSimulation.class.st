Class {
	#name : 'DroneHandoffSimulation',
	#superclass : 'Object',
	#instVars : [
		'perception',
		'action',
		'distanceKm',
		'speedKmh',
		'slaSeconds',
		'printReport',
		'nRuns'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'eaxmples - facilities' }
DroneHandoffSimulation class >> buildMonteCarlo [
	 

	| sim p a |
	sim := self new.
	p := sim perception.
	a := sim action.
	p
		tRevisit: (StochasticParam normal: 4.0 stddev: 0.8);
		tDetect: (StochasticParam normal: 0.5 stddev: 0.1);
		tTrackInit: (StochasticParam normal: 2.0 stddev: 0.4);
		tClass: (StochasticParam normal: 1.5 stddev: 0.3);
		tQualif: (StochasticParam normal: 1.0 stddev: 0.2);
		tEvidence: (StochasticParam normal: 2.0 stddev: 0.4);
		tQueueEdge: (StochasticParam uniform: 0.1 to: 1.0);
		tTx: (StochasticParam normal: 0.2 stddev: 0.05);
		tFuse: (StochasticParam normal: 3.0 stddev: 0.6);
		tDecide: (StochasticParam normal: 5.0 stddev: 1.5).
	a
		tTask: (StochasticParam normal: 2.0 stddev: 0.5);
		tTx: (StochasticParam normal: 0.2 stddev: 0.05);
		tLaunch: (StochasticParam normal: 8.0 stddev: 2.0);
		tIntercept: (StochasticParam uniform: 30.0 to: 70.0);
		tEffect: (StochasticParam normal: 5.0 stddev: 1.5).
	sim
		distanceKm: 12.0;
		speedKmh: 80.0;
		slaSeconds: 120.0;
		nRuns: 10000.
	^ sim 
]

{ #category : 'exploration' }
DroneHandoffSimulation class >> compareScenarios [
	"Affiche un tableau comparatif : nominal vs MC vs réseau dégradé vs pire cas."

	| scenarios fmt pad |
	scenarios := {
		             ('Nominal' -> [ self scenarioNominal ]).
		             ('Monte Carlo' -> [ self scenarioMonteCarlo ]).
		             ('Réseau dégradé' -> [ self scenarioNetworkDegraded ]).
		             ('Pire cas' -> [ self scenarioWorstCase ]) }.

	"Padding droite : complète avec des espaces jusqu'à la largeur voulue"
	pad := [ :str :width |
		       | s |
		       s := str asString.
		       s size < width
			       ifTrue: [ s , (String new: width - s size withAll: $ ) ]
			       ifFalse: [ s copyFrom: 1 to: width ] ].

	fmt := [ :v | pad value: (v roundTo: 0.1) printString value: 7 ].

	Transcript cr.
	Transcript
		show:
			'Scénario           | Mean  | Std   | P50   | P95   | P(SLA)  | P(Win)';
		cr.
	Transcript
		show:
			'-------------------|-------|-------|-------|-------|---------|-------';
		cr.

	scenarios do: [ :assoc |
			| r |
			r := assoc value value.
			Transcript cr;
				show:
					(pad value: assoc key value: 19) , '| '
					, (fmt value: (r at: #mean)) , '| '
					, (fmt value: (r at: #stddev)) , '| ' , (fmt value: (r at: #p50))
					, '| ' , (fmt value: (r at: #p95)) , '| '
					, (fmt value: (r at: #pSlaRespected)) , '| '
					, (fmt value: (r at: #pWindowRespected));
				cr ].
			^scenarios
]

{ #category : 'examples' }
DroneHandoffSimulation class >> example [
	"======================================================"

	"  Exemple d'utilisation"

	"======================================================"

	| sim p a results |
	sim := self new.
	p := sim perception.
	a := sim action.

	"--- Paramètres perception ---"
	p tRevisit: 4.0.
	p tDetect: 0.5.
	p tTrackInit: 2.0.
	p tClass: 1.5.
	p tQualif: 1.0.
	p tEvidence: 2.0.
	p tQueueEdge: 0.3.
	p tTx: 0.2.
	p tFuse: 3.0.
	p tDecide: 5.0.

	"--- Paramètres action ---"
	a tTask: 2.0.
	a tTx: 0.2.
	a tLaunch: 8.0.
	a tIntercept: 45.0.
	a tEffect: 5.0.

	"--- Paramètres scénario ---"
	sim distanceKm: 12.0.
	sim speedKmh: 80.0.
	sim slaSeconds: 120.0.
	sim printReport: true.

	^ results := sim run
]

{ #category : 'examples' }
DroneHandoffSimulation class >> exampleWithDistribution [
	"======================================================"

	"  Exemple d'utilisation avec distributions"

	"======================================================"

	| sim p a |
	sim := DroneHandoffSimulation new.
	p := sim perception.
	a := sim action.

	"--- Perception : moyenne ± stddev (secondes) ---"
	p tRevisit: (StochasticParam normal: 4.0 stddev: 1.0).
	p tDetect: (StochasticParam normal: 0.5 stddev: 0.1).
	p tTrackInit: (StochasticParam normal: 2.0 stddev: 0.5).
	p tClass: (StochasticParam normal: 1.5 stddev: 0.4).
	p tQualif: (StochasticParam normal: 1.0 stddev: 0.2).
	p tEvidence: (StochasticParam normal: 2.0 stddev: 0.5).
	p tQueueEdge: (StochasticParam uniform: 0.1 to: 1.0). "variable réseau"
	p tTx: (StochasticParam normal: 0.2 stddev: 0.05).
	p tFuse: (StochasticParam normal: 3.0 stddev: 1.0).
	p tDecide: (StochasticParam normal: 5.0 stddev: 2.0). "forte variabilité humaine"

	"--- Action ---"
	a tTask: (StochasticParam normal: 2.0 stddev: 0.5).
	a tTx: (StochasticParam normal: 0.2 stddev: 0.05).
	a tLaunch: (StochasticParam normal: 8.0 stddev: 2.0).
	a tIntercept: (StochasticParam uniform: 30.0 to: 70.0). "dépend position intercepteur"
	a tEffect: (StochasticParam normal: 5.0 stddev: 1.5).

	"--- Scénario ---"
	sim distanceKm: 12.0.
	sim speedKmh: 80.0.
	sim slaSeconds: 120.0.
	sim nRuns: 10000.

	sim run
]

{ #category : 'usage' }
DroneHandoffSimulation class >> howTo [
	"Déterministe"

	DroneHandoffSimulation scenarioNominal.

	"Monte Carlo de base"
	DroneHandoffSimulation scenarioMonteCarlo.

	"Réseau dégradé (Cholesky)"
	DroneHandoffSimulation scenarioNetworkDegraded.

	"Pire cas"
	DroneHandoffSimulation scenarioWorstCase.

	"Sensibilité sur tDecide"
	DroneHandoffSimulation
		sensitivityOn: [ :p :v |
		p tDecide: (StochasticParam normal: 5.0 stddev: v) ]
		stddevRange: #( 0.5 1.0 2.0 3.0 5.0 ).

	" Exploratoire"

	"Quels paramètres métier sont les plus risqués ?"
	DroneHandoffSimulation tornadoAnalysis.

	"À partir de quelle latence de décision le SLA devient critique ?"
	DroneHandoffSimulation
		sweepMean: 'tDecide'
		from: 2.0
		to: 20.0
		steps: 10.

	"Vue d'ensemble comparative"
	DroneHandoffSimulation compareScenarios
]

{ #category : 'examples' }
DroneHandoffSimulation class >> scenarioMonteCarlo [

	^ self buildMonteCarlo run
]

{ #category : 'examples' }
DroneHandoffSimulation class >> scenarioNetworkDegraded [

	| sim corrMatrix |
	sim := self buildMonteCarlo. "réutilise sans dupliquer"
	corrMatrix := (Array new: 10) collect: [ :x |
		              Array new: 10 withAll: 0.0 ].
	1 to: 10 do: [ :i | (corrMatrix at: i) at: i put: 1.0 ].
	(corrMatrix at: 7) at: 8 put: 0.85.
	(corrMatrix at: 8) at: 7 put: 0.85.
	sim perception correlationMatrix: corrMatrix.
	^ sim run
]

{ #category : 'examples' }
DroneHandoffSimulation class >> scenarioNominal [
	"Scénario nominal : tous fixed, pas de cholesky
	Pipeline entièrement déterministe, valeurs nominales de référence."

	| sim |
	sim := self new.
	sim perception
		tRevisit: (StochasticParam fixed: 4.0);
		tDetect: (StochasticParam fixed: 0.5);
		tTrackInit: (StochasticParam fixed: 2.0);
		tClass: (StochasticParam fixed: 1.5);
		tQualif: (StochasticParam fixed: 1.0);
		tEvidence: (StochasticParam fixed: 2.0);
		tQueueEdge: (StochasticParam fixed: 0.3);
		tTx: (StochasticParam fixed: 0.2);
		tFuse: (StochasticParam fixed: 3.0);
		tDecide: (StochasticParam fixed: 5.0).
	sim action
		tTask: (StochasticParam fixed: 2.0);
		tTx: (StochasticParam fixed: 0.2);
		tLaunch: (StochasticParam fixed: 8.0);
		tIntercept: (StochasticParam fixed: 45.0);
		tEffect: (StochasticParam fixed: 5.0).
	sim
		distanceKm: 12.0;
		speedKmh: 80.0;
		slaSeconds: 120.0.
	^ sim run
]

{ #category : 'examples' }
DroneHandoffSimulation class >> scenarioWorstCase [
	"Scénario pire cas : drone rapide, SLA serré, opérateurs sous pression
	Drone rapide (150 km/h sur 5 km) => seulement 120 s disponibles.
     SLA = 90 s. tDecide très variable (stress opérateur)."

	| sim p a |
	sim := self new.
	p := sim perception.
	a := sim action.
	p
		tRevisit: (StochasticParam normal: 6.0 stddev: 2.0);
		tDetect: (StochasticParam normal: 1.0 stddev: 0.3);
		tTrackInit: (StochasticParam normal: 3.0 stddev: 1.0);
		tClass: (StochasticParam normal: 2.0 stddev: 0.8);
		tQualif: (StochasticParam normal: 1.5 stddev: 0.5);
		tEvidence: (StochasticParam normal: 3.0 stddev: 1.0);
		tQueueEdge: (StochasticParam uniform: 0.5 to: 3.0);
		tTx: (StochasticParam normal: 0.5 stddev: 0.2);
		tFuse: (StochasticParam normal: 4.0 stddev: 2.0);
		tDecide: (StochasticParam normal: 8.0 stddev: 4.0). "stress"
	a
		tTask: (StochasticParam normal: 3.0 stddev: 1.0);
		tTx: (StochasticParam normal: 0.5 stddev: 0.2);
		tLaunch: (StochasticParam normal: 12.0 stddev: 3.0);
		tIntercept: (StochasticParam uniform: 20.0 to: 50.0);
		tEffect: (StochasticParam normal: 8.0 stddev: 2.0).
	sim
		distanceKm: 5.0;
		speedKmh: 150.0;
		slaSeconds: 90.0;
		nRuns: 10000.
	^ sim run
]

{ #category : 'exploration' }
DroneHandoffSimulation class >> sensitivityOn: aParamSetter stddevRange: aCollection [
	"Renvoie une collection de résultats pour chaque valeur de stddev.
     Exemple d'appel :
       DroneHandoffSimulation
           sensitivityOn: [ :p :v | p tDecide: (StochasticParam normal: 5.0 stddev: v) ]
           stddevRange: #(0.5 1.0 2.0 3.0 5.0)"

	^ aCollection collect: [ :sigma |
			  | sim |
			  sim := self new.
			  aParamSetter value: sim perception value: sigma.
			  sim
				  distanceKm: 12.0;
				  speedKmh: 80.0;
				  slaSeconds: 120.0;
				  nRuns: 5000;
				  printReport: false.
			  Dictionary new
				  at: #sigma put: sigma;
				  at: #result put: sim run;
				  yourself ]
]

{ #category : 'eaxmples - facilities' }
DroneHandoffSimulation class >> setterFor: aName [
	"Retourne un bloc [:perception :mean :stddev | ...]"

	^ {
		  ('tRevisit'
		   -> [ :p :m :s |
		   p tRevisit: (StochasticParam normal: m stddev: s) ]).
		  ('tDetect'
		   -> [ :p :m :s | p tDetect: (StochasticParam normal: m stddev: s) ]).
		  ('tTrackInit'
		   -> [ :p :m :s |
		   p tTrackInit: (StochasticParam normal: m stddev: s) ]).
		  ('tClass'
		   -> [ :p :m :s | p tClass: (StochasticParam normal: m stddev: s) ]).
		  ('tQualif'
		   -> [ :p :m :s | p tQualif: (StochasticParam normal: m stddev: s) ]).
		  ('tEvidence'
		   -> [ :p :m :s |
		   p tEvidence: (StochasticParam normal: m stddev: s) ]).
		  ('tQueueEdge'
		   -> [ :p :m :s |
		   p tQueueEdge: (StochasticParam normal: m stddev: s) ]).
		  ('tTx'
		   -> [ :p :m :s | p tTx: (StochasticParam normal: m stddev: s) ]).
		  ('tFuse'
		   -> [ :p :m :s | p tFuse: (StochasticParam normal: m stddev: s) ]).
		  ('tDecide'
		   -> [ :p :m :s | p tDecide: (StochasticParam normal: m stddev: s) ]) }
		  detect: [ :a | a key = aName ]
		  ifNone: [ Error signal: 'Param inconnu : ' , aName ]
	"retourne la valeur (le bloc)"
]

{ #category : 'exploration' }
DroneHandoffSimulation class >> sweepMean: aParamName from: aMin to: aMax steps: n [
	"Fait varier la moyenne d'un paramètre et trace P(SLA OK).
     Exemple : self sweepMean: #tDecide from: 2.0 to: 15.0 steps: 14"

	| step setter |
	step := aMax - aMin / (n - 1).
	setter := self setterFor: aParamName.

	Transcript
		show: '=== Sweep ' , aParamName , ' ===';
		cr.
	^ (0 to: n - 1) collect: [ :k |
			  | mean sim res |
			  mean := aMin + (k * step).
			  sim := self buildMonteCarlo.
			  sim printReport: false.
			  setter value value: sim perception value: mean value: mean * 0.3.
			  res := sim run.
			  Transcript show:
				  '  μ=' , (mean roundTo: 0.1) printString , '  P(SLA)='
				  , ((res at: #pSlaRespected) roundTo: 0.1) printString , '%'.
			  mean -> (res at: #pSlaRespected) ]
]

{ #category : 'exploration' }
DroneHandoffSimulation class >> tornadoAnalysis [
	"Pour chaque paramètre de perception, mesure l'impact d'un doublement
     du stddev sur le P95. Retourne un Array trié par impact décroissant."

	| baseline setters results |
	baseline := (self buildMonteCarlo
		             printReport: false;
		             yourself) run.

	"Association nom → bloc de mutation"
	setters := {
		           ('tRevisit'
		            -> [ :p |
		            p tRevisit: (StochasticParam normal: 4.0 stddev: 1.6) ]).
		           ('tDetect'
		            -> [ :p |
		            p tDetect: (StochasticParam normal: 0.5 stddev: 0.2) ]).
		           ('tTrackInit'
		            -> [ :p |
		            p tTrackInit: (StochasticParam normal: 2.0 stddev: 0.8) ]).
		           ('tClass'
		            -> [ :p |
		            p tClass: (StochasticParam normal: 1.5 stddev: 0.6) ]).
		           ('tQualif'
		            -> [ :p |
		            p tQualif: (StochasticParam normal: 1.0 stddev: 0.4) ]).
		           ('tEvidence'
		            -> [ :p |
		            p tEvidence: (StochasticParam normal: 2.0 stddev: 0.8) ]).
		           ('tQueueEdge'
		            -> [ :p |
		            p tQueueEdge: (StochasticParam uniform: 0.1 to: 2.0) ]).
		           ('tTx'
		            -> [ :p |
		            p tTx: (StochasticParam normal: 0.2 stddev: 0.1) ]).
		           ('tFuse'
		            -> [ :p |
		            p tFuse: (StochasticParam normal: 3.0 stddev: 1.2) ]).
		           ('tDecide'
		            -> [ :p |
		            p tDecide: (StochasticParam normal: 5.0 stddev: 3.0) ]) }.

	results := setters collect: [ :assoc |
			           | sim res deltaP95 |
			           sim := self buildMonteCarlo.
			           sim printReport: false.
			           assoc value value: sim perception.
			           res := sim run.
			           deltaP95 := (res at: #p95) - (baseline at: #p95).
			           assoc key -> deltaP95 ].

	"Tri par impact décroissant"
	results := results asSortedCollection: [ :a :b | a value > b value ].

	Transcript
		show: '=== Tornado Analysis — Impact sur P95 ===';
		cr.
	results do: [ :assoc |
			Transcript
				show:
					'  ' , assoc key , ' : +'
					, (assoc value roundTo: 0.01) printString , ' s';
				cr ].
	^ results
]

{ #category : 'accessing' }
DroneHandoffSimulation >> action [

	^ action
]

{ #category : 'accessing' }
DroneHandoffSimulation >> action: anObject [

	action := anObject
]

{ #category : 'accessing' }
DroneHandoffSimulation >> distanceKm [

	^ distanceKm
]

{ #category : 'accessing' }
DroneHandoffSimulation >> distanceKm: anObject [

	distanceKm := anObject
]

{ #category : 'initialization' }
DroneHandoffSimulation >> initialize [

	perception := DronePerceptionChain new.
	action := DroneActionChain new.
	nRuns := 10000.
	printReport := true
]

{ #category : 'accessing' }
DroneHandoffSimulation >> nRuns [

	^ nRuns
]

{ #category : 'accessing' }
DroneHandoffSimulation >> nRuns: anObject [

	nRuns := anObject
]

{ #category : 'accessing' }
DroneHandoffSimulation >> perception [

	^ perception
]

{ #category : 'accessing' }
DroneHandoffSimulation >> perception: anObject [

	perception := anObject
]

{ #category : 'accessing' }
DroneHandoffSimulation >> printReport [

	^ printReport
]

{ #category : 'accessing' }
DroneHandoffSimulation >> printReport: anObject [

	printReport := anObject
]

{ #category : 'printing' }
DroneHandoffSimulation >> printReport: samples sorted: sorted
    mean: mean stddev: stddev p5: p5 p50: p50 p95: p95
    pSla: pSla pWin: pWin [ 

    Transcript
        nextPutAll: '========================================';cr;
        nextPutAll: '  Monte Carlo — DroneHandoff Simulation';cr;
        nextPutAll: ('  Runs        : ', nRuns printString);cr;
        nextPutAll: ('  T_available : ', self timeAvailableSeconds printString, ' s');cr;
        nextPutAll: ('  SLA         : ', slaSeconds printString, ' s');cr;
        nextPutAll: '----------------------------------------';cr;
        nextPutAll: '  Mean        : ', (mean   roundTo: 0.01) printString;cr;
        nextPutAll: '  Std dev     : ', (stddev roundTo: 0.01) printString;cr;
        nextPutAll: '  P5          : ', (p5    roundTo: 0.01) printString;cr;
        nextPutAll: '  Median P50  : ', (p50    roundTo: 0.01) printString;cr;
        nextPutAll: '  P95         : ', (p95    roundTo: 0.01) printString;cr;
        nextPutAll: '----------------------------------------';cr;
        nextPutAll: '  P(SLA OK)   : ', (pSla roundTo: 0.01) printString, ' %';cr;
        nextPutAll: '  P(Window OK): ', (pWin roundTo: 0.01) printString, ' %';cr;
        nextPutAll: '========================================'

]

{ #category : 'running' }
DroneHandoffSimulation >> run [ 
    | samples slaOk windowOk sorted mean variance stddev
      p5 p50 p95 pSla pWin n |

    n       := nRuns.
    samples := Array new: n.
    slaOk   := 0.
    windowOk := 0.

    "--- Tirage Monte Carlo ---"
    1 to: n do: [ :i |
        | t |
        t := perception sampleSeconds + action sampleSeconds.
        samples at: i put: t.
        t <= slaSeconds                      ifTrue: [ slaOk    := slaOk    + 1 ].
        t <= self timeAvailableSeconds       ifTrue: [ windowOk := windowOk + 1 ].
    ].

    "--- Statistiques ---"
    sorted   := samples asSortedCollection asArray.
    mean     := (samples inject: 0.0 into: [ :s :x | s + x ]) / n.
    variance := (samples inject: 0.0 into: [ :s :x | s + ((x - mean) squared) ]) / n.
    stddev   := variance sqrt.
    p5       := sorted at: (0.05 * n) ceiling.
    p50      := sorted at: (0.50 * n) ceiling.
    p95      := sorted at: (0.95 * n) ceiling.
    pSla     := slaOk    / n * 100.0.
    pWin     := windowOk / n * 100.0.

    printReport ifTrue: [ self printReport: samples sorted: sorted
        mean: mean stddev: stddev p5: p5 p50: p50 p95: p95
        pSla: pSla pWin: pWin ].

    ^ Dictionary new
        at: #nRuns            put: n;
        at: #mean             put: mean;
        at: #stddev           put: stddev;
        at: #p5               put: p5;
        at: #p50              put: p50;
        at: #p95              put: p95;
        at: #pSlaRespected    put: pSla;
        at: #pWindowRespected put: pWin;
        yourself
]

{ #category : 'validation' }
DroneHandoffSimulation >> slaRespected [ 
    ^ self totalResponseSeconds <= slaSeconds

]

{ #category : 'accessing' }
DroneHandoffSimulation >> slaSeconds [

	^ slaSeconds
]

{ #category : 'accessing' }
DroneHandoffSimulation >> slaSeconds: anObject [

	slaSeconds := anObject
]

{ #category : 'accessing' }
DroneHandoffSimulation >> speedKmh [

	^ speedKmh
]

{ #category : 'accessing' }
DroneHandoffSimulation >> speedKmh: anObject [

	speedKmh := anObject
]

{ #category : 'computing' }
DroneHandoffSimulation >> timeAvailableSeconds [ 
    "Temps avant que le drone atteigne sa cible"
    ^ (distanceKm / speedKmh) * 3600.0

]

{ #category : 'computing' }
DroneHandoffSimulation >> totalResponseSeconds [

	^ perception totalSeconds + action totalSeconds
]

{ #category : 'validation' }
DroneHandoffSimulation >> windowRespected [

	^ self totalResponseSeconds <= self timeAvailableSeconds
]
