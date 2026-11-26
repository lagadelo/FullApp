| project |
project := (OSEnvironment current at: 'SOSE_ATELIER_RESOURCES') asFileReference.
CodeImporter evaluateFileNamed: (project / 'installation' / 'charger-fraicheur.st') fullName.
MCPackageLoader installSnapshot:
	(TonelReader on: project / 'src' fileName: 'SoSe-Atelier-UI') snapshot.
!
