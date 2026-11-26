!PreparerTerrain methodsFor: 'systeme'!
shell: commande
    "Les outils GDAL utilisent les bibliothèques du système."
    ^ LibC system: '/usr/bin/env -u LD_LIBRARY_PATH -u DYLD_LIBRARY_PATH ', commande
! !
