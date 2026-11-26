"
Un passage échantillonné sur le parcours macro. La position est une abscisse
curviligne en mètres et la date est exprimée en secondes simulées.
"
Class {
	#name : 'PointDePassage',
	#superclass : 'Object',
	#instVars : [ 'position', 'date', 'droneId' ],
	#category : 'DroneSystem-Macro',
	#package : 'DroneSystem-Macro'
}

{ #category : 'instance creation' }
PointDePassage class >> position: metres date: seconds droneId: identifier [
	^ self new initializePosition: metres date: seconds droneId: identifier
]

{ #category : 'initialization' }
PointDePassage >> initializePosition: metres date: seconds droneId: identifier [
	position := metres.
	date := seconds.
	droneId := identifier
]

{ #category : 'accessing' }
PointDePassage >> position [
	^ position
]

{ #category : 'accessing' }
PointDePassage >> date [
	^ date
]

{ #category : 'accessing' }
PointDePassage >> droneId [
	^ droneId
]
