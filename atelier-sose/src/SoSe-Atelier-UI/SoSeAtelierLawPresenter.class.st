Class {
	#name : 'SoSeAtelierLawPresenter',
	#superclass : 'SoSeAtelierFormPresenter',
	#instVars : [ 'laws', 'list', 'nameField', 'code', 'selected', 'updating', 'onChoice', 'feedback' ],
	#category : 'SoSe-Atelier-UI'
}

{ #category : 'initialization' }
SoSeAtelierLawPresenter >> initializePresenters [
	super initializePresenters.
	updating := false.
	onChoice := [ :choices :id | ].
	list := self newDropList display: [ :law | law label ]; yourself.
	nameField := self newTextInput.
	code := self newCode beForScripting; lineNumbers: true; yourself.
	feedback := self newLabel label: 'Le bloc reçoit les écarts locaux et renvoie une consigne en m/tik.'; yourself.
	list whenSelectedItemChangedDo: [ :law |
		(updating not and: [ law notNil ]) ifTrue: [ self saveDraft. self showLaw: law ] ].
	self loadLaws: SoSeAtelierCommandLaw presets
]

{ #category : 'layout' }
SoSeAtelierLawPresenter >> defaultLayout [
	^ self column
		add: list height: 30;
		add: nameField height: 30;
		add: (SpBoxLayout newLeftToRight spacing: 5;
			add: (self newButton label: 'Utiliser'; action: [ self validateAndChoose ]; yourself);
			add: (self newButton label: 'Nouvelle'; action: [ self newLaw ]; yourself);
			add: (self newButton label: 'Dupliquer'; action: [ self duplicateLaw ]; yourself);
			add: (self newButton label: 'Retirer'; action: [ self removeLaw ]; yourself);
			add: (self newButton label: 'Préréglages'; action: [ self addPresets ]; yourself);
			yourself) height: 30;
		add: code;
		add: feedback height: 26;
		yourself
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> onChoice: block [
	onChoice := block
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> choices [
	^ laws collect: [ :law | law id -> law label ]
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> lawWithId: policy [
	self saveDraft.
	^ (laws detect: [ :law | law id = policy ] ifNone: [
		self error: 'Choisis une loi dans l’onglet Simulation.' ]) copy
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> snapshot [
	self saveDraft.
	^ laws collect: #copy
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> showLawWithId: identifier [
	self refreshSelecting: (laws detect: [ :law | law id = identifier ] ifNone: [ laws first ])
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> loadLaws: collection [
	laws := collection asOrderedCollection.
	self refreshSelecting: laws first.
	onChoice value: self choices value: nil
]

{ #category : 'catalogue' }
SoSeAtelierLawPresenter >> refreshSelecting: law [
	updating := true.
	[ list items: laws copy; selectItem: law ] ensure: [ updating := false ].
	self showLaw: law
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> saveDraft [
	selected ifNotNil: [
		selected label: (nameField text asString trimBoth ifEmpty: [ selected label ]) source: code text asString ]
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> showLaw: law [
	selected := law.
	nameField text: law label.
	code text: law source
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> validateAndChoose [
	self saveDraft.
	[ selected compileBlock ] on: Error do: [ :error | self inform: error messageText. ^ self ].
	self refreshSelecting: selected.
	onChoice value: self choices value: selected id.
	feedback label: ('Loi active dans Simulation · ', selected label)
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> newLaw [
	self addLawNamed: 'Nouvelle loi' source: '[ :local | local currentSpeed ]'
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> duplicateLaw [
	self saveDraft.
	self addLawNamed: (selected label, ' copie') source: selected source
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> addLawNamed: title source: text [
	| law |
	self saveDraft.
	law := SoSeAtelierCommandLaw id: ('loi-', UUID new asString) asSymbol label: title source: text.
	laws add: law.
	self refreshSelecting: law.
	onChoice value: self choices value: nil
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> removeLaw [
	laws size = 1 ifTrue: [ ^ self inform: 'Ajoute une autre loi pour pouvoir retirer celle-ci.' ].
	laws remove: selected.
	self refreshSelecting: laws first.
	onChoice value: self choices value: nil
]

{ #category : 'editing' }
SoSeAtelierLawPresenter >> addPresets [
	self saveDraft.
	SoSeAtelierCommandLaw presets do: [ :law |
		(laws noneSatisfy: [ :each | each id = law id ]) ifTrue: [ laws add: law ] ].
	self refreshSelecting: selected.
	onChoice value: self choices value: nil
]
