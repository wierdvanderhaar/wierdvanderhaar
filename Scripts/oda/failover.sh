#!/bin/sh

# Auteur: Arnaud van der Vlies | DBA.nl
# Doel: Failover van de databases in db.txt naar de andere node

#Environment setten
export ORAENV_ASK=NO

#Functies definieren

DoubleCheck() {
        while :
        do
                read -p 'Databases will be stopped, are you sure (yes/no?): ' answer
                case "${answer}" in
                    [yY]|[yY][eE][sS]) exit 0 ;;
                        [nN]|[nN][oO]) exit 1 ;;
                esac
        done
}

#Uitvoeren
echo ""
echo Databases to failover in db.txt
echo ===============================
cat ./db.txt
echo ""
echo To which server you want to failover?
echo =====================================

#Kiezen naar welke host de instance verplaatst moet worden
PS3='Please choose?'
options=("oda01-n1-msd" "oda01-n2-msd" "quit")
select opt in "${options[@]}"
do
	case $opt in
		"oda01-n1-msd")
			echo ""
			node="oda01-n1-msd"
			break
			;;
        	"oda01-n2-msd")
                	echo ""
			node="oda01-n2-msd"
			break
                	;;
		"quit")
			echo "Bye!"
			break
			;;
		*) echo invalid option;;
	esac
done

#Als de variable node niet leeg is worden de databases verplaatst
if [ ! -z "$node" ]
then

#Prompt of het akkoord is dat de databases gestopt worden
	if $( DoubleCheck ); then
	
		echo ""
		echo Failover all databases in db.txt to node $node
		
			while read dbname; do
				if [ ! -z "$dbname" ]
				then
					export ORACLE_SID=$dbname
					. oraenv > /dev/null 2>&1
					echo ""
					echo "**************************************"
					echo  Failover $dbname to $node
					echo "**************************************"
					echo ""
					echo Stopping database $dbname...
					srvctl stop database -d $dbname
					echo Moving instance $dbname...
					srvctl modify database -d $dbname -x $node
					echo Starting database $dbname...
					srvctl start database -d $dbname
					echo Checking status database $dbname...
					srvctl status database -d $dbname
				fi
			done <./db.txt
	
		echo ""
		echo Done!
	else
		echo "Bye!"
	fi

fi

#Environment terugzetten
export ORAENV_ASK=YES

