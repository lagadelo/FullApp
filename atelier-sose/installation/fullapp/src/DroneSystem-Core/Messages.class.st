Class {
	#name : 'Messages',
	#superclass : 'Object',
	#instVars : [
		'type',
		'emiter',
		'destinators',
		'intent',
		'receivers',
		'payload'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'facilities' }
Messages class >> broadcastHelpRequest: anEmiter [

 
	^ self new
		  intent: #HelpRequest;
		  emiter: anEmiter;
		  receivers: #();
		  yourself
]

{ #category : 'facilities' }
Messages class >> from: anEmiter identifyRequest: someReceivers [

	^ self new
		  intent: #Query;
		  emiter: anEmiter;
		  receivers: someReceivers;
		  payload: [ :e :r | r id ];
		  yourself
]

{ #category : 'facilities' }
Messages class >> from: anEmiter to: someReceivers queryValue: aValue [

	^ self new
		  intent: #Query;
		  emiter: anEmiter;
		  receivers: #(  );
		  payload: [ :e :r | r getCapability: aValue ];
		  yourself
]

{ #category : 'instance creation' }
Messages class >> intent: anIntent from: anEmiter to: someReceivers payload: aPayload [

	(self supportedIntents includes: anIntent) ifFalse: [
		self error: 'Unsupported intent' ].
	^ self new
		  intent: anIntent;
		  emiter: anEmiter;
		  receivers: someReceivers;
		  payload: aPayload;
		  yourself
]

{ #category : 'instance creation' }
Messages class >> supportedIntents [

	^ { #HelpRequest. #HelpSupport. #Query. #Information }
]

{ #category : 'accessing' }
Messages >> destinators [

	^ destinators
]

{ #category : 'accessing' }
Messages >> destinators: anObject [

	destinators := anObject
]

{ #category : 'leaks' }
Messages >> doesLeak [

^self receivers anySatisfy: [ :a|  (self destinators includes: a) not  ]
]

{ #category : 'accessing' }
Messages >> emiter [

	^ emiter
]

{ #category : 'accessing' }
Messages >> emiter: anObject [

	emiter := anObject
]

{ #category : 'accessing' }
Messages >> intent [

	^ intent
]

{ #category : 'accessing' }
Messages >> intent: anObject [

	intent := anObject
]

{ #category : 'accessing' }
Messages >> payload [

	^ payload
]

{ #category : 'accessing' }
Messages >> payload: anObject [

	payload := anObject
]

{ #category : 'accessing' }
Messages >> receivers [

	^ receivers
]

{ #category : 'accessing' }
Messages >> receivers: anObject [

	receivers := anObject
]

{ #category : 'accessing' }
Messages >> type [

	^ self destinators size = 1
		  ifTrue: [ ^ #PointToPoint ]
		  ifFalse: [ #Broascast ]
]
