Class {
	#name : 'RealDrone',
	#superclass : 'AbstractDrone',
	#instVars : [
		'adapter',
		'currentCommandedWaypoint'
	],
	#category : 'DroneSystem-Core',
	#package : 'DroneSystem-Core'
}

{ #category : 'path commands' }
RealDrone >> hasMoreWaypoints [
    "Dépend du contexte, ou peut être synchronisé avec le simulateur"
    ^ adapter hasPendingWaypoints.

]

{ #category : 'path commands' }
RealDrone >> moveTo: aWaypoint [
    currentCommandedWaypoint := aWaypoint.
    adapter sendMoveCommandTo: aWaypoint.

]

{ #category : 'path commands' }
RealDrone >> position [
    ^ adapter currentGPSPosition.

]
