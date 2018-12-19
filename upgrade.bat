@ECHO off

setlocal enableextensions enabledelayedexpansion

SET CONFIG=config
SET CONFIGINI=config.ini
SET CONFIGURATION=configuration
SET CUSTOMSERVICESFILE=customservices.installed
SET CUSTOMSERVICESTOCOPYFILE=customservices.toCopy
SET TEMPDIR=temp
SET PLUGINSDIR=plugins
SET JARTORUN=gateway-upgrade.jar
SET UPGRADEBAT=upgrade.bat
SET UPGRADESH=upgrade.sh

ECHO Start of script ...
::  check mandatory parameters
IF "%~1"=="" goto display_help
IF "%JAVA_HOME%" == "" (GOTO CASE_noJava)
echo %1
echo %~1

SET OLDVERSION=%~1

SET CUSTOMSERVICE=%OLDVERSION%\%CONFIG%\%CUSTOMSERVICESFILE%

IF NOT EXIST "%OLDVERSION%" goto CASE_NOVERSION
IF NOT EXIST "%OLDVERSION%\%CONFIG%\%CUSTOMSERVICESFILE%" goto CASE_NOCUSTOMSERVICEFILE
IF NOT EXIST "%OLDVERSION%\%PLUGINSDIR%" goto CASE_NOPLUGINSDIR
IF NOT EXIST "%OLDVERSION%\%CONFIGURATION%\%CONFIGINI%" goto CASE_NOCONFIGINI


ECHO Upgrade from %OLDVERSION% starting ...
GOTO copyPlugins

::  Copy plugins installed in old gateway version to temp\plugins folder - step 1 for upgrade
:copyPlugins
	ECHO Custom Services ... 
	mkdir %TEMPDIR%\%PLUGINSDIR%
	IF NOT EXIST %TEMPDIR%\%PLUGINSDIR% goto CASE_NOTEMPFILES 
	IF NOT EXIST "%CUSTOMSERVICE%" goto CASE_NOTEMPFILES 
	
	for /f "usebackq tokens=*" %%a in ("%CUSTOMSERVICE%") do (
		echo bundle=%%a
		IF NOT EXIST "%OLDVERSION%\%PLUGINSDIR%\%%a" goto CASE_NOTEMPFILES 
		COPY "%OLDVERSION%\%PLUGINSDIR%\%%a" %TEMPDIR%\%PLUGINSDIR%\%%a
	)

	GOTO copyConfigIni
	
::  Copy current and old version config ini to temp folder - step 2 for upgrade
:copyConfigIni
	ECHO Custom Services Configuration files ...	
	COPY "%OLDVERSION%\%CONFIGURATION%\%CONFIGINI%" %TEMPDIR%\config_old.ini 
	IF NOT EXIST %TEMPDIR%\config_old.ini  goto CASE_NOCONFIGINISCOPIED
	
	COPY %CONFIGURATION%\%CONFIGINI%  %TEMPDIR%\%CONFIGINI%
	IF NOT EXIST %TEMPDIR%\%CONFIGINI% goto CASE_NOCONFIGINISCOPIED
	GOTO getBundleNames	
	
	
::  Get Bundle-Names from manifest files for every plugin copied in temp\plugin folder - step 3 for upgrade
:getBundleNames
	ECHO Custom Services list ...
	COPY "%CUSTOMSERVICE%" %TEMPDIR%\%CUSTOMSERVICESTOCOPYFILE% 
	IF NOT EXIST %TEMPDIR%\%CUSTOMSERVICESTOCOPYFILE%  goto CASE_NOBUNDLENAMES
	GOTO runJar
		
::  Run jar that creates the merged config ini - step 4 for upgrade
:runJar
	SET MYPWD=%CD%
	start /WAIT java -jar %JARTORUN% "%MYPWD%"
	if errorlevel 1 goto CASE_JAVARUN
	GOTO copyFinalToRightPlace
	

::  Copy merged config ini to configuration dir and copy every plugin in temporary plugin folder to plugin - step 5 for upgrade
:copyFinalToRightPlace
	ECHO Finalizing Services to new gateway installation ...
	:: copy config ini
	REN %CONFIGURATION%\%CONFIGINI% config_original.ini
	IF NOT EXIST %CONFIGURATION%\config_original.ini ( 
		set /A errStr=1
		goto CASE_FINALCOPY 
	)
	
	COPY %TEMPDIR%\config_new.ini %CONFIGURATION%\%CONFIGINI%
	IF NOT EXIST %CONFIGURATION%\%CONFIGINI% ( 
		set /A errStr=2
		goto CASE_FINALCOPY 
	)
	
	:: copy plugins
	::count initial value in plugins
	set cntInit=0
	FOR %%A IN (%PLUGINSDIR%\*) DO set /a cntInit+=1
	::count initial plugins in plugins folder
	echo INITIAL file count in PLUGINS = %cntInit%

	:: count plugins in temp to copy
	set/A cntTemp=0
	for %%A in ( %TEMPDIR%\%PLUGINSDIR%\* ) do set /a cntTemp+=1
	echo File count in temp = %cntTemp%
	
	::do copy 
	copy "%TEMPDIR%\%PLUGINSDIR%" "%PLUGINSDIR%"
			
	::count final plugins in plugins		
	set cntFinal=0
	for %%B in (%PLUGINSDIR%\*) do set /a cntFinal+=1
	echo FINAL file count in PLUGINS = %cntFinal%

	set /A finalresult= %cntFinal%-%cntInit%
	echo Plugins to copy: %cntTemp% ,  Copied: %finalresult%

	 
	IF %cntTemp% NEQ %finalresult% ( 
		set /A errStr=3
		goto CASE_FINALCOPY 
	)
	
	:: copy customservices.installed
	copy %TEMPDIR%\%CUSTOMSERVICESTOCOPYFILE% %CONFIG%\%CUSTOMSERVICESFILE%
	
	IF NOT EXIST "%CONFIG%\%CUSTOMSERVICESFILE%" goto CASE_FINALCOPY

	GOTO clean	

::  clean up files and stuff 
:clean
	ECHO Removing unnecessary files ...
	RMDIR /s /q %TEMPDIR%  > NUL 2>&1
	DEL /s /q %UPGRADESH% > NUL 2>&1
	DEL /s /q %JARTORUN% > NUL 2>&1
	DEL /s /q %UPGRADESH% > NUL 2>&1
::	(goto) 2>NUL & DEL /q %UPGRADEBAT% 
	GOTO end

::  The command line help 		   
:display_help
	ECHO usage: upgrade.bat [argument...]
    ECHO argument: [directory] 
    ECHO [directory] set the path to gateway version where custom services are installed
	Goto end

:: manage errors and restore original files
:CASE_noJava
	ECHO Error: JAVA_HOME not set
	GOTO END_CASE
:CASE_NOVERSION
	Echo Error in Execution %OLDVERSION% not exsitent
	GOTO END_CASE
:CASE_NOCUSTOMSERVICEFILE
	Echo Error in Execution  %OLDVERSION%\%CONFIG%\%CUSTOMSERVICESFILE% not exsitent
	GOTO END_CASE
:CASE_NOPLUGINSDIR
	Echo Error in Execution %OLDVERSION%\%PLUGINSDIR% not exsitent
	GOTO END_CASE
:CASE_NOCONFIGINI
	Echo Error in Execution %OLDVERSION%\%CONFIGURATION%\%CONFIGINI% not exsitent
	GOTO END_CASE
:CASE_NOTEMPFILES
	Echo Error in Execution .... No temp files created
	RMDIR /s /q %TEMPDIR%  > NUL 2>&1
	GOTO END_CASE	
:CASE_NOCONFIGINISCOPIED
	Echo Error in Execution .... no configuration files copied
	RMDIR /s /q %TEMPDIR%  > NUL 2>&1
	GOTO END_CASE		
:CASE_NOBUNDLENAMES
	Echo Error in Execution .... no bundle names available
	RMDIR /s /q %TEMPDIR%  > NUL 2>&1
	GOTO END_CASE
:CASE_JAVARUN
	Echo Error in Execution .... no configuration updates
	RMDIR /s /q %TEMPDIR%  > NUL 2>&1
	GOTO END_CASE	
:CASE_FINALCOPY
	Echo Error in Execution .... %errStr%
	if %errStr% GTR 2 ( for /F "tokens=*" %%A in (%TEMPDIR%\%CUSTOMSERVICESTOCOPYFILE%) do DEL /s /q %PLUGINSDIR%\%%A %%A)	
	if %errStr% GTR 1 ( DEL /s /q %CONFIGURATION%\%CONFIGINI% )
	if %errStr% GTR 1 ( REN %CONFIGURATION%\config_original.ini %CONFIGINI% )
	:: do in any case
	RMDIR /s /q %TEMPDIR%
	GOTO END_CASE	
:END_CASE
GOTO :EOF # return from CALL

:end
ECHO Done!