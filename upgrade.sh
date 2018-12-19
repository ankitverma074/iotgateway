#!/bin/sh
####################################
# If some error happens            #
####################################
abort()
{
	if [ $PROCESS -gt 0 ]; then
		echo "An error occurred. Exiting..." >&2
		rm -R $TEMPDIR 2>&1
	fi	
	
	if [ $PROCESS -gt 1 ]; then
		if [ -f ${CONFIG}/${CUSTOMSERVICESFILE} ]; then
			rm ${CONFIG}/${CUSTOMSERVICESFILE}
		fi

		if [ -f ${CONFIGURATION}/config_original.ini ]; then
			mv ${CONFIGURATION}/config_original.ini ${CONFIGURATION}/${CONFIGINI}
		fi
	fi

	if [ $PROCESS -gt 2 ]; then
		while IFS='' read -r line || [[ -n "$line" ]]; do
		    rm ${PLUGINSDIR}/${line}
		done < "$CUSTOMSERVICE"
	fi
    exit 1
}

trap 'abort' 0

####################################
# Main functions here              #
####################################
### Copy plugins installed in old gateway version to temp\plugins folder - step 1 for upgrade
copyPlugins(){
	mkdir -p ${TEMPDIR}/${PLUGINSDIR}	
	while IFS='' read -r line || [ -n "$line" ]; do				
		#name == plugin
		if [ -f "${OLDVERSION}/${PLUGINSDIR}/${line}" ]; then			    
	    	cp "${OLDVERSION}/${PLUGINSDIR}/${line}" ${TEMPDIR}/${PLUGINSDIR}/${line}
	   	else 	
	   		#name != plugin	
	   		#name contains jar 
	   		if [ -z "${line##*jar*}" ]; then	
	   			lineRemovedjar=${line%.jar}
	   			cp "${OLDVERSION}/${PLUGINSDIR}/${lineRemovedjar}" ${TEMPDIR}/${PLUGINSDIR}/${line}
	  		else
	  		#name does not have jar 
	  		#plugin has jar add jar to nam
	  			cp "${OLDVERSION}/${PLUGINSDIR}/${line}.jar" ${TEMPDIR}/${PLUGINSDIR}/${line}
			fi			
	    fi
	done < "$CUSTOMSERVICE"
}

### Copy current and old version config ini to temp folder - step 2 for upgrade
copyConfigIni(){ 
	echo "Custom Services Configuration files ..." >&2
	cp "${OLDVERSION}/${CONFIGURATION}/${CONFIGINI}" ${TEMPDIR}/config_old.ini
	cp ${CONFIGURATION}/${CONFIGINI} ${TEMPDIR}/${CONFIGINI}
}

### Get Bundle-Names from manifest files for every plugin copied in temp\plugin folder - step 3 for upgrade
getBundleNames(){
	echo "Custom Services list ..." >&2
	cp "$CUSTOMSERVICE" ${TEMPDIR}/${CUSTOMSERVICESTOCOPYFILE}
}

### Run jar that creates the merged config ini - step 4 for upgrade
runJar(){
	MYPWD=${PWD}
	java -jar $JARTORUN "$MYPWD"
}

### Copy merged config ini to configuration dir and copy every plugin in temporary plugin folder to plugin - step 5 for upgrade
copyFinalToRightPlace(){
	echo "Finalizing Services to new gateway installation ..." >&2
	PROCESS=2
	
	mv ${CONFIGURATION}/${CONFIGINI} ${CONFIGURATION}/config_original.ini
	cp ${TEMPDIR}/config_new.ini ${CONFIGURATION}/${CONFIGINI}
	cp ${TEMPDIR}/${CUSTOMSERVICESTOCOPYFILE} ${CONFIG}/${CUSTOMSERVICESFILE}


	PROCESS=3
	while IFS='' read -r line || [ -n "$line" ]; do
			# echo "Copy Custom Service to new installation: $line"
		    cp ${TEMPDIR}/${PLUGINSDIR}/${line} ${PLUGINSDIR}/${line} 
	done < "$CUSTOMSERVICE"
}

### clean up files and stuff / adapters and stuff 
clean(){
	echo "Removing unnecessary files ..."
	rm -R $TEMPDIR 2>&1
	rm $JARTORUN 2>&1
	rm $UPGRADEBAT 2>&1
}

####################################
# The command line help 		   #
####################################
display_help() {
	echo "usage: upgrade.bat [argument...]" >&2
    echo "argument: [directory]" >&2
    echo "[directory] set the path to gateway version where custom services are installed" >&2
    exit 1  
}

####################################
# Main body of script starts here  #
####################################
PROCESS=0
CONFIGINI=config.ini
CONFIG=config
CONFIGURATION=configuration
CUSTOMSERVICESFILE=customservices.installed
CUSTOMSERVICESTOCOPYFILE=customservices.toCopy
TEMPDIR="temp"
PLUGINSDIR="plugins"
JARTORUN=gateway-upgrade.jar
#METAINF=META-INF
#MANIFEST=$METAINF/MANIFEST.MF 
#WORDTOREMOVE="Bundle-Name:"
UPGRADEBAT=upgrade.bat
UPGRADESH=upgrade.sh

echo "Start of upgrade script ..."
### verify input parameters 
if [ $# -eq 0 ] ; then
    display_help 
    exit 0
fi

OLDVERSION="$1"
CUSTOMSERVICE="${OLDVERSION}/${CONFIG}/${CUSTOMSERVICESFILE}"
#older version
if [ -z "$OLDVERSION" ] ; then
	echo "Gateway upgrade path not specified"
	clean
	exit 0
fi

#check for files
if [ ! -d "$OLDVERSION" ]; then
    echo Error: $OLDVERSION not exsistent, normal build will be executed
    clean
    exit 0
fi

#remove last slashes
OLDVERSION="${OLDVERSION%/}"

if [ ! -f "${OLDVERSION}/${CONFIG}/${CUSTOMSERVICESFILE}" ]; then
   	echo Error: ${OLDVERSION}/${CONFIG}/${CUSTOMSERVICESFILE} not exsistent, normal build will be executed
   	clean
   	exit 0
fi

if [ ! -d "${OLDVERSION}/${PLUGINSDIR}"  ]; then
	echo Error: ${OLDVERSION}/${PLUGINSDIR} not exsistent, normal build will be executed
	clean
	exit 0
fi

if [ ! -f "${OLDVERSION}/${CONFIGURATION}/${CONFIGINI}"   ]; then
	echo Error: ${OLDVERSION}/${CONFIGURATION}/${CONFIGINI} not exsistent, normal build will be executed
	clean
	exit 0
fi


PROCESS=1
echo "Upgrade from: $OLDVERSION starting ..."
set -e 
copyPlugins
copyConfigIni
getBundleNames
runJar
copyFinalToRightPlace
set +e 
clean
echo "Done!"

trap : 0