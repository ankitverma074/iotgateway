@ECHO off

SET PLUGIN=%1
SET ADAPTERS=adapters
SET PLUGINFOLDER=gateway-%PLUGIN%
SET CONFIGINI=config.ini
SET CONFIG=config
SET CONFIGURATION=configuration
SET CERTS=certificates
SET GATEWAYSH=gateway.sh
SET GATEWAYBAT=gateway.bat
SET BUILDSH=build.sh
SET BUILDBAT=build.bat

SET JARTORUN=gateway-upgrade.jar
SET UPGRADEBAT=upgrade.bat
SET UPGRADESH=upgrade.sh

::at least gateway type
IF "%1" == "" GOTO end

:: common tasks
ECHO Copying Gateway %PLUGIN% libs ...
XCOPY /YKRSEQ %ADAPTERS%\%PLUGINFOLDER% . > NUL 2>&1

DEL %PLUGINFOLDER% > NUL 2>&1

ECHO ... Plugin configuration ...
TYPE %CONFIG%\%CONFIGINI% >> %CONFIGURATION%\%CONFIGINI%
DEL %CONFIG%\%CONFIGINI%
MOVE %CONFIG%\%GATEWAYSH% . > NUL 2>&1
MOVE %CONFIG%\%GATEWAYBAT% . > NUL 2>&1

ECHO Removing unnecessary adapters ...
DEL /s /q %ADAPTERS% > NUL 2>&1
RMDIR /s /q %ADAPTERS% > NUL 2>&1
DEL /q %BUILDSH% > NUL 2>&1

:: steps relative to different parameters
IF NOT "%~3"=="" goto CASE_3
IF NOT "%~2"=="" goto CASE_2
GOTO CASE_1
 

:CASE_3
SET kCerts=N
	IF "%~2" == "keepCerts" ( 
		set kCerts=Y 
		set upgrade="%~3"
	)
	IF "%~3" == "keepCerts" ( 
		set kCerts=Y
		set upgrade="%~2"
	)
	
	IF %kCerts%==N ( 
		DEL /s /q %CONFIG%\%CERTS% > NUL 2>&1
		RMDIR /s /q %CONFIG%\%CERTS% > NUL 2>&1
	)
	
	call %UPGRADEBAT% %upgrade%
	
	GOTO cleanUpgradeScript

:CASE_2
	IF "%~2" == "keepCerts" GOTO cleanAllUpgradeFiles
	
	::remove certificates
	DEL /s /q %CONFIG%\%CERTS% > NUL 2>&1
	RMDIR /s /q %CONFIG%\%CERTS% > NUL 2>&1
	
	set upgrade="%~2"
	IF NOT "%~2"=="" call %UPGRADEBAT% %upgrade%
	
	GOTO cleanUpgradeScript

:CASE_1
	::remove certificates
	DEL /s /q %CONFIG%\%CERTS% > NUL 2>&1
	RMDIR /s /q %CONFIG%\%CERTS% > NUL 2>&1
	GOTO cleanAllUpgradeFiles	
	
	
:cleanAllUpgradeFiles
	:: clean up other upgrade files
	ECHO Removing unnecessary upgrade files ...
	DEL /s /q %UPGRADESH% > NUL 2>&1
	DEL /s /q %JARTORUN% > NUL 2>&1
	DEL /s /q %UPGRADESH% > NUL 2>&1
	GOTO cleanUpgradeScript
	
:cleanUpgradeScript
	:: clean up upgrade script
	DEL /s /q %UPGRADEBAT% > NUL 2>&1
	GOTO clean

:clean
	:: clean final build script 
	(goto) 2>nul & del "%~f0"	
	
:end
