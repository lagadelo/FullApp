| project packageDirectory |
project := (OSEnvironment current at: 'SOSE_ATELIER_RESOURCES'
	ifAbsent: [ (OSEnvironment current at: 'SOSE_ATELIER_BUNDLE') asFileReference parent fullName ]) asFileReference.
(MacroSimulatorParameters instVarNames includes: 'maxDate') ifFalse: [
	MacroSimulatorParameters addInstVarNamed: 'maxDate' ].
packageDirectory := project / 'installation' / 'fraicheur'.
MCPackageLoader installSnapshot:
	(TonelReader on: packageDirectory fileName: 'DroneSystem-Macro') snapshot.
!
