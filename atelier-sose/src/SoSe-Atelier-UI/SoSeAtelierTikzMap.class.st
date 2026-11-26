"
Produit des instantanés à insérer avec \\input dans un document qui charge TikZ.
Le temps est exprimé en secondes simulées depuis le tik 0. La sélection
par date exige un tik existant. La géométrie optique utilise le MNT/MNS
et une caméra au nadir.

    figure := SoSeAtelierTikzMap history: simulator history
        tickSeconds: 1 terrain: nil.
    figure writeAtTick: 18 options: { #mode -> #speed } asDictionary
        to: 'tik-18.tex'.
"
Class {
	#name : 'SoSeAtelierTikzMap',
	#superclass : 'Object',
	#instVars : [ 'history', 'tickSeconds', 'replay', 'geometry', 'indexByTick', 'lossTicks' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierTikzMap class >> history: steps tickSeconds: duration terrain: aTerrain [
	^ self new initializeHistory: steps tickSeconds: duration terrain: aTerrain
]

{ #category : 'initialization' }
SoSeAtelierTikzMap >> initializeHistory: steps tickSeconds: duration terrain: aTerrain [
	(steps isEmpty or: [ (steps first range > 0) not ])
		ifTrue: [ self error: 'La figure exige un historique et un circuit de longueur positive.' ].
	(duration isNumber and: [ duration asFloat isFinite and: [ duration > 0 ] ])
		ifFalse: [ self error: 'La durée du tik doit être positive et finie.' ].
	history := steps asArray.
	tickSeconds := duration.
	replay := aTerrain ifNotNil: [ aTerrain newReplay ].
	geometry := SoSeAtelierRenderScene new routeWith: replay firstStep: history first.
	indexByTick := Dictionary new: history size.
	lossTicks := Dictionary new.
	history doWithIndex: [ :step :index |
		(index > 1 and: [ step timeStep <= (history at: index - 1) timeStep ])
			ifTrue: [ self error: 'Les tiks de l’historique doivent être strictement croissants.' ].
		indexByTick at: step timeStep put: index.
		step lostDrones do: [ :drone |
			lossTicks at: drone id ifAbsentPut: [ step timeStep ] ] ]
]

{ #category : 'export' }
SoSeAtelierTikzMap >> writeAtTick: tick options: options to: aFile [
	| file figure |
	figure := self atTick: tick options: options.
	file := aFile asFileReference.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream truncate; nextPutAll: figure ].
	^ file
]

{ #category : 'export' }
SoSeAtelierTikzMap >> writeAtSeconds: date options: options to: aFile [
	^ self writeAtTick: (self tickForSeconds: date) options: options to: aFile
]

{ #category : 'export' }
SoSeAtelierTikzMap >> atSeconds: date options: options [
	^ self atTick: (self tickForSeconds: date) options: options
]

{ #category : 'export' }
SoSeAtelierTikzMap >> atTick: tick options: options [
	| index |
	index := indexByTick at: tick ifAbsent: [
		self error: 'Tik absent de l’historique : ', tick asString ].
	^ (SoSeAtelierTikzMapFigure map: self index: index options: options) asTikz
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> tickForSeconds: date [
	| fractionalTick tick |
	(date isNumber and: [ date asFloat isFinite and: [ date >= 0 ] ])
		ifFalse: [ self error: 'La date simulée doit être positive ou nulle et finie.' ].
	fractionalTick := date / tickSeconds.
	tick := fractionalTick rounded.
	((fractionalTick - tick) abs <= 1.0e-7 and: [ indexByTick includesKey: tick ])
		ifFalse: [ self error: 'La date ne correspond à aucun tik de l’historique : ', date asString, ' s.' ].
	^ tick
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> tickSeconds [
	^ tickSeconds
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> stepAt: index [
	^ history at: index
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> route [
	^ geometry first
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> terrain [
	^ replay ifNotNil: [ replay terrain ]
]

{ #category : 'accessing' }
SoSeAtelierTikzMap >> lossTickOf: aDrone [
	^ lossTicks at: aDrone id
]

{ #category : 'geometry' }
SoSeAtelierTikzMap >> positionOf: drone in: step [
	^ geometry second value: drone value: step
]

{ #category : 'geometry' }
SoSeAtelierTikzMap >> headingOf: drone in: step [
	| ahead movement |
	ahead := drone copy.
	ahead position: (drone position + (step range * 1.0e-7) \\ step range).
	movement := (self positionOf: ahead in: step) - (self positionOf: drone in: step).
	movement = (0 @ 0) ifTrue: [ ^ 0 ].
	^ (movement y arcTan: movement x) radiansToDegrees
]

{ #category : 'observations' }
SoSeAtelierTikzMap >> accelerationOf: drone at: index [
	| previous previousDrone deltaT |
	index = 1 ifTrue: [ ^ nil ].
	previous := self stepAt: index - 1.
	previousDrone := previous drones detect: [ :each | each id = drone id ] ifNone: [ ^ nil ].
	deltaT := ((self stepAt: index) timeStep - previous timeStep) * tickSeconds.
	^ (drone currentSpeed - previousDrone currentSpeed) / tickSeconds / deltaT
]

{ #category : 'observations' }
SoSeAtelierTikzMap >> trailOf: drone at: index lastTicks: duration [
	| limit positions state previous |
	limit := (self stepAt: index) timeStep - duration.
	positions := OrderedCollection new.
	index to: 1 by: -1 do: [ :previousIndex |
		state := self stepAt: previousIndex.
		state timeStep < limit ifTrue: [ ^ positions ].
		previous := state drones detect: [ :each | each id = drone id ] ifNone: [ ^ positions ].
		positions addFirst: (self positionOf: previous in: state) ].
	^ positions
]
