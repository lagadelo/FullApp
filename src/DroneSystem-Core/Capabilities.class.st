Class {
	#name : 'Capabilities',
	#superclass : 'Object',
	#instVars : [
		'currentCapabilities',
		'maxCapabilities'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'facilities' }
Capabilities >> ammunition [ 
^self getCapability: #ammunition
]

{ #category : 'facilities' }
Capabilities >> ammunition: aValue [

	^ self setCapability: #ammunition value: aValue
]

{ #category : 'availability' }
Capabilities >> availablePercentage: aCapabilityName [

	^ (currentCapabilities at: aCapabilityName)
	  / (maxCapabilities at: aCapabilityName)
]

{ #category : 'facilities' }
Capabilities >> communicationRange [

	^ self getCapability: #communicationRange  
]

{ #category : 'facilities' }
Capabilities >> communicationRange: aValue [

	^ self setCapability: #communicationRange value: aValue
]

{ #category : 'consumption' }
Capabilities >> consume: aValue of: aCapabilityName [

	^ (self getCapability: aCapabilityName) >= aValue
		  ifTrue: [
				  self
					  setCapability: aCapabilityName
					  value:  (self getCapability: aCapabilityName) - aValue ]
		  ifFalse: [ self error: 'Insufficient capabilitiy' ]
]

{ #category : 'consumption' }
Capabilities >> consumePercent: aValue of: aCapabilityName [

	^ self consume: (self getMaxCapability: aCapabilityName) * aValue of: aCapabilityName
			 
]

{ #category : 'consumption' }
Capabilities >> consumed: aCapabilityName [

	^ (self getMaxCapability: aCapabilityName) - (self getCapability: aCapabilityName)
]

{ #category : 'consumption' }
Capabilities >> consumedPercentage: aCapabilityName [

	^ 1- (self availablePercentage: aCapabilityName)
]

{ #category : 'evolution' }
Capabilities >> define: aCapabilityName [

	currentCapabilities
		at: aCapabilityName
		ifPresent: [ self error: 'Existing capability cannot be defined' ]
		ifAbsentPut: [
		self error: 'Cannot define capability without providing max value' ]
]

{ #category : 'as yet unclassified' }
Capabilities >> define: aCapabilityName  maxValue: aValue [

	maxCapabilities at: aCapabilityName  ifPresent: [
		^self error: 'Existing capability cannot be defined' ]  ifAbsentPut: [ aValue].

	currentCapabilities at: aCapabilityName put: aValue	
]

{ #category : 'facilities' }
Capabilities >> energy [ 
^self getCapability: #energy
]

{ #category : 'facilities' }
Capabilities >> energy: aValue [

	^ self setCapability: #energy value: aValue
]

{ #category : 'as yet unclassified' }
Capabilities >> forget: aCapabilityName [  

	maxCapabilities removeKey: aCapabilityName.
	currentCapabilities  removeKey: aCapabilityName.
]

{ #category : 'availability' }
Capabilities >> getCapability: aCapabilityName [

	^ currentCapabilities
		  at: aCapabilityName
		  ifAbsent: [ self error: 'Non existing capability' ]
]

{ #category : 'availability' }
Capabilities >> getMaxCapability: aCapabilityName [

	^ maxCapabilities
		  at: aCapabilityName
		  ifAbsent: [ self error: 'Non existing capability' ]
]

{ #category : 'initialization' }
Capabilities >> initialize [ 
maxCapabilities := IdentityDictionary new.
currentCapabilities := IdentityDictionary new.
]

{ #category : 'facilities' }
Capabilities >> perceptionRange [ 
^self getCapability: #perceptionRange
]

{ #category : 'facilities' }
Capabilities >> perceptionRange: aValue [

	^ self setCapability: #perceptionRange value: aValue
]

{ #category : 'evolution' }
Capabilities >> receive: aValue of: aCapabilityName [


" returns the residual amount of provided capability"
	| amount |
	amount := aValue min: (self consumed: aCapabilityName ).
	self setCapability: aCapabilityName value: amount.
	^ aValue - amount
]

{ #category : 'private' }
Capabilities >> setCapability: aCapabilityName value: aValue [

	(currentCapabilities keys includes: aCapabilityName) ifFalse: [
		self error: 'Non existing capability' ].
	(aValue > (maxCapabilities at: aCapabilityName)) ifTrue:[self error:'Limit exceeded'.].
	currentCapabilities at: aCapabilityName put: aValue
]
