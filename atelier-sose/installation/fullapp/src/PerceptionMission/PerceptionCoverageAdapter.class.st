"
Fusionne les relevés des drones et conserve la date de dernière observation par cellule. Une cellule masquée pour une caméra et relevée par une autre au même pas sort du masque affiché. fadeOutDuration: fixe la durée d’effacement après le blanc complet.

"
Class {
	#name : 'PerceptionCoverageAdapter',
	#superclass : 'PerceptionAdapter',
	#instVars : [
		'shadowCells',
		'fadeOutDuration'
	],
	#category : 'PerceptionMission',
	#package : 'PerceptionMission'
}

{ #category : 'display' }
PerceptionCoverageAdapter >> fadeOutDuration: seconds [
    (seconds isNumber and: [ seconds > 0 and: [ seconds asFloat isFinite ] ])
        ifFalse: [ self error: 'Le délai de transparence doit dépasser le délai de blanchiment.' ].
    fadeOutDuration := seconds

]

{ #category : 'display' }
PerceptionCoverageAdapter >> opacityOf: reading [
    fadeOutDuration ifNil: [ ^ 1.0 ].
    ^ ((self transparentAfterSeconds - (time - reading first))
        / fadeOutDuration asFloat max: 0.0) min: 1.0

]

{ #category : 'simulation' }
PerceptionCoverageAdapter >> recordAt: seconds polygon: vertices drones: poses [
    shadowCells := terrain collectShadowsDuring: [
        super recordAt: seconds polygon: vertices drones: poses ].
    ^ self

]

{ #category : 'display' }
PerceptionCoverageAdapter >> shadowGridCellsDo: block [
    shadowCells ifNotNil: [
        shadowCells do: [ :cell |
            | reading |
            reading := observations at: cell + gridOffset ifAbsent: [ nil ].
            (reading isNil or: [ reading first < time ]) ifTrue: [ block value: cell ] ] ]

]

{ #category : 'display' }
PerceptionCoverageAdapter >> transparentAfterSeconds [
    ^ fadeOutDuration ifNotNil: [ self fadeSeconds + fadeOutDuration ]

]
