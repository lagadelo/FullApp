| resources configuration simulator observations |
SoSeAtelierPresenter isClass ifFalse: [ Error signal: 'Interface Atelier indisponible' ].
resources := SoSeAtelierResources directory.
((resources / 'cartographie' / 'index.html') isFile
    and: [ SoSeAtelierResources examples notEmpty ]) ifFalse: [
        Error signal: 'Ressources géographiques absentes à côté de l’image' ].
Stdio stdout nextPutAll: 'Atelier Spec et ressources des terrains OK'; lf.
configuration := SoSeAtelierParameters exampleComparison.
configuration perceptionMode: #bearing; ticks: 30.
simulator := configuration run.
observations := simulator evaluateMetrics history.
((simulator history size = 31 and: [ observations allSatisfy: [ :each | each directPerceptionRatio = 0 ] ])
    and: [ observations anySatisfy: [ :each | each angularPerceptionRatio > 0 ] ]) ifFalse: [
        Error signal: 'Exemple headless sans mesure de distance indisponible' ].
Stdio stdout nextPutAll: 'Simulation headless sans mesure de distance OK'; lf.
configuration at: #maxDate put: 2.
simulator := configuration run.
((simulator isKindOf: MacroSimulatorWithFreshness) and: [
    simulator current freshPassages notEmpty and: [
        simulator evaluateMetrics history last respondsTo: #freshnessRuptureCount ] ])
    ifFalse: [ Error signal: 'Suivi de fraîcheur absent' ].
Stdio stdout nextPutAll: 'Fenêtre de passages et métriques de fraîcheur OK'; lf.
!
