"Socle macro tiré du commit FullApp sélectionné par atelier.sh."
| environment bundle source packages allowedClasses droneMethods skippedMethods definitions undeclared |
environment := OSEnvironment current.
bundle := (environment at: 'SOSE_ATELIER_BUNDLE') asFileReference.
source := (environment at: 'SOSE_ATELIER_GIT') asFileReference / 'src'.
((#(RSCanvas SpPresenter) allSatisfy: [ :name | Smalltalk globals includesKey: name ])
    and: [ (Smalltalk globals includesKey: #MacroSimulator) not ])
    ifFalse: [ Error signal: 'Indiquer une image Pharo neuve avec Roassal et Spec.' ].
undeclared := Undeclared keys asSet.

packages := #('DroneSystem-Core' 'DroneSystem-Utils' 'DroneSystem-Macro'
    'DroneSystem-Installation' 'Drone-SystemCouplagePerceptionRoassal'
    'PerceptionMission' 'MNT-Generation').
allowedClasses := {
    'DroneSystem-Core' -> #(AbstractDrone Capabilities Drone FleetElement GeoPoint MissionsList Status Waypoint).
    'DroneSystem-Utils' -> #(ConvexHullCalculator Hull).
    'DroneSystem-Installation' -> #(ManifestDroneSystemInstallation) } asDictionary.
droneMethods := #(LandingBase example exampleAngers accept: behavior behavior: canCommunicateWith:
    canPerceive: cluster cluster: destroy distanceToLatitude:longitude:altitude:
    initialize initializeWithId:latitude:longitude:altitude: isDestroyed
    latitude latitude: longitude longitude: moveToLatitude:longitude:altitude:
    position position: setBehavior: type type:).
skippedMethods := {
    #FleetElement -> #(asTarget).
    #MacroSimulator -> #(open).
    #MacroSimulatorExample -> #(example8WithHandoff).
    #PerceptionFacilities -> #(exportFromPath:imagesNamed:from:to:to:) } asDictionary.

definitions := OrderedCollection new.
(Smalltalk globals includesKey: #NeoCSVWriter) ifFalse: [
    definitions addAll: (TonelReader on: bundle / 'dependances' fileName: 'Neo-CSV-Core') snapshot definitions ].
packages do: [ :package |
    (source / package) isDirectory ifFalse: [ Error signal: 'Paquet FullApp manquant ', package ].
    definitions addAll: ((TonelReader on: source fileName: package) snapshot definitions select: [ :definition |
        definition isOrganizationDefinition or: [
            | className |
            className := definition className asSymbol.
            (allowedClasses at: package ifPresent: [ :names | names includes: className ]
                ifAbsent: [ className ~= #MacroSimulatorGUI ]) and: [
                definition isMethodDefinition not or: [
                    | selector |
                    selector := definition selector asSymbol.
                    (className ~= #Drone or: [ droneMethods includes: selector ]) and: [
                        (definition protocol ~= 'handoff') and: [
                            ((skippedMethods at: className ifAbsent: [ #() ]) includes: selector) not ] ] ] ] ] ]) ].

definitions := definitions collect: [ :definition |
    | className |
    definition isOrganizationDefinition ifTrue: [ definition ] ifFalse: [
        className := definition className asSymbol.
        (definition isClassDefinition and: [ className = #MacroSimulatorParameters ]) ifTrue: [
            (definition instVarNames includes: 'hull') ifFalse: [ definition instVarNames: #('hull') ] ].
        definition isMethodDefinition ifFalse: [ definition ] ifTrue: [
            | methodSource |
            methodSource := definition source.
            (#(MacroSimulator MacroSimulatorHybridPerception MacroSimulatorParameters
                MacroSimulatorPatrolExamples) includes: className) ifTrue: [
                    methodSource := (methodSource copyReplaceAll: ' \ ' with: ' \\ ')
                        copyReplaceAll: ' % ' with: ' \\ ' ].
            (className = #PerceptionTerrain and: [ definition selector asSymbol = #readCsv:noData: ]) ifTrue: [
                "Pharo 14 signals a compatibility notification on every send of #trimmed."
                methodSource := methodSource copyReplaceAll: ' trimmed' with: ' trimBoth' ].
            methodSource = definition source ifTrue: [ definition ] ifFalse: [
                MCMethodDefinition
                    className: definition className
                    classIsMeta: definition classIsMeta
                    selector: definition selector
                    category: definition protocol
                    timeStamp: definition timeStamp
                    source: methodSource ] ] ] ].
MCPackageLoader installSnapshot: (MCSnapshot fromDefinitions: definitions).
(Undeclared keys asSet difference: undeclared) ifNotEmpty: [ :added |
    Error signal: 'Références sans définition dans le profil macro ', added printString ].
!
