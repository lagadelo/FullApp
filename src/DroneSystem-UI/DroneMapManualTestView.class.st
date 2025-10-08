Class {
	#name : 'DroneMapManualTestView',
	#superclass : 'DroneMapWithOWSView',
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'accessing' }
DroneMapManualTestView class >> boxVertical: aBlock [
    | presenter layout |
    presenter := self newPresenter.
    layout := SpBoxLayout newVertical.
    aBlock value: layout.          "Le block personnalise le layout (add:, spacing:, ...)"
    presenter layout: layout.
    ^ presenter
]

{ #category : 'accessing' }
DroneMapManualTestView class >> openOnSimulation: aSimulation [
    | v |
    v := self new.
    v simulation: aSimulation.
    v etupUI.
    v open.
    ^ v
]

{ #category : 'accessing' }
DroneMapManualTestView >> boxHorizontal: aBlock [
    | presenter myLayout |
    presenter := self newPresenter.
    myLayout := (SpBoxLayout respondsTo: #newLeftToRight)
        ifTrue: [ SpBoxLayout newLeftToRight ]
        ifFalse: [ SpBoxLayout new ].
    aBlock value: myLayout.
    presenter layout: myLayout.
    ^ presenter

]

{ #category : 'accessing' }
DroneMapManualTestView >> boxVertical: aBlock [
    | presenter myLayout |
    presenter := self newPresenter.
    myLayout :=  SpBoxLayout newTopToBottom  .
      
    aBlock value: myLayout.
    presenter layout: myLayout.
    ^ presenter
]

{ #category : 'as yet unclassified' }
DroneMapManualTestView >> buildMainLayout [
    "Construit et retourne le layout principal."
    | leftColumn rightColumn |
    leftColumn := self boxVertical: [ :lay |
        lay
            spacing: 4;
            add: (SpLabelPresenter new label: 'Menu');
            add: mapCanvas ].
    rightColumn := self boxVertical: [ :lay |
        lay
            spacing: 6;
            add: (self buildMiniToolBar);
            add: overlayPanel;
            add: clusterList;
            add: dronesList ].
    ^ (SpBoxLayout respondsTo: #newLeftToRight)
        ifTrue: [
            SpBoxLayout newLeftToRight
                spacing: 8;
                add: leftColumn;
                add: rightColumn;
                yourself ]
        ifFalse: [
            SpBoxLayout new
                orientation: #leftToRight;
                spacing: 8;
                add: leftColumn;
                add: rightColumn;
                yourself ]
]

{ #category : 'rendering' }
DroneMapManualTestView >> buildMiniToolBar [
    ^ SpBoxLayout newHorizontal
        spacing: 4;
        add: (SpButtonPresenter new
            label: 'Overlays';
            action: [ self refreshOverlays ]);
        add: (SpButtonPresenter new
            label: 'All';
            action: [ (self respondsTo: #refreshAll)
                ifTrue: [ self refreshAll ]
                ifFalse: [ self refreshOverlays ] ]);
        yourself
]

{ #category : 'rendering' }
DroneMapManualTestView >> ensureLists [
    clusterList ifNil: [
        clusterList := SpListPresenter new
            headerTitle: 'Clusters';
            items: self initialClusterItems;
            yourself.
        clusterList display: [ :c |
            c
                ifNil: [ '' ]
                ifNotNil: [ (c respondsTo: #clusterId)
                    ifTrue: [ c clusterId printString ]
                    ifFalse: [ c printString ] ] ].
        clusterList whenSelectionChangedDo: [ self onClusterSelectionChanged ] ].
    dronesList ifNil: [
        dronesList := SpListPresenter new
            headerTitle: 'Drones';
            yourself.
        dronesList display: [ :d |
            (d respondsTo: #uniqueId)
                ifTrue: [ d uniqueId printString ]
                ifFalse: [ d printString ] ] ]
]

{ #category : 'rendering' }
DroneMapManualTestView >> ensureMapCanvas [
    mapCanvas ifNotNil: [ ^ mapCanvas ].
    mapCanvas := self newRoassal
        canvas: self buildCanvas;
        yourself.
    ^ mapCanvas
]

{ #category : 'accessing' }
DroneMapManualTestView >> ensureOverlayModel [
    overlayModel ifNil: [
        (Smalltalk includesKey: #DroneOverlayModel)
            ifTrue: [ overlayModel := DroneOverlayModel new ]
            ifFalse: [ overlayModel := Object new ] ]  "placeholder"
]

{ #category : 'accessing' }
DroneMapManualTestView >> ensureOverlayPanel [
   
    | presenter   myLayout |
 	  overlayPanel ifNotNil: [ ^ overlayPanel ].
    "Encapsuler le layout des cases dans un presenter"
    presenter := self newPresenter.
    myLayout := SpBoxLayout newTopToBottom
        spacing: 3;
        add: (SpLabelPresenter new label: 'Overlays');
        add: (self overlayToggle: 'Perception' getter: #showPerceptionRadius setter: #showPerceptionRadius:);
        add: (self overlayToggle: 'Missions'   getter: #showMissionPaths   setter: #showMissionPaths:);
        add: (self overlayToggle: 'Fuel'       getter: #showEnergyBars     setter: #showEnergyBars:);
        add: (self overlayToggle: 'Ammo'       getter: #showAmmoBars       setter: #showAmmoBars:);
        add: (self overlayToggle: 'Hull'       getter: #showClusterHull    setter: #showClusterHull:);
        yourself.
    presenter layout: myLayout.
    overlayPanel := presenter
]

{ #category : 'accessing' }
DroneMapManualTestView >> etupUI [
    "Construit le layout manuel (pas de defaultLayout utilisé)."
 
    | leftColumn rightColumn root |
   self ensureMapCanvas.
    self ensureLists.
    self ensureOverlayPanel.

    leftColumn := self boxVertical: [ :lay |
        lay
            spacing: 4;
            add: (SpLabelPresenter new label: 'Menu');
            add: mapCanvas ].

    rightColumn := self boxVertical: [ :lay |
        lay
            spacing: 6;
            add: (self buildMiniToolBar);
            add: overlayPanel;
            add: clusterList;
            add: dronesList ].
 

    root := SpPresenter new.
root layout:   (SpBoxLayout newLeftToRight
        spacing: 8;
        add: leftColumn;
        add: rightColumn;
        yourself).
self layout: root layout.
    ^ self halt.


 
]

{ #category : 'rendering' }
DroneMapManualTestView >> initialClusterItems [
^simulation allFleets  first clusters copy 
]

{ #category : 'rendering' }
DroneMapManualTestView >> initialize [
    super initialize.
 "   overlayModel ifNil: [
        (Smalltalk includesKey: #DroneOverlayModel)
            ifTrue: [ overlayModel := DroneOverlayModel new ]
            ifFalse: [ overlayModel := nil ] ]."
]

{ #category : 'rendering' }
DroneMapManualTestView >> onClusterSelectionChanged [
    | cluster |
    cluster := clusterList selectedItem.
    dronesList items: (cluster
        ifNil: [ #() ]
        ifNotNil: [ "(cluster respondsTo: #drones)
            ifTrue: [" cluster drones" ]
            ifFalse: [ #() ]" ]).
    "(self respondsTo: #refreshOverlays) ifTrue: [" self refreshOverlays "]"
]

{ #category : 'accessing' }
DroneMapManualTestView >> overlayToggle: label getter: getSel setter: setSel [
    overlayModel ifNil: [ ^ SpLabelPresenter new label: label , ' (no model)' ].
    ^ SpCheckBoxPresenter new
        label: label;
        state: (overlayModel perform: getSel );
        whenChangedDo: [ :state |
            (overlayModel respondsTo: setSel) ifTrue: [ overlayModel perform: setSel with: state ].
            (self respondsTo: #refreshOverlays) ifTrue: [ self refreshOverlays ] ];
        yourself
]

{ #category : 'as yet unclassified' }
DroneMapManualTestView >> setupUI [
    self ensureMapCanvas.
    self ensureLists.
    self ensureOverlayPanel.
    self layout: self buildMainLayout
]
