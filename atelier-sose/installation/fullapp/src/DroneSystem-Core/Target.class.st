Class {
	#name : 'Target',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'position',
		'movable',
		'strategicImportance',
		'model',
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

{ #category : 'building' }
Target >> addDependency: aTarget [ 
    dependencies add: aTarget.
    aTarget addDependent: self.
]

{ #category : 'building' }
Target >> addDependent: aTarget [ 
    dependents add: aTarget.

]

{ #category : 'destroying' }
Target >> cascadeDestroy [

	self dependents do: [ :a | a destroy ]
]

{ #category : 'building' }
Target >> dependencies [

	^ dependencies
]

{ #category : 'building' }
Target >> dependents [

	^ dependents
]

{ #category : 'destroying' }
Target >> destroy [

	self model destroy.
	destroyed := true.
	self cascadeDestroy
]

{ #category : 'accessing' }
Target >> destroyed [

	^ destroyed
]

{ #category : 'accessing' }
Target >> id [

	^ id
]

{ #category : 'accessing' }
Target >> id: anObject [

	id := anObject
]

{ #category : 'adding' }
Target >> initialize [

	destroyed := false.
	dependents := OrderedCollection new.
	dependencies := OrderedCollection new
]

{ #category : 'accessing' }
Target >> isMovable [

	^ self model isMovable
]

{ #category : 'accessing' }
Target >> model [

	^ model
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

{ #category : 'destroying' }
Target >> weakenDueTo: aTarget [ 
    "Reduce strategic importance or mark as weakened"
    strategicImportance := strategicImportance // 2.
]
