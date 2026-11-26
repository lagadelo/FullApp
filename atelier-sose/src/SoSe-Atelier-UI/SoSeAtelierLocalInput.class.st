"
Valeurs locales d’un drone à un tik. Les écarts le long du parcours sont en
mètres et peuvent être absents. Les vitesses de commande sont en mètres par tik.
"
Class {
	#name : 'SoSeAtelierLocalInput',
	#superclass : 'Object',
	#instVars : [ 'gapAhead', 'gapBehind', 'currentSpeed', 'nominalSpeed', 'minSpeed', 'maxSpeed',
		'revisitTargetSeconds', 'secondsPerTick', 'pacingRate', 'sensibility', 'distanceWeight' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierLocalInput class >> of: drone ahead: first behind: second behavior: behavior [
	^ self new initializeOf: drone ahead: first behind: second behavior: behavior
]

{ #category : 'initialization' }
SoSeAtelierLocalInput >> initializeOf: drone ahead: first behind: second behavior: behavior [
	gapAhead := first.
	gapBehind := second.
	currentSpeed := drone currentSpeed.
	nominalSpeed := drone nominalSpeed.
	minSpeed := drone minSpeed.
	maxSpeed := drone maxSpeed.
	revisitTargetSeconds := drone revisitTargetSeconds.
	secondsPerTick := drone secondsPerTick.
	pacingRate := behavior pacingRate.
	sensibility := behavior sensibility
]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> gapAhead [ ^ gapAhead ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> gapBehind [ ^ gapBehind ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> currentSpeed [ ^ currentSpeed ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> nominalSpeed [ ^ nominalSpeed ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> minSpeed [ ^ minSpeed ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> maxSpeed [ ^ maxSpeed ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> revisitTargetSeconds [ ^ revisitTargetSeconds ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> secondsPerTick [ ^ secondsPerTick ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> pacingRate [ ^ pacingRate ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> sensibility [ ^ sensibility ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> distanceWeight [ ^ distanceWeight ifNil: [ 2 ] ]

{ #category : 'accessing' }
SoSeAtelierLocalInput >> distanceWeight: value [ distanceWeight := value ]

{ #category : 'feedback' }
SoSeAtelierLocalInput >> hasBothGaps [
	^ gapAhead notNil and: [ gapBehind notNil ]
]

{ #category : 'feedback' }
SoSeAtelierLocalInput >> relativeGapError [
	| farthest |
	farthest := gapAhead max: gapBehind.
	^ farthest = 0 ifTrue: [ 0.0 ] ifFalse: [ ((gapAhead - gapBehind) / farthest) asFloat ]
]

{ #category : 'feedback' }
SoSeAtelierLocalInput >> balanced [
	^ self relativeGapError abs < sensibility
]

{ #category : 'feedback' }
SoSeAtelierLocalInput >> scaledSpeed: ratio [
	^ ((currentSpeed * ratio roundUpTo: 0.1) min: maxSpeed) max: minSpeed
]

{ #category : 'feedback' }
SoSeAtelierLocalInput >> toward: reference [
	^ currentSpeed + ((reference - currentSpeed) * pacingRate)
]
