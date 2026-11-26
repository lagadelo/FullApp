"
Récupère les cellules masquées pendant l’acquisition. Le terrain donne un état distinct lorsque le rayon rencontre une donnée manquante. Le MNS, lorsqu’il est fourni, permet de tester aussi les surfaces au-dessus du sol.

"
Class {
	#name : 'PerceptionTerrainWithShadows',
	#superclass : 'PerceptionTerrain',
	#instVars : [
		'shadowCandidates'
	],
	#category : 'PerceptionMission',
	#package : 'PerceptionMission'
}

{ #category : 'visibility' }
PerceptionTerrainWithShadows >> collectShadowsDuring: block [
    | previous candidates |
    previous := shadowCandidates.
    candidates := Set new.
    shadowCandidates := candidates.
    block ensure: [ shadowCandidates := previous ].
    ^ candidates

]

{ #category : 'visibility' }
PerceptionTerrainWithShadows >> rayStatusForColumn: column row: row from: cameraGrid elevation: cameraAltitude clearance: clearance [
    | x y sensorX sensorY dx dy stepX stepY deltaX deltaY nextX nextY entryX entryY t surfaceZ targetZ |
    x := column.
    y := row.
    sensorX := cameraGrid x floor.
    sensorY := cameraGrid y floor.
    dx := cameraGrid x - (x + 0.5).
    dy := cameraGrid y - (y + 0.5).
    stepX := dx sign.
    stepY := dy sign.
    deltaX := stepX = 0 ifTrue: [ Float infinity ] ifFalse: [ 1.0 / dx abs ].
    deltaY := stepY = 0 ifTrue: [ Float infinity ] ifFalse: [ 1.0 / dy abs ].
    nextX := deltaX / 2.
    nextY := deltaY / 2.
    targetZ := cameraAltitude - clearance.
    [ x = sensorX and: [ y = sensorY ] ] whileFalse: [
        entryX := x = sensorX ifTrue: [ Float infinity ] ifFalse: [ nextX ].
        entryY := y = sensorY ifTrue: [ Float infinity ] ifFalse: [ nextY ].
        t := entryX min: entryY.
        entryX <= t ifTrue: [ x := x + stepX. nextX := nextX + deltaX ].
        entryY <= t ifTrue: [ y := y + stepY. nextY := nextY + deltaY ].
        surfaceZ := self surfaceAtColumn: x row: y.
        surfaceZ ifNil: [ ^ #unknown ].
        surfaceZ > (targetZ + (clearance * t) + 0.000001) ifTrue: [ ^ #masked ] ].
    ^ #visible
]

{ #category : 'visibility' }
PerceptionTerrainWithShadows >> visibleColumn: column row: row from: cameraGrid elevation: altitude clearance: clearance [
    | status |
    status := self rayStatusForColumn: column row: row from: cameraGrid
        elevation: altitude clearance: clearance.
    (status = #masked and: [ shadowCandidates notNil ]) ifTrue: [
        shadowCandidates add: column @ row ].
    ^ status = #visible

]
