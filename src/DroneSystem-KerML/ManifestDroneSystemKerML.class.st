"
KeML Package

├── models/               # Spécifications KerML (4 packages)
│   ├── CoreModel.kerml
│   ├── MissionsModel.kerml
│   ├── SimulationModel.kerml
│   ├── EventsModel.kerml
│   └── README.md
└── pharo/               # Code Pharo et exporteur
    ├── ExportKerMLFromSimulation.st  # Exporteur principal
    ├── ExampleBlock4.st              # Script d'exemple
    ├── InstantiateSampleSystem.st
    ├── README_ExportKerML.md
    └── tests/
        ├── KerMLExporterTest.st
"
Class {
	#name : 'ManifestDroneSystemKerML',
	#superclass : 'PackageManifest',
	#category : 'DroneSystem-KerML-Manifest',
	#package : 'DroneSystem-KerML',
	#tag : 'Manifest'
}
