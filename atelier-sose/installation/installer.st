| environment bundle output required data known definitions currentDefinition export report changes originalUndeclared |
environment := OSEnvironment current.
bundle := (environment at: 'SOSE_ATELIER_BUNDLE') asFileReference.
output := (environment at: 'SOSE_ATELIER_OUTPUT') asFileReference.
required := #(MacroSimulator MacroSimulatorExample NeoCSVWriter RSCanvas PerceptionAdapter).
(required reject: [ :name | Smalltalk globals includesKey: name ]) ifNotEmpty: [ :missing |
    Error signal: 'Cette image doit contenir le socle SoSe–ISSe. Classes manquantes ', missing printString ].

data := STON fromString: (bundle / 'mise-a-jour.ston') contents.
known := data at: #known.
definitions := data at: #definitions.
(environment at: 'SOSE_ATELIER_ACTION' ifAbsent: [ '' ]) = 'depuis-git' ifTrue: [
    | publishedDefinitions |
    publishedDefinitions := STON fromString: (bundle / 'compatibilite-fullapp.ston') contents.
    publishedDefinitions keysAndValuesDo: [ :description :versions |
        (known at: description ifAbsentPut: [ OrderedCollection new ]) addAll: versions ] ].
export := [ :name |
    | directory |
    directory := (output / name) ensureCreateDirectory.
    (data at: #packages) do: [ :packageName |
        | package |
        package := MCPackage named: packageName.
        package systemPackage ifNotNil: [
            (TonelWriter on: directory) writeSnapshot: package snapshot ] ] ].
export value: 'sources-avant'.

currentDefinition := [ :definition |
    definition isMethodDefinition
        ifTrue: [ definition actualClass ifNotNil: [ :behavior |
            (behavior compiledMethodAt: definition selector asSymbol ifAbsent: [ nil ])
                ifNotNil: [ :method | method asMCMethodDefinition ] ] ]
        ifFalse: [ definition actualClass ifNotNil: [ :class | class asClassDefinition ] ] ].
changes := OrderedCollection new.
report := output / 'reprise-locale.txt'.
report writeStreamDo: [ :stream |
    stream nextPutAll: 'Définitions locales conservées lors de la reprise'; lf.
    definitions do: [ :definition |
        | current |
        current := currentDefinition value: definition.
        definition = current ifFalse: [
            (current isNil or: [ (known at: definition description ifAbsent: [ #() ]) includes: current ])
                ifTrue: [ changes add: definition ]
                ifFalse: [ stream nextPutAll: definition description printString; lf ] ] ].
    stream lf; print: changes size; nextPutAll: ' définitions à installer'; lf ].

originalUndeclared := Undeclared keys asSet.
MCPackageLoader installSnapshot: (MCSnapshot fromDefinitions: changes).
(Undeclared keys asSet difference: originalUndeclared) ifNotEmpty: [ :added |
    Error signal: 'Références non résolues après reprise ', added printString ].
export value: 'sources-apres'.
Stdio stdout nextPutAll: report basename; lf.
!
