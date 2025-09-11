Class {
	#name : 'ConcentricDefenseStrategy',
	#superclass : 'Object',
	#instVars : [
		'center',
		'radiusLayers',
		'spacing',
		'dronesPerLayer'
	],
	#category : 'DroneSystem-Strategies',
	#package : 'DroneSystem-Strategies'
}

{ #category : 'initialization' }
ConcentricDefenseStrategy >> applyTo: aSimulation [
    | allies lat0 lon0 lat lon i angle ringCount totalNodes idx d |
    allies := aSimulation allAlliedDrones.
    allies isEmpty ifTrue: [ ^ self ].
    lat0 := (center isPoint) ifTrue: [ center x ] ifFalse: [ center at: 1 ].
    lon0 := (center isPoint) ifTrue: [ center y ] ifFalse: [ center at: 2 ].
    1 to: radiusLayers do: [:i |
        ringCount := dronesPerLayer * i.
        totalNodes := ringCount.
        1 to: totalNodes do: [:idx |
            angle := (2 * Float pi * (idx - 1)) / totalNodes.
            lat := lat0 + ((spacing * i) * (angle cos) * 0.01).
            lon := lon0 + ((spacing * i) * (angle sin) * 0.01).
            d := (allies at: ((idx - 1) \\ allies size) + 1).
            d setBehavior: (StaticPositionBehavior new initializeWithLatitude: lat longitude: lon altitude: 120).
        ].
    ].
    Transcript show: 'ConcentricDefenseStrategy applied with ', radiusLayers asString, ' layers'; cr.
    ^ self.


]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> center [

	^ center
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> center: anObject [

	center := anObject
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> dronesPerLayer [

	^ dronesPerLayer
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> dronesPerLayer: anObject [

	dronesPerLayer := anObject
]

{ #category : 'initialization' }
ConcentricDefenseStrategy >> initializeWithCenter: aCenter radiusLayers: layers spacing: s dronesPerLayer: n [
    center := aCenter. radiusLayers := layers. spacing := s. dronesPerLayer := n. ^ self.
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> radiusLayers [

	^ radiusLayers
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> radiusLayers: anObject [

	radiusLayers := anObject
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> spacing [

	^ spacing
]

{ #category : 'accessing' }
ConcentricDefenseStrategy >> spacing: anObject [

	spacing := anObject
]
