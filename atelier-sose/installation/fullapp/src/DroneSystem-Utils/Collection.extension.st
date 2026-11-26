Extension { #name : 'Collection' }

{ #category : '*DroneSystem-Utils' }
Collection >> collectMany: aBlock [
   "Returns a flattened collection by applying aBlock to each element.
Each sub-collection produced by aBlock is concatenated into the result."
    
    | result |
    result := OrderedCollection new.
    self do: [:each |
        (aBlock value: each) do: [:subElement |
            result add: subElement ] ].
    ^ result
]

{ #category : '*DroneSystem-Utils' }
Collection >> selectMany: aBlock [
    | results |
    results := OrderedCollection new.
    self do: [:each |
        (aBlock value: each) do: [:sub | results add: sub ] ].
    ^ results
]
