"
Serveur local du rejeu 3D. Il sert une scène figée et les fichiers Three.js
embarqués. Il communique avec le navigateur sur 127.0.0.1 et possède son
propre port. Le serveur cartographique peut fonctionner en même temps.

    server := SoSeAtelierRenderServer on: scene.
    server open.
    server stop.
"
Class {
	#name : 'SoSeAtelierRenderServer',
	#superclass : 'Object',
	#instVars : [ 'scene', 'server', 'token', 'resources', 'json', 'address' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'instance creation' }
SoSeAtelierRenderServer class >> on: aRenderScene [
	^ self new scene: aRenderScene
]

{ #category : 'initialization' }
SoSeAtelierRenderServer >> scene: aRenderScene [
	scene := aRenderScene.
	^ self
]

{ #category : 'running' }
SoSeAtelierRenderServer >> start [
	| deadline |
	(server notNil and: [ server isListening ]) ifTrue: [ ^ address ].
	resources := SoSeAtelierResources directory / 'visualisation-3d'.
	(resources / 'index.html') isFile ifFalse: [
		self error: 'Indique le dossier contenant visualisation-3d avec SoSeAtelierResources directory:.' ].
	json := scene asJSON.
	token := UUID new asString.
	server := ZnServer on: 0.
	server bindingAddress: #[127 0 0 1]; delegate: self; start.
	deadline := DateAndTime now + 2 seconds.
	[ server isListening not and: [ DateAndTime now < deadline ] ] whileTrue: [
		(Delay forMilliseconds: 20) wait ].
	server isListening ifFalse: [
		self stop.
		self error: 'Le serveur local du rejeu 3D ne démarre pas.' ].
	address := 'http://127.0.0.1:', server port printString, '/', token, '/'.
	^ address
]

{ #category : 'running' }
SoSeAtelierRenderServer >> open [
	| url |
	url := self start.
	WebBrowser openOn: url.
	^ url
]

{ #category : 'running' }
SoSeAtelierRenderServer >> stop [
	server ifNotNil: [ server stop. server := nil ].
	address := nil.
	json := nil
]

{ #category : 'http' }
SoSeAtelierRenderServer >> handleRequest: request [
	| parts path type file response |
	parts := request uri pathSegments.
	(request method = #GET and: [ parts isNotEmpty and: [ parts first = token ] ])
		ifFalse: [ ^ ZnResponse notFound: request uri ].
	path := '/' join: (parts allButFirst reject: [ :segment | segment = $/ ]).
	path = 'scene.json' ifTrue: [
		response := ZnResponse ok: (ZnEntity json: json).
		response headers at: 'Cache-Control' put: 'no-store'.
		^ response ].
	path := path ifEmpty: [ 'index.html' ].
	type := ({
		'index.html' -> 'text/html; charset=utf-8'.
		'viewer.css' -> 'text/css; charset=utf-8'.
		'viewer.js' -> 'text/javascript; charset=utf-8'.
		'vendor/three.module.min.js' -> 'text/javascript'.
		'vendor/OrbitControls.js' -> 'text/javascript'.
		'vendor/LICENSE' -> 'text/plain; charset=utf-8' } asDictionary)
		at: path ifAbsent: [ ^ ZnResponse notFound: request uri ].
	file := resources / path.
	file isFile ifFalse: [ ^ ZnResponse notFound: request uri ].
	^ ZnResponse ok: ((ZnEntity bytes: (file binaryReadStreamDo: [ :stream | stream contents ]))
		contentType: type asZnMimeType; yourself)
]
