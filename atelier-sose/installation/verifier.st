| example simulator replay id view directory editor |
example := SoSeAtelier vercors.
simulator := example simulate.
simulator history size = 141 ifFalse: [ Error signal: 'Historique Vercors incomplet' ].
replay := example replay.
id := simulator history first drones first id.
replay displayOptions at: #focusDrone put: id.
view := (replay frameReaderFor: simulator history every: 5) value.
view asForm.
((view instVarNamed: 'focus') at: #id) = id
    ifFalse: [ Error signal: 'Incrustation Vercors indisponible' ].
directory := FileLocator temp / ('controle-sose-', UUID new asString).
[
    editor := replay exportTimedHistory: (simulator history first: 3) every: 2
        into: directory rateAt: [ :step :position | 20 ].
    ((editor / '0000.png') isFile and: [ (editor / 'lecture.ffconcat') isFile ])
        ifFalse: [ Error signal: 'Export Vercors incomplet' ]
] ensure: [ directory ensureDeleteAll ].
(PreparerTerrain respondsTo: #polygone:sortie:options:)
    ifFalse: [ Error signal: 'Préparateur MNT absent' ].
Stdio stdout nextPutAll: 'Vercors: 141 etats, incrustation et export PNG/ffconcat OK'; lf.
(OSEnvironment current at: 'SOSE_ATELIER_ACTION' ifAbsent: [ '' ]) = 'depuis-git' ifTrue: [
    | sose isse |
    sose := FullAppMacroReplay soSe.
    isse := FullAppMacroReplay isSeWithSeedIndex: 10.
    (sose history size = 1501 and: [ isse history size = 1501 ])
        ifFalse: [ Error signal: 'Historique macro incomplet' ].
    directory := FileLocator temp / ('controle-isse-', UUID new asString).
    [
        (MacroExporter directoryName: directory fullName) visit: isse.
        (directory / 'parameters.csv') isFile ifFalse: [ Error signal: 'CSV ISSe indisponible' ]
    ] ensure: [ directory ensureDeleteAll ].
    Stdio stdout nextPutAll: 'SoSe et ISSe: 1501 etats et export CSV ISSe OK'; lf ].
!
