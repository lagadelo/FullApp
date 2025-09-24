Class {
	#name : 'DroneSystemPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'buttonStart',
		'buttonHalt',
		'buttonStop',
		'result',
		'dronesList'
	],
	#category : 'DroneSystem-Visualization-visualization',
	#package : 'DroneSystem-Visualization',
	#tag : 'visualization'
}

{ #category : 'example' }
DroneSystemPresenter class >> exampleEntryCompletion [ 
self new open 
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonHalt [

	^ buttonHalt
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonHalt: anObject [

	buttonHalt := anObject
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonStart [

	^ buttonStart
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonStart: anObject [

	buttonStart := anObject
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonStop [

	^ buttonStop
]

{ #category : 'accessing' }
DroneSystemPresenter >> buttonStop: anObject [

	buttonStop := anObject
]

{ #category : 'initialization' }
DroneSystemPresenter >> connectPresenters [

"buttonStart action: [ result label: buttonStart label ].
  buttonHalt action: [ result label: buttonHalt label ].
  buttonStop action: [ result label: buttonStop label ]"
]

{ #category : 'initialization' }
DroneSystemPresenter >> defaultLayout [
  ^ SpBoxLayout newTopToBottom
            add: dronesList ;
yourself
" ^ SpBoxLayout newTopToBottom
    add: (SpBoxLayout newLeftToRight
        add: buttonStop;
        add: buttonStart;
        add: buttonHalt;
        yourself);
    add: result;
    yourself"
]

{ #category : 'accessing' }
DroneSystemPresenter >> dronesList [

	^ dronesList
]

{ #category : 'accessing' }
DroneSystemPresenter >> dronesList: anObject [

	dronesList := anObject
]

{ #category : 'initialization' }
DroneSystemPresenter >> initializePresenters [

 
        dronesList := self newTable
          addColumn: (SpStringTableColumn title: 'ID'
   
evaluated: #uniqueID);
          addColumn: (SpStringTableColumn title: 'latitude'
            evaluated: #latitude);
          addColumn: (SpStringTableColumn title: 'longitude'
            evaluated: #latitude);
          yourself

"result := self newLabel.
buttonStart := self newButton.
buttonHalt := self newButton.
buttonStop := self newButton.


result label: 'Please give us your feedback.'.
  buttonStart
    label: 'Start';
    icon: (self iconNamed: #smallDoIt ).
  buttonHalt
    label: 'Halt';
    icon: (self iconNamed: #pause).
  buttonStop
    label: 'Stop';
    icon: (self iconNamed: #smallStop)"
]

{ #category : 'initialization' }
DroneSystemPresenter >> initializeWindow: aWindowPresenter [
 "       super initializeWindow: aWindowPresenter.
        aWindowPresenter
          title: 'Customer Satisfaction Survey';
          initialExtent: 400@100"
 
        | addButton toolbar |
        addButton := self newToolbarButton
            label: 'Add film' ;
            icon: (self iconNamed: #smallAdd);
            action: [ "self addFilm" ];
            yourself.
        toolbar := self newToolbar
          add: addButton;
          yourself.
        aWindowPresenter
          title: 'Mini IMDB';
          initialExtent: 600@400;
          toolbar: toolbar

]

{ #category : 'accessing' }
DroneSystemPresenter >> result [

	^ result
]

{ #category : 'accessing' }
DroneSystemPresenter >> result: anObject [

	result := anObject
]

{ #category : 'initialization' }
DroneSystemPresenter >> updatePresenter [
        dronesList items: Drone allInstances
]
