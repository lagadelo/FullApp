Class {
	#name : 'ResiliencyPolicyFactory',
	#superclass : 'Object',
	#category : 'DroneSystem-Evaluation-Resilience',
	#package : 'DroneSystem-Evaluation-Resilience'
}

{ #category : 'factory' }
ResiliencyPolicyFactory >> createAdaptivePolicy [
	"Adaptation: réassigne les waypoints, engage spares si besoin, rollback possible"
	^ ResiliencyPolicy new
		policyName: 'Adaptive';
		description: 'Adaptive: rebalance waypoints, lazy spare activation, rollback on critical failure';
		spareDroneActivationMode: #lazy;
		failureThreshold: 0.2;
		rebalancingStrategy: #redistribute;
		rollbackOnFailure: true
]

{ #category : 'factory' }
ResiliencyPolicyFactory >> createConservativePolicy [
	"Conservative: activation tardive des spares, haute tolérance à la dégradation"
	^ ResiliencyPolicy new
		policyName: 'Conservative';
		description: 'Conservative: lazy spare activation, high degradation tolerance';
		spareDroneActivationMode: #lazy;
		failureThreshold: 0.1;
		rebalancingStrategy: #sequential;
		rollbackOnFailure: false
]

{ #category : 'factory' }
ResiliencyPolicyFactory >> createFailFastPolicy [
	"Fail-fast: abandon mission si seuil atteint"
	^ ResiliencyPolicy new
		policyName: 'FailFast';
		description: 'Fail-fast: abort mission if resilience drops below threshold';
		spareDroneActivationMode: #never;
		failureThreshold: 0.5;
		rebalancingStrategy: #none;
		rollbackOnFailure: false
]

{ #category : 'factory' }
ResiliencyPolicyFactory >> createGracefulDegradationPolicy [
	"Dégradation gracieuse: continue avec moins de drones jusqu'au seuil"
	^ ResiliencyPolicy new
		policyName: 'GracefulDegradation';
		description: 'Graceful degradation: continue with fewer drones until threshold';
		spareDroneActivationMode: #lazy;
		failureThreshold: 0.3;
		rebalancingStrategy: #redistribute;
		rollbackOnFailure: false
]

{ #category : 'factory' }
ResiliencyPolicyFactory >> createRedundancyPolicy [
	"Redondance complète: activation immédiate des spares, pas de dégradation"
	^ ResiliencyPolicy new
		policyName: 'Redundancy';
		description: 'Complete redundancy: activate spares immediately, no degradation';
		spareDroneActivationMode: #immediate;
		failureThreshold: 0.0;
		rebalancingStrategy: #redistribute;
		rollbackOnFailure: false
]
