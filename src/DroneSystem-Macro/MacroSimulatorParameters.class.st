"
has 6 instance variables as:
	- totalDistance : the span of the mission
	- numberOfDrones : an integer defining the number of drones at first  
	- minSpeed, maxSpeed and nominalSpeed  for drones. We assume the drones share the same internal cgaracteristics
	- captureRadius : this describes the zone under investigation. It is used at runtime to detect gaps into the border's coverage
	- sensingRadius ; this describes the distance allowing to perceive other drones (i.e one drone further than sensingRadius is reported missing
	
is intented to initialize the MacroSimulator
"
Class {
	#name : 'MacroSimulatorParameters',
	#superclass : 'Object',
	#instVars : [
		'nominalSpeed',
		'maxSpeed',
		'minSpeed',
		'sensingRadius',
		'captureRadius',
		'numberOfDrones',
		'totalDistance',
		'initialGap',
		'wayPoints',
		'policy',
		'seed',
		'interWayPointsDistances',
		'wayPointsPositions'
	],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'facilities' }
MacroSimulatorParameters class >> balancedRouteFrom: orderedWayPoints [
	"Defaut values"

	"Middle policy between convex hull and full route.
    Keep a point if far enough from last kept OR if heading changes enough."

	^ self
		  balancedRouteFrom: orderedWayPoints
		  minSpacingKm: 60
		  turnThresholdDeg: 65
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> balancedRouteFrom: ordered minSpacingKm: minSpacingKm turnThresholdDeg: turnThresholdDeg [
	"Keep a point if:
     1) it is far enough from last kept point, OR
     2) it creates a significant turn.
    ordered is expected to be an OrderedCollection/Array of lon@lat Points."

	| kept |
	ordered size <= 3 ifTrue: [ ^ ordered ].

	kept := OrderedCollection new.
	kept add: ordered first.

	2 to: ordered size - 1 do: [ :i |
			| prevKept current next distKm turnDeg |
			prevKept := kept last.
			current := ordered at: i.
			next := ordered at: i + 1.

			distKm := (self haversineMetersFrom: prevKept to: current) / 1000.0.
			turnDeg := self turnAngleDegreesAt: current from: prevKept to: next.

			(distKm >= minSpacingKm and: [ turnDeg >= turnThresholdDeg ])
				ifTrue: [ kept add: current ] ].

	kept add: ordered last.
	^ kept asArray
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> compactedRouteFrom: ordered compactingFactor: compactingFactor [
    | n target keepCount scores ranked keepIndices |
    n := ordered size.
    n <= 2 ifTrue: [ ^ ordered ].

    target := ((n * compactingFactor) rounded max: 2) min: n.
    keepCount := target - 2.

    scores := OrderedCollection new.
    2 to: n - 1 do: [ :i |
        | prev current next turnDeg distKm score |
        prev    := ordered at: i - 1.
        current := ordered at: i.
        next    := ordered at: i + 1.

        turnDeg := self turnAngleDegreesAt: current from: prev to: next.
        distKm  := (((self haversineMetersFrom: prev to: current))
                 + ((self haversineMetersFrom: current to: next))) / 2000.0.

        score := (turnDeg * 0.7) + (distKm * 0.3).
        scores add: (Array with: i with: score) ].

    "Tri déterministe : départage par index si scores égaux"
    ranked := scores asSortedCollection: [ :a :b |
        a second = b second
            ifTrue: [ a first < b first ]
            ifFalse: [ a second > b second ] ].

    keepIndices := SortedCollection sortBlock: [ :a :b | a < b ].
    keepIndices add: 1.
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> compactedRouteFrom: ordered compactingFactor: compactingFactor mandatory: mandatory [
    "mandatory: collection de GeoPoints à garder absolument."

    | n target keepCount scores ranked keepIndices mandatoryIdx |

    n := ordered size.
    n <= 2 ifTrue: [ ^ ordered ].

    "Indices des points obligatoires"
    mandatoryIdx := mandatory collect: [ :m | ordered indexOf: m ].

    target := ((n * compactingFactor) rounded max: 2) min: n.
    keepCount := target - 2 - mandatoryIdx size. "on réserve les slots"

    scores := OrderedCollection new.
    2 to: n - 1 do: [ :i |
        (mandatoryIdx includes: i) ifFalse: [
            | prev current next turnDeg distKm score |
            prev    := ordered at: i - 1.
            current := ordered at: i.
            next    := ordered at: i + 1.
            turnDeg := self turnAngleDegreesAt: current from: prev to: next.
            distKm  := ((self haversineMetersFrom: prev to: current)
                     +  (self haversineMetersFrom: current to: next)) / 2000.0.
            score := (turnDeg * 0.7) + (distKm * 0.3).
            scores add: (Array with: i with: score) ] ].

    ranked := scores asSortedCollection: [ :a :b |
        a second = b second
            ifTrue:  [ a first < b first ]
            ifFalse: [ a second > b second ] ].

    keepIndices := SortedCollection sortBlock: [ :a :b | a < b ].
    keepIndices add: 1.
    keepIndices add: n.
    mandatoryIdx do: [ :i | keepIndices add: i ].
    1 to: (keepCount max: 0) min: ranked size do: [ :k |
        keepIndices add: (ranked at: k) first ].

    ^ keepIndices collect: [ :idx | ordered at: idx ]
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> compactedRouteFrom: ordered compactingFactorLegacy: compactingFactor [
	"compactingFactor in [0..1]. Example: 0.5 keeps ~50%."

	| n target keepCount scores ranked keepIndices |
	n := ordered size.
	n <= 2 ifTrue: [ ^ ordered ].

	target := ((n * compactingFactor) rounded max: 2) min: n.
	keepCount := target - 2. "first+last are always kept"

	scores := OrderedCollection new.
	2 to: n - 1 do: [ :i |
			| prev current next turnDeg distKm score |
			prev := ordered at: i - 1.
			current := ordered at: i.
			next := ordered at: i + 1.

			turnDeg := self turnAngleDegreesAt: current from: prev to: next.
			distKm := (self haversineMetersFrom: prev to: current)
			          + (self haversineMetersFrom: current to: next) / 2000.0.

			score := turnDeg * 0.7 + (distKm * 0.3).
			scores add: (Array with: i with: score) ].

	ranked := scores asSortedCollection: [ :a :b | a second > b second ].

	keepIndices := SortedCollection sortBlock: [ :a :b | a < b ].
	keepIndices add: 1.
	keepIndices add: n.

	1 to: (keepCount min: ranked size) do: [ :k |
	keepIndices add: (ranked at: k) first ].

	^ keepIndices collect: [ :idx | ordered at: idx ]
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> compactedRouteFrom: ordered to: aValue [
	"compactingFactor in [0..1]. Example: 0.5 keeps ~50%."

	^self
		compactedRouteFrom: ordered
		compactingFactor: (aValue / ordered size roundTo: 0.1)
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points [
    | sorted cross lower upper hull |
    sorted := points asSortedCollection: [ :a :b |
        (a longitude) ~= (b longitude)
            ifTrue: [ (a longitude) < (b longitude) ]
            ifFalse: [ (a latitude) < (b latitude) ] ].

    cross := [ :o :a :b |
        (((a longitude) - (o longitude)) * ((b latitude) - (o latitude)))
            - (((a latitude) - (o latitude)) * ((b longitude) - (o longitude))) ].

    lower := OrderedCollection new.
    sorted do: [ :point |
        [ lower size >= 2 and: [
            (cross value: (lower at: lower size - 1) value: (lower at: lower size) value: point) <= 0 ] ]
            whileTrue: [ lower removeLast ].
        lower add: point ].

    upper := OrderedCollection new.
    sorted reverseDo: [ :point |
        [ upper size >= 2 and: [
            (cross value: (upper at: upper size - 1) value: (upper at: upper size) value: point) <= 0 ] ]
            whileTrue: [ upper removeLast ].
        upper add: point ].

    hull := lower , (upper copyFrom: 2 to: (upper size - 1 max: 1)).

    ^ hull collect: [ :p |
        GeoPoint  latitude: ((p latitude) truncateTo: 0.001) longitude:((p longitude) truncateTo: 0.001) altitude: p altitude]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points epsilon: epsilon [
    "epsilon=0 → hull strict. epsilon>0 → hull relâché (garde plus de points).
     epsilon est en degrés² (produit vectoriel lon/lat).
     Typiquement: 0=strict, 0.0001=léger, 0.001=relâché, 0.01=très relâché."

    | sorted cross lower upper seen result |
    sorted := points asSortedCollection: [ :a :b |
        a longitude ~= b longitude
            ifTrue: [ a longitude < b longitude ]
            ifFalse: [ a latitude < b latitude ] ].

    cross := [ :o :a :b |
        ((a longitude - o longitude) * (b latitude - o latitude))
        - ((a latitude - o latitude) * (b longitude - o longitude)) ].

    lower := OrderedCollection new.
    sorted do: [ :point |
        [ lower size >= 2 and: [
            (cross
                value: (lower at: lower size - 1)
                value: lower last
                value: point) <= epsilon negated ] ]
            whileTrue: [ lower removeLast ].
        lower add: point ].

    upper := OrderedCollection new.
    sorted reverseDo: [ :point |
        [ upper size >= 2 and: [
            (cross
                value: (upper at: upper size - 1)
                value: upper last
                value: point) <= epsilon negated ] ]
            whileTrue: [ upper removeLast ].
        upper add: point ].

    upper removeFirst.
    upper removeLast.

    seen := Set new.
    result := OrderedCollection new.
    (lower , upper) do: [ :p |
        | key |
        key := p longitude @ p latitude.
        (seen includes: key) ifFalse: [
            seen add: key.
            result add: p ] ].

    ^ result collect: [ :p |
        GeoPoint
            latitude: (p latitude truncateTo: 0.001)
            longitude: (p longitude truncateTo: 0.001)
            altitude: p altitude ]
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points ratio: aRatio [

self assert: aRatio >1. 
	^ self
		  convexHullRouteFromRawPoints: points
		  targetCount: aRatio * (self convexHullRouteFromRawPoints: points) size
]

{ #category : 'as yet unclassified' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points ratio: ratio maxSpikeAngle: maxSpikeAngle [
    "ratio: multiplicateur du hull strict. Ex: 1.0=hull strict, 2.5=2.5x plus de points."
    
    | strictCount targetCount |
    strictCount := (self convexHullRouteFromRawPoints: points epsilon: 0) size.
    targetCount := (strictCount * ratio) rounded.
    
    ^ self 
        convexHullRouteFromRawPoints: points 
        targetCount: targetCount 
        maxSpikeAngle: maxSpikeAngle
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points targetCount: targetCount [
	"Trouve epsilon par recherche binaire pour obtenir approximativement targetCount points."

	| low high mid result |
	"Hull strict = minimum de points"
	(self convexHullRouteFromRawPoints: points epsilon: 0) size
	>= targetCount ifTrue: [
		^ self convexHullRouteFromRawPoints: points epsilon: 0 ].

	low := 0.0.
	high := 1.0.

	20 timesRepeat: [
			mid := low + high / 2.0.
			result := self convexHullRouteFromRawPoints: points epsilon: mid.
			result size = targetCount ifTrue: [ ^ result ].
			result size > targetCount
				ifTrue: [ high := mid ]
				ifFalse: [ low := mid ] ].

	^ self convexHullRouteFromRawPoints: points epsilon: mid
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> convexHullRouteFromRawPoints: points targetCount: targetCount maxSpikeAngle: maxSpikeAngle [

	| hull toRemove result |
	hull := (self
		         convexHullRouteFromRawPoints: points
		         targetCount: targetCount) asOrderedCollection.

	[
		toRemove := OrderedCollection new.
		2 to: hull size - 1 do: [ :i |
				| turn |
				turn := self
					        turnAngleDegreesAt: (hull at: i)
					        from: (hull at: i - 1)
					        to: (hull at: i + 1).
				turn > maxSpikeAngle ifTrue: [ toRemove add: i ] ].

		result := OrderedCollection new.
		hull keysAndValuesDo: [ :i :p |
			(toRemove includes: i) ifFalse: [ result add: p ] ].
		hull := result.
		toRemove notEmpty ] whileTrue.

	^ result
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> convexHullRouteFromRawPointsLegacy: points [
    | sorted cross lower upper hull |
    sorted := points asSortedCollection: [ :a :b |
        (a longitude) ~= (b longitude)
            ifTrue: [ (a longitude) < (b longitude) ]
            ifFalse: [ (a latitude) < (b latitude) ] ].

    cross := [ :o :a :b |
        (((a longitude) - (o longitude)) * ((b latitude) - (o latitude)))
            - (((a latitude) - (o latitude)) * ((b longitude) - (o longitude))) ].

    lower := OrderedCollection new.
    sorted do: [ :point |
        [ lower size >= 2 and: [
            (cross value: (lower at: lower size - 1) value: (lower at: lower size) value: point) <= 0 ] ]
            whileTrue: [ lower removeLast ].
        lower add: point ].

    upper := OrderedCollection new.
    sorted reverseDo: [ :point |
        [ upper size >= 2 and: [
            (cross value: (upper at: upper size - 1) value: (upper at: upper size) value: point) <= 0 ] ]
            whileTrue: [ upper removeLast ].
        upper add: point ].

    hull := lower , (upper copyFrom: 2 to: (upper size - 1 max: 1)).

    ^ hull collect: [ :p |
        GeoPoint  latitude: ((p latitude) truncateTo: 0.001) longitude:((p longitude) truncateTo: 0.001) altitude: p altitude]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example1 [
	"easy, *2 redundancy"

	"+50% max speed, non speed under nominal"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 20;
		captureRadius: 20;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example2 [
	"medium, *1,5 redundancy"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 15;
		captureRadius: 20;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example3 [
	"medium, *1,5 redundancy, *2 neighbours detection"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 100;
		nominalSpeed: 10;
		minSpeed: 10;
		maxSpeed: 15;
		sensingRadius: 20;
		captureRadius: 15;
		totalDistance: 10000.
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> example4 [
	"Assuming 2500-3000 km, the number of drones is computed with regardes to sensing radis (inter drone visibility)"

	| tmp |
	tmp := self new.
	tmp
		numberOfDrones: 450;
		"We assume the simulation step will be one minute"
		nominalSpeed: 130000/60;
		minSpeed: 60000/60;
		maxSpeed: 220000/60;
		sensingRadius: 3;
		captureRadius: 8;
	 wayPoints: (self exampleWaypoints2: tmp seed ).
	^ tmp
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleDrones [
	"Generate 100 drones over Brittany organized as convex hull"

	| randomGenerator points sorted cross lower upper hull centroidLat centroidLng drones |
	randomGenerator := Random new.

	"Brittany coordinates: ~47.5-48.5°N, ~-4.5 to -1.5°W (or 355.5-358.5°E)"


	"Generate 100 random points over Brittany"
	points := (1 to: 100) collect: [ :i |
			          Dictionary new
				          at: #lat put: 47.5 + (randomGenerator next * 1.0);
				          at: #lng put: -4.5 + (randomGenerator next * 3.0);
				          at: #alt put: randomGenerator next + 1 * 200;
				          yourself ].

	"Compute convex hull using Andrew's monotone chain algorithm"
	sorted := points sort: [ :a :b |
			          (a at: #lng) ~= (b at: #lng)
				          ifTrue: [ (a at: #lng) < (b at: #lng) ]
				          ifFalse: [ (a at: #lat) < (b at: #lat) ] ].

	cross := [ :o :a :b |
		         (a at: #lng) - (o at: #lng) * ((b at: #lat) - (o at: #lat))
		         - ((a at: #lat) - (o at: #lat))
		         * ((b at: #lng) - (o at: #lng)) ].

	"Lower hull"
	lower := OrderedCollection new.
	sorted do: [ :point |
			[
				lower size >= 2 and: [
						(cross
							 value: (lower at: lower size - 1)
							 value: (lower at: lower size)
							 value: point) <= 0 ] ] whileTrue: [ lower removeLast ].
			lower add: point ].

	"Upper hull"
	upper := OrderedCollection new.
	sorted reverse do: [ :point |
			[
				upper size >= 2 and: [
						(cross
							 value: (upper at: upper size - 1)
							 value: (upper at: upper size)
							 value: point) <= 0 ] ] whileTrue: [ upper removeLast ].
			upper add: point ].

	hull := lower , (upper allButFirst: 1) allButLast: 1.

	"Sort all points by angle from centroid for radial ordering"
	centroidLat := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lat) ])
	               / points size.
	centroidLng := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lng) ])
	               / points size.

	points := points sort: [ :a :b |
			          | angleA angleB |
			          angleA := (a at: #lat) - centroidLat arcTan:
				                    (a at: #lng) - centroidLng.
			          angleB := (b at: #lat) - centroidLat arcTan:
				                    (b at: #lng) - centroidLng.
			          angleA < angleB ].

	"Format as array of strings: { lat.lng.alt }"
	^ drones := points collect: [ :p |
			            | lat lng alt |
			            lat := (p at: #lat) truncateTo: 0.001.
			            lng := (p at: #lng) truncateTo: 0.001.
			            alt := (p at: #alt) truncateTo: 1.
			            Array with: lat with: lng with: alt ]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleDrones2 [
	"Generate 100 drones over Brittany organized as convex hull"

	| randomGenerator points sorted cross lower upper hull centroidLat centroidLng drones |
	randomGenerator := Random new.

	"Brittany coordinates: ~47.5-48.5°N, ~-4.5 to -1.5°W (or 355.5-358.5°E)"


	"Generate 100 random points over Brittany"
	points := (1 to: 100) collect: [ :i |
			          Dictionary new
				          at: #lat put: 47.5 + (randomGenerator next * 1.0);
				          at: #lng put: -4.5 + (randomGenerator next * 3.0);
				          at: #alt put: randomGenerator next + 1 * 200;
				          yourself ].

	"Compute convex hull using Andrew's monotone chain algorithm"
	sorted := points sort: [ :a :b |
			          (a at: #lng) ~= (b at: #lng)
				          ifTrue: [ (a at: #lng) < (b at: #lng) ]
				          ifFalse: [ (a at: #lat) < (b at: #lat) ] ].

	cross := [ :o :a :b |
		         (a at: #lng) - (o at: #lng) * ((b at: #lat) - (o at: #lat))
		         - ((a at: #lat) - (o at: #lat))
		         * ((b at: #lng) - (o at: #lng)) ].

	"Lower hull"
	lower := OrderedCollection new.
	sorted do: [ :point |
			[
				lower size >= 2 and: [
						(cross
							 value: (lower at: lower size - 1)
							 value: (lower at: lower size)
							 value: point) <= 0 ] ] whileTrue: [ lower removeLast ].
			lower add: point ].

	"Upper hull"
	upper := OrderedCollection new.
	sorted reverse do: [ :point |
			[
				upper size >= 2 and: [
						(cross
							 value: (upper at: upper size - 1)
							 value: (upper at: upper size)
							 value: point) <= 0 ] ] whileTrue: [ upper removeLast ].
			upper add: point ].

	hull := lower , (upper allButFirst: 1) allButLast: 1.

"We can switch to hull instead"
"^  hull collect: [ :p |
    ((p at: #lng) truncateTo: 0.001) @ ((p at: #lat) truncateTo: 0.001) ]"

	"Sort all points by angle from centroid for radial ordering"
	centroidLat := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lat) ])
	               / points size.
	centroidLng := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lng) ])
	               / points size.

	points := points sort: [ :a :b |
			          | angleA angleB |
			          angleA := (a at: #lat) - centroidLat arcTan:
				                    (a at: #lng) - centroidLng.
			          angleB := (b at: #lat) - centroidLat arcTan:
				                    (b at: #lng) - centroidLng.
			          angleA < angleB ].
 
	^ drones := points collect: [ :p |
		           ( (p at: #lng) truncateTo:
			            0.001) @ ((p at: #lat) truncateTo: 0.001) ]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleDrones2: aSeed [
	"Generate 100 drones over Brittany organized as convex hull"

	| randomGenerator points sorted cross lower upper hull centroidLat centroidLng drones |
	randomGenerator := Random new seed:   aSeed .

	"Brittany coordinates: ~47.5-48.5°N, ~-4.5 to -1.5°W (or 355.5-358.5°E)"


	"Generate 100 random points over Brittany"
	points := (1 to: 100) collect: [ :i |
			          Dictionary new
				          at: #lat put: 47.5 + (randomGenerator next * 1.0);
				          at: #lng put: -4.5 + (randomGenerator next * 3.0);
				          at: #alt put: randomGenerator next + 1 * 200;
				          yourself ].

	"Compute convex hull using Andrew's monotone chain algorithm"
	sorted := points sort: [ :a :b |
			          (a at: #lng) ~= (b at: #lng)
				          ifTrue: [ (a at: #lng) < (b at: #lng) ]
				          ifFalse: [ (a at: #lat) < (b at: #lat) ] ].

	cross := [ :o :a :b |
		         (a at: #lng) - (o at: #lng) * ((b at: #lat) - (o at: #lat))
		         - ((a at: #lat) - (o at: #lat))
		         * ((b at: #lng) - (o at: #lng)) ].

	"Lower hull"
	lower := OrderedCollection new.
	sorted do: [ :point |
			[
				lower size >= 2 and: [
						(cross
							 value: (lower at: lower size - 1)
							 value: (lower at: lower size)
							 value: point) <= 0 ] ] whileTrue: [ lower removeLast ].
			lower add: point ].

	"Upper hull"
	upper := OrderedCollection new.
	sorted reverse do: [ :point |
			[
				upper size >= 2 and: [
						(cross
							 value: (upper at: upper size - 1)
							 value: (upper at: upper size)
							 value: point) <= 0 ] ] whileTrue: [ upper removeLast ].
			upper add: point ].

	hull := lower , (upper allButFirst: 1) allButLast: 1.

"We can switch to hull instead"
"^  hull collect: [ :p |
    ((p at: #lng) truncateTo: 0.001) @ ((p at: #lat) truncateTo: 0.001) ]"

	"Sort all points by angle from centroid for radial ordering"
	centroidLat := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lat) ])
	               / points size.
	centroidLng := (points
		                inject: 0
		                into: [ :sum :p | sum + (p at: #lng) ])
	               / points size.

	points := points sort: [ :a :b |
			          | angleA angleB |
			          angleA := (a at: #lat) - centroidLat arcTan:
				                    (a at: #lng) - centroidLng.
			          angleB := (b at: #lat) - centroidLat arcTan:
				                    (b at: #lng) - centroidLng.
			          angleA < angleB ].
 
	^ drones := points collect: [ :p |
		           ( (p at: #lng) truncateTo:
			            0.001) @ ((p at: #lat) truncateTo: 0.001) ]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleWayPointsPolicy: aSymbol [
    "Policies: #convexHull #balanced #fullRoute"
    | points orderedPoints hullPoints wayPoints |
    points := self generateRawBrittanyPoints: 100.
    orderedPoints := self orderedRouteFromRawPoints: points.
    hullPoints := self convexHullRouteFromRawPoints: points.

    wayPoints := aSymbol caseOf: {
        [#convexHull] -> [ hullPoints ].
        [#balanced]   -> [ self balancedRouteFrom: orderedPoints ].
        [#fullRoute]  -> [ orderedPoints ] }
        otherwise: [ self error: 'Unknown policy' ].

    ^ wayPoints
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleWaypoints2 [
	"Now returns only 30 points out of the initial 100"

	^ self
		  compactedRouteFrom:
		  (self orderedRouteFromRawPoints:
			   (self generateRawBrittanyPoints: 100))
		  to: 30 
]

{ #category : 'examples' }
MacroSimulatorParameters class >> exampleWaypoints2: aSeed [
	"Now returns only 30 points out of the initial 100"

	^ self
		  compactedRouteFrom:
		  (self orderedRouteFromRawPoints:
			   (self generateRawBrittanyPoints: 100 seed: aSeed))
		  to: 30 
]

{ #category : 'examples' }
MacroSimulatorParameters class >> generateRawBrittanyPoints: n [

	| randomGenerator |
	randomGenerator := Random new.
	randomGenerator seed: 1000000.
	^ (1 to: n) collect: [ :i |
			  GeoPoint
				  latitude: 47.5 + (randomGenerator next * 1.0)
				  longitude: -4.5 + (randomGenerator next * 3.0)
				  altitude: randomGenerator next + 1 * 200 ]
]

{ #category : 'examples' }
MacroSimulatorParameters class >> generateRawBrittanyPoints: n seed: aSeed [
    | randomGenerator |
    randomGenerator := Random new seed: aSeed.
    ^ (1 to: n) collect: [ :i |
        Dictionary new
            at: #lat put: (47.5 + (randomGenerator next * 1.0));
            at: #lng put: (-4.5 + (randomGenerator next * 3.0));
            at:  #alt put: randomGenerator next + 1 * 200;
            yourself ]
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> haversineMetersFrom: p1 to: p2 [
    | r lat1 lat2 dLat dLon a c |
    r := 6378137.0.
    lat1 := p1 latitude degreesToRadians.
    lat2 := p2 latitude degreesToRadians.
    dLat := (p2 latitude- p1 latitude) degreesToRadians.
    dLon := (p2 longitude - p1 longitude) degreesToRadians.
    a := ((dLat / 2) sin squared)
        + ((lat1 cos) * (lat2 cos) * ((dLon / 2) sin squared)).
    c := 2 * ((a sqrt) arcTan: (1 - a) sqrt).
    ^ r * c
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> orderedRouteFromRawPoints: points [
	" | centroidLat centroidLng sorted |
    centroidLat := (points inject: 0.0 into: [ :sum :p | sum + (p at: #lat) ]) / points size.
    centroidLng := (points inject: 0.0 into: [ :sum :p | sum + (p at: #lng) ]) / points size.

    sorted := points asSortedCollection: [ :a :b |
        | angleA angleB |
        angleA := ((a at: #lat) - centroidLat) arcTan: ((a at: #lng) - centroidLng).
        angleB := ((b at: #lat) - centroidLat) arcTan: ((b at: #lng) - centroidLng).
        angleA < angleB ].

    ^ sorted collect: [ :p |
        ((p at: #lng) truncateTo: 0.001) @ ((p at: #lat) truncateTo: 0.001) ]"

	| centroidLat centroidLng sorted |
	centroidLat := (points
		                inject: 0.0
		                into: [ :sum :p | sum + p latitude ]) / points size.
	centroidLng := (points
		                inject: 0.0
		                into: [ :sum :p | sum + p longitude ]) / points size.

	sorted := points asSortedCollection: [ :a :b |
			          | angleA angleB |
			          angleA := a latitude - centroidLat arcTan:
				                    a longitude - centroidLng.
			          angleB := b latitude - centroidLat arcTan:
				                    b longitude - centroidLng.
			          angleA < angleB ].

	^ sorted collect: [ :p |
			  GeoPoint
				  latitude: (p latitude truncateTo: 0.001)
				  longitude: (p longitude truncateTo: 0.001)
				  altitude: p altitude ]
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> simulatorAutonomyFreeNotes [
    "Autonomy-free MVP (no battery/maintenance/crew constraints).

    Inputs:
    - routeKm: total patrol route length (example: 2623)
    - speedNominalKmh: nominal drone speed (example: 130)
    - revisitTargetHours: max delay between two observations of same area (patrol mode)
    - detectionSwathKm: effective covered width along line (static coverage mode)
    - availabilityFactor: later realism multiplier (default 1.0 now; later 3.0..4.0)

    Modes:

    1) Static line coverage (instant full-line coverage)
       activeDrones = ceil(routeKm / detectionSwathKm)

    2) Patrol/revisit coverage (usually more realistic)
       loopTimeHours = routeKm / speedNominalKmh
       activeDrones = ceil(loopTimeHours / revisitTargetHours)

    Autonomy-free:
       fleetSize = activeDrones

    With realism later:
       fleetSize = ceil(activeDrones * availabilityFactor)

    Example with routeKm=2623 and speed=130:
    - loopTimeHours ~= 20.2 h
    - revisit 2h  => activeDrones = 11
    - revisit 1h  => activeDrones = 21
    - revisit 0.5h => activeDrones = 41"
    ^ self
]

{ #category : 'facilities' }
MacroSimulatorParameters class >> turnAngleDegreesAt: p2 from: p1 to: p3 [
    | v1x v1y v2x v2y dot n1 n2 cosTheta |
    v1x := p2 longitude - p1 longitude.
    v1y := p2 latitude - p1 latitude.
    v2x := p3 longitude - p2 longitude.
    v2y := p3 latitude - p2 latitude.

    n1 := ((v1x * v1x) + (v1y * v1y)) sqrt.
    n2 := ((v2x * v2x) + (v2y * v2y)) sqrt.
    (n1 = 0 or: [ n2 = 0 ]) ifTrue: [ ^ 0.0 ].

    dot := (v1x * v2x) + (v1y * v2y).
    cosTheta := ((dot / (n1 * n2)) max: -1.0) min: 1.0.
    ^ (cosTheta arcCos) radiansToDegrees
]

{ #category : 'examples' }
MacroSimulatorParameters class >> useExample [
 

self exampleWayPointsPolicy: #convexHull.
"self computeTotalDistanceFromWayPoints."

self exampleWayPointsPolicy: #balanced.
"self computeTotalDistanceFromWayPoints."

self exampleWayPointsPolicy: #fullRoute.
"self computeTotalDistanceFromWayPoints." 
 

]

{ #category : 'examples' }
MacroSimulatorParameters class >> useExample2 [

	| raw ordered balanced50 balanced60 balanced30 |
	raw := self generateRawBrittanyPoints: 100.
	ordered := self orderedRouteFromRawPoints: raw.

	balanced50 := self compactedRouteFrom: ordered compactingFactor: 0.5.
	balanced60 := self compactedRouteFrom: ordered compactingFactor: 0.6.
	balanced30 := self compactedRouteFrom: ordered to: 30
]

{ #category : 'visiting' }
MacroSimulatorParameters >> accept: aVisitor [

	^ aVisitor visitMacroSimulatorParameters: self
]

{ #category : 'accessing' }
MacroSimulatorParameters >> captureRadius [

	^ captureRadius
]

{ #category : 'accessing' }
MacroSimulatorParameters >> captureRadius: anObject [

	captureRadius := anObject
]

{ #category : 'computing - waypoints' }
MacroSimulatorParameters >> computeInterWayPointsDistances [

	| td tmp result d |
	td := 0.0.
	"Consider wayPoints"
	tmp := wayPoints copy asOrderedCollection.
	"Close the loop; first is seen as last's succesor"
	tmp add: wayPoints first.
	"Compute inter wayPoints distance"
	result := (1 to: wayPoints size ) collect: [ :i |
		         ( self haversineMetersFrom: (tmp at: i) to: (tmp at: (i % wayPoints size )+ 1))/1000 "use kilometers as unit" ].


	^ result
]

{ #category : 'computing - waypoints' }
MacroSimulatorParameters >> computeTotalDistanceFromWayPoints [

	^ totalDistance := self interWayPointsDistances
		                   inject: 0
		                   into: [ :a :b | a + b ]
]

{ #category : 'computing - waypoints' }
MacroSimulatorParameters >> computeWayPointsPositions [

	| d |
	d := 0. 
	^ self computeInterWayPointsDistances asOrderedCollection
		  removeLast;
		  addFirst: 0;
		  collect: [ :interWayPointDistance |
			  d := d + interWayPointDistance ]
]

{ #category : 'simulator  generation' }
MacroSimulatorParameters >> generate [
	"Generate a collection of drones "

	"^ (1 to: self numberOfDrones) collect: [ :i |
			  | tmp |
			  tmp := self generateDrone.
			  tmp id: i - 1.
			  tmp position: self numberOfDrones - i * self initialGap ]"
		
	
	^ (1 to: self numberOfDrones) collect: [ :i |
			  | tmp |
			  tmp := self generateDrone.
			  tmp id: i - 1.
			  tmp position: self numberOfDrones - i * self initialGap ]
]

{ #category : 'simulator  generation' }
MacroSimulatorParameters >> generateDrone [
	"Generate a drone with no meaning id nor position"

	| tmp |
	tmp := MacroSimulatorDrone new.
	tmp id: Float infinity.
	tmp nominalSpeed: self nominalSpeed.
	tmp maxSpeed: self maxSpeed.
	tmp minSpeed: self minSpeed.
	tmp currentSpeed: self nominalSpeed.
	tmp sensingRadius: self sensingRadius.
	tmp captureRadius: self captureRadius.
	tmp position: Float infinity.
	^ tmp
]

{ #category : 'accessing' }
MacroSimulatorParameters >> haversineMetersFrom: p1 to: p2 [

	^ self class haversineMetersFrom: p1 to: p2
]

{ #category : 'accessing' }
MacroSimulatorParameters >> initialGap [

	initialGap ifNil: [ "Assume homogeneous dispatch omong the perimeter"
		self initialGap: self totalDistance / self numberOfDrones ].
	^ initialGap
]

{ #category : 'accessing' }
MacroSimulatorParameters >> initialGap: anObject [

	initialGap := anObject
]

{ #category : 'simulator  generation' }
MacroSimulatorParameters >> initializeSimulator [

	^ MacroSimulator new startWith: self
]

{ #category : 'accessing' }
MacroSimulatorParameters >> interWayPointsDistances [

	interWayPointsDistances ifNil: [ interWayPointsDistances := self computeInterWayPointsDistances ].
	^ interWayPointsDistances
]

{ #category : 'accessing' }
MacroSimulatorParameters >> maxSpeed [

	maxSpeed ifNil: [ maxSpeed := self nominalSpeed ].

	^ maxSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> maxSpeed: anObject [

	maxSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> minSpeed [

	^ minSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> minSpeed: anObject [

	minSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> nominalSpeed [

	"This is the minimal viable information, as min and max values can be derived from on demand"

	^ nominalSpeed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> nominalSpeed: anObject [

	nominalSpeed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> numberOfDrones [

	^ numberOfDrones
]

{ #category : 'accessing' }
MacroSimulatorParameters >> numberOfDrones: anObject [

	numberOfDrones := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> policy [

	policy ifNil: [ self policy: #default ].
	^ policy
]

{ #category : 'accessing' }
MacroSimulatorParameters >> policy: anObject [

	policy := anObject
]

{ #category : 'computing - waypoints' }
MacroSimulatorParameters >> realPositionFrom: aPosition [

	| relativePosition predecessor ratio |
	"current turn position"
	relativePosition := aPosition \\ self totalDistance.
	"previous wayPoint"
	predecessor := (self wayPointsPositions size to: 1 by: -1) detect: [
		               :a |
		               (self wayPointsPositions at: a) < relativePosition ].
	"Ofset"
	ratio := relativePosition - (self wayPointsPositions at: predecessor)
	         / (self interWayPointsDistances at: predecessor).
	" Current Position is previous waypoint  + offset"
	^ (self wayPoints at: predecessor)
	  +
		  (ratio
		   * ((self wayPoints at: predecessor \\ self wayPoints size + 1)
			    - self wayPoints at: predecessor))
]

{ #category : 'accessing' }
MacroSimulatorParameters >> seed [
	"Usefull for exact replay"

	seed ifNil: [ seed := Time primUTCMillisecondsClock ].
	^ seed
]

{ #category : 'accessing' }
MacroSimulatorParameters >> seed: anObject [

	seed := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> sensingRadius [

	^ sensingRadius
]

{ #category : 'accessing' }
MacroSimulatorParameters >> sensingRadius: anObject [

	sensingRadius := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> totalDistance [

	^ totalDistance
]

{ #category : 'accessing' }
MacroSimulatorParameters >> totalDistance: anObject [

	totalDistance := anObject
]

{ #category : 'accessing' }
MacroSimulatorParameters >> wayPoints [

	^ wayPoints
]

{ #category : 'accessing' }
MacroSimulatorParameters >> wayPoints: anArray [

	 
	wayPoints := anArray.
	self computeTotalDistanceFromWayPoints
]

{ #category : 'accessing' }
MacroSimulatorParameters >> wayPointsPositions [

	| d |
	wayPointsPositions ifNil: [
			d := 0.
			wayPointsPositions := self computeWayPointsPositions ].
	^ wayPointsPositions
]

{ #category : 'accessing' }
MacroSimulatorParameters >> wayPointsPositions: aValue [

	wayPointsPositions := aValue
]
