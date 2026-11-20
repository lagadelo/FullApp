| directory frames fps input |
frames := (OSEnvironment current at: 'DRONE_DEMO_FRAMES' ifAbsent: [ '160' ]) asInteger.
input := OSEnvironment current at: 'DRONE_DEMO_SURFACE' ifAbsent: [ nil ].
fps := 20.
directory := 'frames' asFileReference.
frames > 0 ifFalse: [ Error signal: 'DRONE_DEMO_FRAMES doit être positif' ].
input
    ifNil: [ #(ville montagne) do: [ :scene |
        DronePerceptionDemo new renderScene: scene in: directory / scene asString frames: frames fps: fps ] ]
    ifNotNil: [ DronePerceptionDemo new
        surfaceFromCsv: input asFileReference;
        renderScene: #surface in: directory / 'surface' frames: frames fps: fps ].
