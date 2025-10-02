Class {
	#name : 'DroneListPresenter',
	#superclass : 'Object',
	#instVars : [
		'simulator',
		'dronesModel',
		'polygonLabel'
	],
	#category : 'DroneSystem-Visualization',
	#package : 'DroneSystem-Visualization'
}

{ #category : 'initialization' }
DroneListPresenter >> buildWith: builder [
    <spec: #default>

    builder label label: polygonLabel.
]

{ #category : 'initialization' }
DroneListPresenter >> initializeWidgets [
    polygonLabel := ValueHolder with: 'No mission assigned'.
]

{ #category : 'initialization' }
DroneListPresenter >> refreshDroneList [
    dronesModel contents: simulator allDrones.
]

{ #category : 'initialization' }
DroneListPresenter >> refreshMissionInfo [
    | mission |
    mission := simulator currentMission.
    polygonLabel contents: 'Mission zone: ', (mission polygon size) printString, ' points'.
]

{ #category : 'initialization' }
DroneListPresenter >> simulator: aSimulator [
    simulator := aSimulator.
    self refreshMissionInfo.
]
