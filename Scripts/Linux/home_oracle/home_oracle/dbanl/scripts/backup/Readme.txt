orabackup.sh nog testen met aanpassingen in regel 176 en verder (sed ipv tr)
config en logging directory niveau hoger geplaatst script nog aanpassen.

orabackup.sh
Met dit script kunnen Rman back-ups van de Oracle databases gemaakt worden. 

De volgende script parameters zijn beschikbaar:
--all                   : Back-up van alle gestarte instances
-e                      : Komma gescheiden lijst met alle instances die uitgesloten (exclude) worden.
                          Gebruiken i.c.m. --all
-d                      : Komma gescheiden lijst met instances die geback-upt dienen te worden.
                          Gebruiken i.p.v. --all
--online                : Online back-up (default)
--offline               : Offline back-up
                          De database dient vanuit het rman (rcv) script in mount fase gebracht te
                          worden en daarna ook weer geopend.
                          Een offline back-up van een RAC database wordt niet ondersteund
--incremental           : Incrementele back-up
-l                      : Level van de incrementele back-up. Toegestane waarden zijn 0 en 1
                          Gebruiken i.c.m. --incremental
--archivelog            : Archivelog back-up
--clusterdb             : Betreft cluster databases in een RAC
--catalog               : Synchronisatie naar een Rman catalog 
--configfile            : Gebruik van extern configuratie bestand $SCRIPTDIR/config/backup.conf

De onderstaande variabelen dienen vooraf geconfigureerd te worden. Bij gebruik van de '--configfile' parameter is dit in het bestand $SCRIPTDIR/config/backup.conf en anders in het back-up script zelf.

BCKSCRIPTDIR=			 # Default locatie van de back-up (rcv) bestanden
BCKLOGDIR=			 # Default locatie van de back-up logs
BCKPATH=	                 # Default locatie voor de back-up bestanden
LOGRETENTION=                    # Default aantal dagen dat de logs bewaard worden
RMANCATALOG=                     # Default Net Service Name van de Rman catalog
RCATUSER=                        # Default Rman catalog owner
RCATPWD=                         # Password Rman catalog owner

Voorbeelden:
Alle database online back-up (default):		orabackup.sh --all 
Alle databases behalve ORCL:			orabackup.sh --all -e ORCL
Archivelog back-up van alleen ORCL:		orabackup.sh -d ORCL --archivelog
Offlline back-up o.b.v. configuratiebestand:	orabackup.sh -d ORCL --offline --configfile
Incremental level 0:				orabackup.sh -d ORCL --incremental -l 0  
Back-up cluster database:			orabackup.sh --all --clusterdb --online
Gebruik Rman catalog:				orabackup.sh -d ORCL --catalog --configfile
