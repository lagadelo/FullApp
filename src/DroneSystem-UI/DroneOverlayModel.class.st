Class {
	#name : 'DroneOverlayModel',
	#superclass : 'Object',
	#instVars : [
		'showPerceptionRadius',
		'showEnergyBars',
		'showAmmoBars',
		'showMissionPaths',
		'showClusterHull',
		'autoFocusSelection',
		'changeBlock'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'initialization' }
DroneOverlayModel >> autoFocusSelection [
    ^ autoFocusSelection
]

{ #category : 'initialization' }
DroneOverlayModel >> autoFocusSelection: aBoolean [
    autoFocusSelection := aBoolean.
    self changed
]

{ #category : 'accessing' }
DroneOverlayModel >> changeBlock [

	^ changeBlock
]

{ #category : 'accessing' }
DroneOverlayModel >> changeBlock: anObject [

	changeBlock := anObject
]

{ #category : 'initialization' }
DroneOverlayModel >> changed [
    changeBlock ifNotNil: [ changeBlock value ]
]

{ #category : 'initialization' }
DroneOverlayModel >> initialize [ 
    showPerceptionRadius := true.
    showEnergyBars := true.
    showAmmoBars := false.
    showMissionPaths := true.
    showClusterHull := false.
    autoFocusSelection := false.
]

{ #category : 'initialization' }
DroneOverlayModel >> onChange: aBlock [ 

changeBlock := aBlock 
]

{ #category : 'initialization' }
DroneOverlayModel >> showAmmoBars [
    ^ showAmmoBars
]

{ #category : 'initialization' }
DroneOverlayModel >> showAmmoBars: aBoolean [
    showAmmoBars := aBoolean.
    self changed
]

{ #category : 'initialization' }
DroneOverlayModel >> showClusterHull [
    ^ showClusterHull
]

{ #category : 'initialization' }
DroneOverlayModel >> showClusterHull: aBoolean [
    showClusterHull := aBoolean.
    self changed
]

{ #category : 'initialization' }
DroneOverlayModel >> showEnergyBars [
    ^ showEnergyBars
]

{ #category : 'initialization' }
DroneOverlayModel >> showEnergyBars: aBoolean [
    showEnergyBars := aBoolean.
    self changed
]

{ #category : 'initialization' }
DroneOverlayModel >> showMissionPaths [
    ^ showMissionPaths
]

{ #category : 'initialization' }
DroneOverlayModel >> showMissionPaths: aBoolean [
    showMissionPaths := aBoolean.
    self changed
]

{ #category : 'initialization' }
DroneOverlayModel >> showPerceptionRadius [
    ^ showPerceptionRadius
]

{ #category : 'initialization' }
DroneOverlayModel >> showPerceptionRadius: aBoolean [
    showPerceptionRadius := aBoolean.
    self changed
]
