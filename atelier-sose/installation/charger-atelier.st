| bundle project undeclared |
bundle := (OSEnvironment current at: 'SOSE_ATELIER_BUNDLE') asFileReference.
project := bundle parent.
undeclared := Undeclared keys asSet.
CodeImporter evaluateFileNamed: (project / 'migrer-macro.st') fullName.
CodeImporter evaluateFileNamed: (bundle / 'charger-fraicheur.st') fullName.
CodeImporter evaluateFileNamed: (bundle / 'preparer-terrain-portable.st') fullName.
MCPackageLoader installSnapshot:
    (TonelReader on: project / 'src' fileName: 'SoSe-Atelier-UI') snapshot.
(Undeclared keys asSet difference: undeclared) ifNotEmpty: [ :added |
    Error signal: 'Références sans définition dans l’atelier ', added printString ].
!
