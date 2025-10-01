Class {
	#name : 'ClusterPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'cluster',
		'clusterInfoLabel',
		'droneCountLabel',
		'leaderLabel'
	],
	#category : 'DroneSystem-Visualization-visualization',
	#package : 'DroneSystem-Visualization',
	#tag : 'visualization'
}

{ #category : 'initialization - deprecated' }
ClusterPresenter >> buildWith: builder [
    <spec: #default>

    builder
        newColumn: [
            builder label label: clusterInfoLabel.
            builder label label: droneCountLabel.
            builder label label: leaderLabel.
        ].
]

{ #category : 'initialization - deprecated' }
ClusterPresenter >> cluster: aCluster [
    cluster := aCluster.
    self updateClusterInfo.
]

{ #category : 'initialization - deprecated' }
ClusterPresenter >> initializeWidgets [
    clusterInfoLabel := ValueHolder with: 'No cluster assigned'.
    droneCountLabel := ValueHolder with: 'Drones: 0'.
    leaderLabel := ValueHolder with: 'Leader: Unknown'.
]

{ #category : 'initialization - deprecated' }
ClusterPresenter >> updateClusterInfo [
    clusterInfoLabel contents: 'Cluster ID: ', cluster clusterId printString.
    droneCountLabel contents: 'Drones: ', cluster drones size printString.
    leaderLabel contents: 'Leader: ', (cluster leader ifNotNil: [ cluster leader id printString ] ifNil: [ 'None' ]).
]
