Class {
	#name : 'SimulationTaskFactory',
	#superclass : 'Object',
	#category : 'DroneSystem-Simulation-Revised',
	#package : 'DroneSystem-Simulation-Revised'
}

{ #category : 'tasks exampleq' }
SimulationTaskFactory class >> example1 [

	| t |
	t := SimulationTask new.
	t minStartTime: 10.
	t duration: 5.
	t condition: [ :aClient :aTask | true ].
	t process: [ :aClient :aTask |
			Transcript
				show:
					'I am the task A, running at: ' , aClient currentTime printString;
				cr ].
	^ t
]

{ #category : 'tasks exampleq' }
SimulationTaskFactory class >> example2 [

	| t |
	t := SimulationTask new.
	t minStartTime: 20.
	t duration: 5.
	t condition: [ :aClient :aTask | true ].
	t process: [ :aClient :aTask |
			Transcript
				show:
					'I am the task B, running at: ' , aClient currentTime printString;
				cr ].
	^ t
]

{ #category : 'tasks exampleq' }
SimulationTaskFactory class >> example3 [

	| t |
	t := SimulationTask new.
	t minStartTime: 10.
	t duration: 3.
	t condition: [ :aClient :aTask | true ].
	t process: [ :aClient :aTask |
			Transcript
				show:
					'I am the task C, running at: ' , aClient currentTime printString;
				cr ].
	^ t
]

{ #category : 'tasks exampleq' }
SimulationTaskFactory class >> example4 [

	| t |
	t := SimulationTask new.
	t minStartTime: 15.
	t duration: 3.
	t condition: [ :aClient :aTask |
			SpConfirmDialog new
				title: 'Conditional example';
				label: 'Are you ready now?';
				acceptLabel: 'Sure!';
				cancelLabel: 'No, wait a bit';
				onAccept: [ :dialog | true ];
				onCancel: [ :dialog | false ];
				openModal ].
	t process: [ :aClient :aTask |
			Transcript
				show:
					'I am the task D, running at: ' , aClient currentTime printString;
				cr ].
	^ t
]

{ #category : 'tasks exampleq' }
SimulationTaskFactory class >> fullExample1 [

	| a b c d sim |
	a := self example1.
	b := self example2.
	c := self example3.
	d := self example4.
	
sim := EventBasedSimulator new.
sim registerTask: a; registerTask: b; registerTask: c; registerTask: d.

]
