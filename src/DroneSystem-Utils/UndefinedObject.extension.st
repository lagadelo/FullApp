Extension { #name : 'UndefinedObject' }

{ #category : '*DroneSystem-Utils' }
UndefinedObject >> merge: aRectangle [

"This prevent miltiple refreshs from interleaving"
self assert:(aRectangle inheritsFrom: Rectangle).
^aRectangle
]
