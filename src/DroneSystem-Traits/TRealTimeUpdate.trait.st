Trait {
	#name : 'TRealTimeUpdate',
	#instVars : [
		'updateProcess'
	],
	#category : 'DroneSystem-Traits',
	#package : 'DroneSystem-Traits'
}

{ #category : 'as yet unclassified' }
TRealTimeUpdate >> startUpdatingEvery: ms [
    updateProcess ifNotNil: [ updateProcess terminate ].
    updateProcess := [
        [ true ] whileTrue: [
            self refreshView.
            (Delay forMilliseconds: ms) wait.
        ].
    ] forkAt: Processor userBackgroundPriority.


]

{ #category : 'as yet unclassified' }
TRealTimeUpdate >> stopUpdating [
    updateProcess ifNotNil: [ updateProcess terminate. updateProcess := nil ].


]
