Class {
	#name : 'EventBasedSimulator',
	#superclass : 'Object',
	#instVars : [
		'currentTime',
		'tasksQueue',
		'timeline',
		'model',
		'past'
	],
	#category : 'DroneSystem-Simulation-Revised',
	#package : 'DroneSystem-Simulation-Revised'
}

{ #category : 'accessing' }
EventBasedSimulator >> currentTime [

	^ currentTime
]

{ #category : 'accessing' }
EventBasedSimulator >> currentTime: anObject [

	currentTime := anObject
]

{ #category : 'initialize' }
EventBasedSimulator >> initialize [ 
currentTime :=0.
tasksQueue := SortedCollection sortBlock: [ :aTask :anotherTask| aTask startTime < anotherTask startTime ].
]

{ #category : 'accessing' }
EventBasedSimulator >> model [

	^ model
]

{ #category : 'accessing' }
EventBasedSimulator >> model: anObject [

	model := anObject
]

{ #category : 'accessing' }
EventBasedSimulator >> past [

	^ past
]

{ #category : 'accessing' }
EventBasedSimulator >> past: anObject [

	past := anObject
]

{ #category : 'registering' }
EventBasedSimulator >> registerTask: aTask [

self tasksQueue add: aTask.




]

{ #category : 'accessing' }
EventBasedSimulator >> tasksQueue [

	^ tasksQueue
]

{ #category : 'accessing' }
EventBasedSimulator >> tasksQueue: anObject [

	tasksQueue := anObject
]

{ #category : 'accessing' }
EventBasedSimulator >> timeline [

	^ timeline
]

{ #category : 'accessing' }
EventBasedSimulator >> timeline: anObject [

	timeline := anObject
]

{ #category : 'running-visiting' }
EventBasedSimulator >> visitSimulationTask: aTask [
	"The task has been completed. Play its effects, and tag the event as past"

	aTask startTime > self currentTime ifTrue: [ ^ self ]. "Cannot start before schedule"
	(aTask predecessors reject: [ :anEvent |
		 aTask status "I am already done" ]) ifNotEmpty: [ ^ self ]. "At least one prerequisite task's completion is missing"
	(aTask evaluateConditionFor: self) ifFalse: [ ^ self ]. "Condition is not met"
	aTask actualStartTime: self currentTime. "ok let's rock. Update the start date"
	aTask proceedFor: self. "Run the process"
	aTask successors do: [ :aSuccessor | "And check for tasks to be unlocked"
		aSuccessor cannotStartBefore: aTask expectedEndTime ]
]
