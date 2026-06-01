Class {
	#name : 'DroneFleetEvent',
	#superclass : 'Object',
	#instVars : [
		'timestep',
		'type',
		'magnitude',
		'metadata'
	],
	#category : 'DroneHandoff',
	#package : 'DroneHandoff'
}

{ #category : 'instance creation' }
DroneFleetEvent class >> intrusionAt: t metadata: aDict [

	^ self new
		  type: #intrusion;
		  magnitude: nil;
		  timestep: t;
		  metadata: aDict;
		  yourself
]

{ #category : 'instance creation' }
DroneFleetEvent class >> oss: n at: t [

	^ self new
		  type: #loss;
		  magnitude: n;
		  timestep: t;
		  yourself
]

{ #category : 'instance creation' }
DroneFleetEvent class >> reinforcement: n at: t [

	^ self new
		  type: #reinforcement;
		  magnitude: n;
		  timestep: t;
		  yourself
]

{ #category : 'accessing' }
DroneFleetEvent >> magnitude [

	^ magnitude
]

{ #category : 'accessing' }
DroneFleetEvent >> magnitude: anObject [

	magnitude := anObject
]

{ #category : 'accessing' }
DroneFleetEvent >> metadata [

	^ metadata
]

{ #category : 'accessing' }
DroneFleetEvent >> metadata: anObject [

	metadata := anObject
]

{ #category : 'accessing' }
DroneFleetEvent >> timestep [

	^ timestep
]

{ #category : 'accessing' }
DroneFleetEvent >> timestep: anObject [

	timestep := anObject
]

{ #category : 'accessing' }
DroneFleetEvent >> type [

	^ type
]

{ #category : 'accessing' }
DroneFleetEvent >> type: anObject [

	type := anObject
]
