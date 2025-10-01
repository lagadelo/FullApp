Class {
	#name : 'MissionPresenter',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'polygonLabel'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'initialization' }
MissionPresenter >> buildWith: builder [
    <spec: #default>

    builder label
        label: polygonLabel.
]

{ #category : 'initialization' }
MissionPresenter >> initializeWidgets [
    polygonLabel := ValueHolder with: 'No mission assigned'.
]

{ #category : 'initialization' }
MissionPresenter >> refreshMissionInfo [
    | mission polygonSize |
    mission := simulator currentMission.
    polygonSize := mission
        ifNil: [ 0 ]
        ifNotNil: [ mission polygon size ].

    polygonLabel contents: 'Mission zone: ', polygonSize printString, ' points'.
]

{ #category : 'initialization' }
MissionPresenter >> simulator: aSimulator [
    simulator := aSimulator.
    self refreshMissionInfo.
]
