Class {
	#name : 'DroneEnvironment',
	#superclass : 'Object',
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'as yet unclassified' }
DroneEnvironment class >> roasalVersion [
	 | version |

version := (Smalltalk at: #RSCanvas ifAbsent: [ nil ]) notNil
    ifTrue: [
        (RSCanvas package name includesSubstring: 'Roassal3')
            ifTrue: [ 'Roassal3 détecté ✅ (' , RSCanvas package name , ')' ]
            ifFalse: [ 'Roassal2 détecté ✅ (' , RSCanvas package name , ')' ]
    ]
    ifFalse: [
        (Smalltalk includesKey: #RTView)
            ifTrue: [ 'Roassal2 détecté (classe RTView présente) ✅' ]
            ifFalse: [ 'Aucune version de Roassal détectée ❌' ]
    ].

version inspect.
]
