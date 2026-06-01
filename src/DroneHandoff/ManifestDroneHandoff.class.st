"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestDroneHandoff',
	#superclass : 'PackageManifest',
	#category : 'DroneHandoff-Manifest',
	#package : 'DroneHandoff',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestDroneHandoff class >> ruleCascadedNextPutAllsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'DroneHandoffSimulation class' #weepMean:from:to:steps: #true)) #'2026-05-29T08:15:01.089854+02:00') #(#(#RGPackageDefinition #(#DroneHandoff)) #'2026-05-29T08:23:55.406234+02:00') )
]

{ #category : 'code-critics' }
ManifestDroneHandoff class >> ruleCodeCruftLeftInMethodsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'DroneHandoffSimulation class' #weepMean:from:to:steps: #true)) #'2026-05-29T08:15:17.993154+02:00') )
]

{ #category : 'code-critics' }
ManifestDroneHandoff class >> ruleModifiesCollectionRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'DroneHandoffSimulation class' #scenarioNetworkDegraded #true)) #'2026-05-29T07:45:52.842436+02:00') )
]

{ #category : 'code-critics' }
ManifestDroneHandoff class >> ruleStringConcatenationRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGPackageDefinition #(#DroneHandoff)) #'2026-05-29T08:24:11.173042+02:00') )
]
