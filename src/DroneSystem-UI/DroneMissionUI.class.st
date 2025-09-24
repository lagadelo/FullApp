Class {
	#name : 'DroneMissionUI',
	#superclass : 'ComposableMorph',
	#instVars : [
		'missions',
		'clusters',
		'drones',
		'actions'
	],
	#category : 'DroneSystem-UI',
	#package : 'DroneSystem-UI'
}

{ #category : 'mock' }
DroneMissionUI >> backgroundImage [ 

^RSBitmap newFrom: 'Logo'
              
]

{ #category : 'building' }
DroneMissionUI >> buildActionPanel: builder [
    builder list
        items: actions;
        display: [ :action | action description ].

]

{ #category : 'building' }
DroneMissionUI >> buildClusterPanel: builder [
    builder list
        items: clusters;
        display: [ :cluster | cluster name ].

]

{ #category : 'building' }
DroneMissionUI >> buildDronePanel: builder [
    builder list
        items: drones;
        display: [ :drone | drone uniqueId asString ].


]

{ #category : 'building' }
DroneMissionUI >> buildMissionPanel: builder [
    builder roassal
        extent: 400@300;
        draw: [ :canvas |
            missions do: [ :mission |
                | waypoints poly |
                waypoints := mission waypoints.
                poly := (RSPolygon new points: waypoints) color: Color lightBlue.
                canvas add: poly.
            ].
        ].

]

{ #category : 'building' }
DroneMissionUI >> buildWith: builder [
 
    ^ builder
        window
            title: 'Simulation Drones';
            layout: #vertical;
            add: [ :b | self buildMissionPanel: b ];
"            add: [ :b | self buildClusterPanel: b ];
            add: [ :b | self buildActionPanel: b ];
            add: [ :b | self buildDronePanel: b ];"
            yourself

]

{ #category : 'building' }
DroneMissionUI >> renderDroneListOn: builder [
    builder list
        items: drones;
        display: [ :drone | drone uniqueId asString ]";
        onSelectionChanged: [ :selected |  ]".

]

{ #category : 'building' }
DroneMissionUI >> renderIn: aCanvas [
    "Ajoute un fond de carte bitmap, puis les missions et drones"
    self backgroundImage ifNotNil: [
        | bitmapShape |
        bitmapShape := RSBitmap new
            image: self backgroundImage;
            position: 0@0;
            yourself.
        aCanvas add: bitmapShape.
    ].

              
]

{ #category : 'building' }
DroneMissionUI >> renderOn: builder [
    <spec: #default>
    ^ builder
        window
            title: 'Simulation Drones';
            layout: #horizontal;
            add: [ :b | 
                b roassal
                    extent: 600@400;
                    draw: [ :canvas | self renderIn: canvas ] ];
            add: [ :b | self renderSidePanelOn: b ];
            yourself

]

{ #category : 'building' }
DroneMissionUI >> renderSidePanelOn: builder [
    "Un panneau vertical avec les listes"
    builder verticalLayout
        add: [ :b | b label text: 'Drones'; yourself. self renderDroneListOn: b ];
        "add: [ :b | b label text: 'Clusters'; yourself. self renderClusterListOn: b ];
        add: [ :b | b label text: 'Actions'; yourself. self renderActionListOn: b ];"
        yourself

]

{ #category : 'building' }
DroneMissionUI >> shapesFor: objects [
    ^ objects collect: [ :obj |
        (obj isKindOf: ClusterMission)
            ifTrue: [ | waypoints poly |
                waypoints := obj waypoints.
                poly := (RSPolygon new points: waypoints) color: Color lightBlue.
                poly ]
            ifFalse: [ (obj isKindOf: Drone)
                ifTrue: [ RSCircle new
                    position: obj latitude @ obj longitude;
                    color: (obj isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]);
                    size: 10;
                    yourself ]
                ifFalse: [ nil ] ] ].

]

{ #category : 'visiting' }
DroneMissionUI >> visitClusterMission: obj [
              | waypoints poly |
                waypoints := obj waypoints.
                poly := (RSPolygon new points: waypoints) color: Color lightBlue.
                ^ poly  
]

{ #category : 'visiting' }
DroneMissionUI >> visitDrone:obj [
^ RSCircle new
                    position: obj latitude @ obj longitude;
                    color: (obj isHostile ifTrue: [ Color red ] ifFalse: [ Color green ]);
                    size: 10;
                    yourself 
              
]
