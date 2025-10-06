Class {
	#name : 'Target',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'position',
		'movable',
		'strategicImportance',
		'type',
		'dependencies',
		'dependents',
		'destroyed'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'examples' }
Target class >> example [



| powerPlant bridge base city |
powerPlant := Target named: 'Power Plant' position: (GeoPoint latitude: 48.9 longitude: 2.3 altitude: 0) type: #infrastructure strategicImportance: 8 movable: false.
bridge := Target named: 'Bridge' position: (GeoPoint latitude: 48.8 longitude: 2.4 altitude: 0) type: #infrastructure strategicImportance: 5 movable: false.
base := Target named: 'Military Base' position: (GeoPoint latitude: 48.7 longitude: 2.5 altitude: 0) type: #military strategicImportance: 10 movable: false.
city := Target named: 'City' position: (GeoPoint latitude: 48.6 longitude: 2.6 altitude: 0) type: #civilian strategicImportance: 7 movable: false.

"Set up dependencies: base depends on powerPlant and bridge"
base addDependency: powerPlant.
base addDependency: bridge.

"Destroy power plant and propagate impact"
powerPlant destroy.
"base strategicImportance is now reduced"
]

{ #category : 'instance creation' }
Target class >> named: aString position: aGeoPoint type: aSymbol strategicImportance: anInteger movable: aBoolean [ 
    ^ self new
        id: UUID new asString;
        name: aString;
        position: aGeoPoint;
        type: aSymbol;
        strategicImportance: anInteger;
        movable: aBoolean;
        dependencies: OrderedCollection new;
        dependents: OrderedCollection new;
        destroyed: false;
        yourself
]

{ #category : 'adding' }
Target >> addDependency: aTarget [ 
    dependencies add: aTarget.
    aTarget addDependent: self.
]

{ #category : 'adding' }
Target >> addDependent: aTarget [ 
    dependents add: aTarget.

]

{ #category : 'accessing' }
Target >> dependencies [

	^ dependencies
]

{ #category : 'accessing' }
Target >> dependencies: anObject [

	dependencies := anObject
]

{ #category : 'accessing' }
Target >> dependents1 [

	^ dependents
]

{ #category : 'accessing' }
Target >> dependents: anObject [

	dependents := anObject
]

{ #category : 'adding' }
Target >> destroy [ 
    destroyed := true.
    dependents do: [:dep | dep weakenDueTo: self]
]

{ #category : 'accessing' }
Target >> destroyed [

	^ destroyed
]

{ #category : 'accessing' }
Target >> destroyed: anObject [

	destroyed := anObject
]

{ #category : 'accessing' }
Target >> id [

	^ id
]

{ #category : 'accessing' }
Target >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
Target >> movable [

	^ movable
]

{ #category : 'accessing' }
Target >> movable: anObject [

	movable := anObject
]

{ #category : 'accessing' }
Target >> name [

	^ name
]

{ #category : 'accessing' }
Target >> name: anObject [

	name := anObject
]

{ #category : 'accessing' }
Target >> position [

	^ position
]

{ #category : 'accessing' }
Target >> position: anObject [

	position := anObject
]

{ #category : 'accessing' }
Target >> strategicImportance [

	^ strategicImportance
]

{ #category : 'accessing' }
Target >> strategicImportance: anObject [

	strategicImportance := anObject
]

{ #category : 'accessing' }
Target >> type [

	^ type
]

{ #category : 'accessing' }
Target >> type: anObject [

	type := anObject
]

{ #category : 'adding' }
Target >> weakenDueTo: aTarget [ 
    "Reduce strategic importance or mark as weakened"
    strategicImportance := strategicImportance // 2.
]
