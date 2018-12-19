#!/bin/sh
####################################
# Main functions here              #
####################################
case_3(){
	if test "$2" = 'keepCerts' ; then
    	KCERTS=true
		UPGRADE="$3"
		# ./$UPGRADESH "$3"
	fi

	if test "$3" = 'keepCerts' ; then
		KCERTS=true
		UPGRADE="$2"
		# ./$UPGRADESH "$2"
	fi
	
	if !$KCERTS ; then
		removeCerts
	fi

	./$UPGRADESH "$UPGRADE"

	cleanUpgradeScript
}

case_2(){
	if test "$2" = 'keepCerts' ; then
    	cleanAllUpgradeFiles
    else
		removeCerts	
	    ./$UPGRADESH "$2"
		cleanUpgradeScript
	fi
}

case_1(){
	removeCerts
	cleanAllUpgradeFiles	
}

cleanAllUpgradeFiles(){
	# clean up other upgrade files
	echo "Removing unnecessary upgrade files ..."
	rm $JARTORUN 
	rm $UPGRADEBAT 
	cleanUpgradeScript
}

cleanUpgradeScript(){
	rm $UPGRADESH 
	clean
}

# clean final build script 
clean(){
	rm $BUILDSH 
	echo "Done!"
	FINISH=true
}
removeCerts(){
	rm -rf ${CONFIG}/${CERTS}
}
####################################
# Main body of script starts here  #
####################################
# Make plugin case insensitive
PLUGIN=$(echo $1 | tr '[:upper:]' '[:lower:]')
ADAPTERS='adapters'
PLUGINFLDR=gateway-$PLUGIN
CONFIGINI=config.ini
CONFIG=config
CERTS=certificates
CONFIGURATION=configuration
GATEWAYSH=gateway.sh
GATEWAYBAT=gateway.bat
BUILDSH=build.sh
BUILDBAT=build.bat

# upgrade script
JARTORUN=gateway-upgrade.jar
UPGRADEBAT=upgrade.bat
UPGRADESH=upgrade.sh
KCERTS=false
FINISH=false

# at least gateway type
if [ $# -eq 0 ] ; then
    exit 0
fi

# common tasks
cp -rf ${ADAPTERS}/${PLUGINFLDR}/. .

echo "... Plugin configuration ..."
cat ${CONFIG}/${CONFIGINI} >> ${CONFIGURATION}/${CONFIGINI}
rm ${CONFIG}/${CONFIGINI}
mv ${CONFIG}/${GATEWAYSH} ${GATEWAYSH}
mv ${CONFIG}/${GATEWAYBAT} ${GATEWAYBAT}

echo "Removing unnecessary adapters ..." 
rm -R $ADAPTERS 
rm $BUILDBAT 

#echo "Start parameters check"
# steps relative to different parameters
if [ ! -z "$3" ] ; then
	echo $1 $2 $3
	case_3 "$1" "$2" "$3"
fi

if $FINISH ; then
	exit 0;
fi

if [ ! -z "$2" ] ; then
	echo $1 $2
	case_2 "$1" "$2"
fi

if $FINISH ; then
	exit 0;
fi


echo $1
case_1

