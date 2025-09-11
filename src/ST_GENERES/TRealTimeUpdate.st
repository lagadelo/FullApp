Trait named: #TRealTimeUpdate
uses: {}
category: 'Simulation-HUD'.

TRealTimeUpdate class >> withOn: aSimulation in: aCanvas
    "Constructeur pratique pour instancier et activer le trait"
    ^ self new
        simulation: aSimulation;
        canvas: aCanvas;
        initializeHUD;
        yourself.

"==== Attributs d’instance ===="
TRealTimeUpdate>>simulation: aSimulation
    simulation := aSimulation.

TRealTimeUpdate>>canvas: aCanvas
    canvas := aCanvas.

TRealTimeUpdate>>initializeHUD
    updateDelay := 500.  "délai initial en ms"
    savedState := nil.
    savedTime := 0.
    self addControlButtons.

"==== Lancement / arrêt de la boucle temps réel ===="
TRealTimeUpdate>>startUpdatingEvery: milliseconds
    self stopUpdating.
    updateProcess := [
        [ true ] whileTrue: [
            (Delay forMilliseconds: milliseconds) wait.
            simulation step.
            self refreshView.
        ].
    ] forkAt: Processor userBackgroundPriority.

TRealTimeUpdate>>stopUpdating
    updateProcess ifNotNil: [
        updateProcess terminate.
        updateProcess := nil
    ].

"==== Rafraîchissement de la vue ===="
TRealTimeUpdate>>refreshView
    "Mettre à jour la vue et l’horloge"
    self updateCanvasWith: simulation.
    timeLabel string: 'Time: ', (simulation instVarNamed: 'time') asString, ' s'.

TRealTimeUpdate>>updateCanvasWith: aSimulation
    "À adapter pour dessiner ton modèle dans la vue"
    canvas shapes do: #remove.
    aSimulation drones do: [:drone |
        | shape |
        shape := RSCircle new size: 8; color: Color blue.
        shape translateTo: drone position.
        canvas add: shape
    ].
    canvas signalUpdate.

"==== HUD et contrôles ===="
TRealTimeUpdate>>addControlButtons
    | hudY hudBackground startIcon pauseIcon stopIcon stepIcon resumeIcon background slider label padding barWidth barHeight pausePopup stopPopup |

    padding := 20.
    barWidth := canvas extent x.
    barHeight := 60.
    hudY := canvas extent y - (barHeight / 2).

    "Fond HUD"
    hudBackground := RSBox new
        size: barWidth @ barHeight;
        color: (Color gray alpha: 0.2);
        yourself.
    hudBackground translateTo: (barWidth / 2) @ hudY.

    "▶️ START"
    startIcon := RSText new
        string: '▶️';
        fontSize: 24;
        color: Color green.
    startIcon translateTo: (padding + 30) @ hudY.
    startIcon @ (RSInteraction onClickDo: [ self startUpdatingEvery: updateDelay ]).

    "⏸️ PAUSE avec menu"
    pauseIcon := RSText new
        string: '⏸️';
        fontSize: 24;
        color: Color yellow.
    pauseIcon translateTo: (padding + 90) @ hudY.

    pausePopup := RSPopup new.
    pausePopup text: 'Pause options:'.
    pausePopup addItem: 'Pause simple' do: [ self stopUpdating ].
    pausePopup addItem: 'Pause + sauvegarde' do: [
        self stopUpdating.
        savedState := simulation copy.
        savedTime := simulation instVarNamed: 'time'.
    ].
    pauseIcon @ pausePopup.

    "⏹️ STOP avec menu"
    stopIcon := RSText new
        string: '⏹️';
        fontSize: 24;
        color: Color red.
    stopIcon translateTo: (padding + 150) @ hudY.

    stopPopup := RSPopup new.
    stopPopup text: 'Stop options:'.
    stopPopup addItem: 'Stop simple' do: [ self stopUpdating ].
    stopPopup addItem: 'Stop + Reset' do: [
        self stopUpdating.
        simulation := SimulationState new.
        self refreshView.
    ].
    stopIcon @ stopPopup.

    "⏭️ STEP"
    stepIcon := RSText new
        string: '⏭️';
        fontSize: 24;
        color: Color orange.
    stepIcon translateTo: (padding + 210) @ hudY.
    stepIcon @ (RSInteraction onClickDo: [
        simulation step.
        self refreshView.
    ]).

    "🔄 RESUME"
    resumeIcon := RSText new
        string: '🔄';
        fontSize: 24;
        color: Color cyan.
    resumeIcon translateTo: (padding + 270) @ hudY.
    resumeIcon @ (RSInteraction onClickDo: [
        savedState ifNotNil: [
            simulation := savedState copy.
            simulation instVarNamed: 'time' put: savedTime.
            self refreshView.
            self startUpdatingEvery: updateDelay.
        ] ifNil: [
            Transcript show: 'Aucun état sauvegardé à reprendre.'; cr.
        ].
    ]).

    "Slider vitesse"
    background := RSBox new size: 200@10; color: (Color gray alpha: 0.4).
    background translateTo: (padding + 480) @ hudY.

    slider := RSCircle new size: 15; color: Color blue.
    slider translateTo: (padding + 380) @ hudY.

    label := RSText new string: 'Delay: ', updateDelay asString, ' ms'; fontSize: 10.
    label translateTo: (padding + 480) @ (hudY + 20).

    slider @ (RSInteraction onDragDo: [:pt |
        | minX maxX newX ratio newDelay |
        minX := (padding + 380).
        maxX := (padding + 580).
        newX := pt x min: maxX max: minX.
        slider translateTo: newX @ hudY.

        ratio := (newX - minX) / (maxX - minX).
        newDelay := 100 + (2000 - 100) * (1 - ratio).
        updateDelay := newDelay asInteger.

        label string: 'Delay: ', updateDelay asString, ' ms'.
    ]).

    "⏱️ Horloge"
    timeLabel := RSText new
        string: 'Time: 0 s';
        fontSize: 12;
        color: Color white.
    timeLabel translateTo: (barWidth - 80) @ hudY.

    "Ajout HUD"
    canvas hudLayer addAll: {
        hudBackground.
        startIcon. pauseIcon. stopIcon. stepIcon. resumeIcon.
        background. slider. label.
        timeLabel
    }.
