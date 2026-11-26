Class {
	#name : 'STFileIn',
	#superclass : 'Object',
	#instVars : [
		'dummy'
	],
	#category : 'DroneSystem-Utils',
	#package : 'DroneSystem-Utils'
}

{ #category : 'as yet unclassified' }
STFileIn class >> fileInSt: aPath [
    (FileStream readOnlyFileNamed: aPath) do: [:stream |
        Compiler evaluate: stream contents
    ].
]
