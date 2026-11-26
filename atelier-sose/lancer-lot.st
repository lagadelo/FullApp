| environment configuration output result resources |
environment := OSEnvironment current.
resources := environment at: 'SOSE_ATELIER_RESOURCES'.
SoSeAtelierResources directory: resources.
configuration := SoSeAtelierParameters readFrom: (environment at: 'SOSE_BATCH_SETTINGS').
output := (environment at: 'SOSE_BATCH_OUTPUT') asFileReference.
result := (environment at: 'SOSE_BATCH_MODE') caseOf: {
	[ 'run' ] -> [ configuration exportInto: output ].
	[ 'compare' ] -> [ configuration runComparisonInto: output ].
	[ 'publication' ] -> [ configuration publicationInto: output ].
	[ 'video' ] -> [ configuration videoInto: output ].
	[ 'terrain' ] -> [
		| terrain |
		terrain := configuration prepareTerrainInto: output.
		configuration writeTo: terrain / 'parametres.json'.
		terrain ] }.
Stdio stdout nextPutAll: result fullName; lf.
