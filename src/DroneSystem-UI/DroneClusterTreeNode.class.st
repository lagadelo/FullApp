Class {
	#name : 'DroneClusterTreeNode',
	#superclass : 'Object',
	#instVars : [
		'domainObject',
		'children'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'instance creation' }
DroneClusterTreeNode class >> fromCluster: aCluster [
    ^ self new
        domainObject: aCluster;
        children: (aCluster drones collect: [ :d | self fromDrone: d ]);
        yourself
]

{ #category : 'instance creation' }
DroneClusterTreeNode class >> fromDrone: aDrone [
    ^ self new
        domainObject: aDrone;
        children: #();
        yourself
]

{ #category : 'accessing' }
DroneClusterTreeNode >> children [
    ^ children
]

{ #category : 'accessing' }
DroneClusterTreeNode >> children: aCollection [
    children := aCollection
]

{ #category : 'accessing' }
DroneClusterTreeNode >> domainObject [
    ^ domainObject
]

{ #category : 'accessing' }
DroneClusterTreeNode >> domainObject: anObject [
    domainObject := anObject
]

{ #category : 'accessing' }
DroneClusterTreeNode >> label [
    (domainObject respondsTo: #isDrone) ifTrue: [ ^ 'Drone ', domainObject id asString ].
    (domainObject class name = #DroneCluster)
        ifTrue: [
            ^ 'Cluster(',
                (domainObject respondsTo: #id ifTrue: [ domainObject id asString ] ifFalse: [ '...' ]),
                ')' ].
    ^ domainObject class name
]
