"
Une scène relie le MNT/MNS et le parcours ordonné au simulateur SoSe. Les sommets et les points mobiles s’expriment dans le repère d’entrée de terrain.json. L’observateur reçoit un MacroSimulatorStep et un instant cumulé en secondes. La hauteur est en mètres au-dessus du sol.

scene := PerceptionScene on: ground wayPoints: orderedPoints.
observer := scene observerWith: options
    heightAt: [ :step :drone | 180 ]
    intrudersAt: [ :step | #() ].
view := observer value: step value: (step timeStep * 2).

Pour une condition de scénario dans le repère métrique de la scène, utiliser positionOf:in:. Chaque appel à observerWith:heightAt:intrudersAt: ouvre une mémoire de relevés pour un nouveau rejeu.

"
Class {
	#name : 'PerceptionScene',
	#superclass : 'Object',
	#instVars : [
		'terrain',
		'projection',
		'route',
		'segments',
		'perimeter'
	],
	#category : 'PerceptionMission',
	#package : 'PerceptionMission'
}

{ #category : 'instance creation' }
PerceptionScene class >> on: directory wayPoints: vertices [
    ^ self new initializeOn: directory wayPoints: vertices

]

{ #category : 'initialization' }
PerceptionScene >> initializeOn: aDirectory wayPoints: vertices [
    | directory metadata |
    directory := aDirectory asFileReference.
    metadata := STONJSON fromString: (directory / 'terrain.json') contents.
    terrain := PerceptionTerrainWithShadows fromDirectory: directory metadata: metadata.
    projection := PerceptionCoordinateTransform forMetadata: metadata.
    route := (PerceptionAdapter on: terrain projection: projection) projectPolygon: vertices.
    segments := OrderedCollection new.
    perimeter := 0.0.
    route withIndexDo: [ :point :index |
        | next endDistance |
        next := route at: (index \\ route size) + 1.
        endDistance := perimeter + (point distanceTo: next).
        endDistance > perimeter ifTrue: [
            segments add: { point. next. perimeter. endDistance }.
            perimeter := endDistance ] ]

]

{ #category : 'observation' }
PerceptionScene >> observerWith: settings heightAt: heightAt intrudersAt: intrudersAt [
    ^ self observerWith: settings heightAt: heightAt intrudersAt: intrudersAt secondsPerTick: 1

]

{ #category : 'observation' }
PerceptionScene >> observerWith: settings heightAt: heightAt intrudersAt: intrudersAt secondsPerTick: tickSeconds [
    | adapter view lossSeconds visibleLosses knownLosses camera fade
      measureAcceleration previousSpeeds previousSeconds |
    (tickSeconds isNumber and: [ tickSeconds asFloat isFinite and: [ tickSeconds > 0 ] ])
        ifFalse: [ self error: 'La durée d’un tik doit être positive et finie.' ].
    lossSeconds := settings at: #lossMarkerSeconds ifAbsent: [ 0 ].
    (lossSeconds isNumber and: [ lossSeconds >= 0 and: [ lossSeconds asFloat isFinite ] ])
        ifFalse: [ self error: 'La durée d’affichage d’une perte doit être finie et positive ou nulle.' ].
    camera := settings at: #camera ifAbsent: [ #(1.0 2000) ].
    fade := settings at: #fadeAfterSeconds ifAbsent: [ 300 ].
    adapter := PerceptionCoverageAdapter on: terrain copy.
    adapter cameraHalfFieldTangent: camera first sensorSidePixels: camera second.
    adapter fadeAfterSeconds: fade.
    (settings at: #transparentAfterSeconds ifAbsent: [ nil ]) ifNotNil: [ :seconds |
        adapter fadeOutDuration: seconds - fade ].
    view := PerceptionMissionView on: adapter options: settings.
    measureAcceleration := view droneColorMode = #acceleration.
    knownLosses := Set new.
    visibleLosses := OrderedCollection new.
    ^ [ :step :seconds |
        | speeds currentSpeeds poses newLosses positions points |
        speeds := Dictionary new.
        currentSpeeds := measureAcceleration ifTrue: [ Dictionary new ].
        poses := step drones collect: [ :drone |
            | id speed |
            id := drone id.
            speed := drone currentSpeed.
            drone nominalSpeed > 0 ifTrue: [
                speeds at: id put: speed / drone nominalSpeed ].
            measureAcceleration ifTrue: [ currentSpeeds at: id put: speed ].
            PerceptionDronePose id: id position: (self positionOf: drone in: step)
                heightAboveGround: (heightAt value: step value: drone) ].
        newLosses := OrderedCollection new.
        lossSeconds > 0 ifTrue: [
            step lostDrones do: [ :drone |
                (knownLosses includes: drone id) ifFalse: [
                    newLosses add: { drone id. self positionOf: drone in: step. seconds } ] ] ].
        positions := (intrudersAt value: step) collect: [ :pair |
            { pair first. self project: pair second } ].
        adapter recordAt: seconds polygon: route drones: poses.
        points := positions collect: [ :pair |
            | reading |
            reading := adapter observationAt: pair second.
            { pair first. pair second. reading notNil and: [ reading first = seconds ] } ].
        visibleLosses := visibleLosses select: [ :marker | seconds - marker third < lossSeconds ].
        newLosses do: [ :marker | knownLosses add: marker first. visibleLosses add: marker ].
        view annotateSpeeds: speeds losses: visibleLosses intruders: points.
        measureAcceleration ifTrue: [
            | values scale |
            values := Dictionary new.
            previousSeconds ifNotNil: [
                "La vitesse du simulateur est un déplacement par tik."
                scale := tickSeconds * (seconds - previousSeconds).
                currentSpeeds keysAndValuesDo: [ :id :speed |
                    previousSpeeds at: id ifPresent: [ :previous |
                        values at: id put: (speed - previous) / scale ] ] ].
            view annotateAccelerations: values.
            previousSpeeds := currentSpeeds.
            previousSeconds := seconds ].
        view ]

]

{ #category : 'accessing' }
PerceptionScene >> perimeterMeters [
    ^ perimeter

]

{ #category : 'position' }
PerceptionScene >> positionOf: drone in: step [
    | distance segment fraction |
    distance := (drone position \\ step range) / step range * perimeter.
    segment := segments detect: [ :each | distance < each fourth ] ifNone: [ segments last ].
    fraction := (distance - segment third) / (segment fourth - segment third).
    ^ segment first interpolateTo: segment second at: fraction

]

{ #category : 'position' }
PerceptionScene >> project: point [
    ^ projection value: point

]
