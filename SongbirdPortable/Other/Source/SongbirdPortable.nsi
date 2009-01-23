;Copyright 2004-2008 John T. Haller
;Copyright 2008 Ryan McCue

;Website: http://PortableApps.com/SongbirdPortable

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

!define PORTABLEAPPNAME "Songbird Portable"
!define APPNAME "Songbird"
!define NAME "SongbirdPortable"
!define VER "1.6.1.0"
!define WEBSITE "PortableApps.com/SongbirdPortable"
!define DEFAULTEXE "songbird.exe"
!define DEFAULTAPPDIR "songbird"
!define LAUNCHERLANGUAGE "English"

;=== Program Details
Name "${PORTABLEAPPNAME}"
OutFile "..\..\${NAME}.exe"
Caption "${PORTABLEAPPNAME} | PortableApps.com"
VIProductVersion "${VER}"
VIAddVersionKey ProductName "${PORTABLEAPPNAME}"
VIAddVersionKey Comments "Allows ${APPNAME} to be run from a removable drive.  For additional details, visit ${WEBSITE}"
VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "PortableApps.com and contributors"
VIAddVersionKey FileDescription "${PORTABLEAPPNAME}"
VIAddVersionKey FileVersion "${VER}"
VIAddVersionKey ProductVersion "${VER}"
VIAddVersionKey InternalName "${PORTABLEAPPNAME}"
VIAddVersionKey LegalTrademarks "Songbird and related logos are Trademarks of POTI, Inc. PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${NAME}.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""

;=== Runtime Switches
CRCCheck On
;WindowIcon Off
SilentInstall Silent
;AutoCloseWindow True
RequestExecutionLevel user

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard NSIS)
!include FileFunc.nsh
!insertmacro GetRoot
!include Registry.nsh
!insertmacro GetParameters

;(Custom)
!include Attrib.nsh
!include ReplaceInFile.nsh
!include StrRep.nsh

;=== Program Icon
Icon "..\..\App\AppInfo\appicon.ico"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\${LAUNCHERLANGUAGE}.nlf"
!include PortableApps.comLauncherLANG_${LAUNCHERLANGUAGE}.nsh


;=== Variables
Var PROGRAMDIRECTORY
Var SQLITEDIRECTORY
Var PROFILEDIRECTORY
Var SETTINGSDIRECTORY
Var MUSICDIR
Var ADDITIONALPARAMETERS
Var ALLOWMULTIPLEINSTANCES
Var SKIPCOMPREGFIX
Var EXECSTRING
Var PROGRAMEXECUTABLE
Var INIPATH
Var DISABLESPLASHSCREEN
Var DISABLEINTELLIGENTSTART
Var ISDEFAULTDIRECTORY
Var RUNLOCALLY
Var WAITFORPROGRAM
Var LASTPROFILEDIRECTORY
Var LASTDRIVE
Var CURRENTDRIVE
Var SQLQUERY
Var APPDATAPATH
Var SECONDARYLAUNCH
Var MISSINGFILEORPATH
Var CRASHREPORTSDIREXISTS

Section "Main"
	;=== Setup variables
	ReadEnvStr $APPDATAPATH "APPDATA"

	;=== Find the INI file, if there is one
		IfFileExists "$EXEDIR\${NAME}.ini" "" NoINI
			StrCpy "$INIPATH" "$EXEDIR"

		;=== Read the parameters from the INI file
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "${APPNAME}Directory"
		StrCpy $PROGRAMDIRECTORY "$EXEDIR\$0"
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "SQLiteDirectory"
		StrCpy $SQLITEDIRECTORY "$EXEDIR\$0"
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "ProfileDirectory"
		StrCpy $PROFILEDIRECTORY "$EXEDIR\$0"
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "SettingsDirectory"
		StrCpy $SETTINGSDIRECTORY "$EXEDIR\$0"

		;=== Check that the above required parameters are present
		IfErrors NoINI

		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "AdditionalParameters"
		StrCpy $ADDITIONALPARAMETERS $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "AllowMultipleInstances"
		StrCpy $ALLOWMULTIPLEINSTANCES $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "${APPNAME}Executable"
		StrCpy $PROGRAMEXECUTABLE $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "SkipCompregFix"
		StrCpy $SKIPCOMPREGFIX $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "WaitFor${APPNAME}"
		StrCpy $WAITFORPROGRAM $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DisableSplashScreen"
		StrCpy $DISABLESPLASHSCREEN $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "DisableIntelligentStart"
		StrCpy $DISABLEINTELLIGENTSTART $0
		ReadINIStr $0 "$INIPATH\${NAME}.ini" "${NAME}" "RunLocally"
		StrCpy $RUNLOCALLY $0
		StrCmp $RUNLOCALLY "true" "" CleanUpAnyErrors
		StrCpy $WAITFORPROGRAM "true"
		
	CleanUpAnyErrors:
		;=== Any missing unrequired INI entries will be an empty string, ignore associated errors
		ClearErrors

		;=== Check if default directories
		StrCmp $PROGRAMDIRECTORY "$EXEDIR\App\${DEFAULTAPPDIR}" "" EndINI
		StrCmp $SQLITEDIRECTORY "$EXEDIR\App\SQLite" "" EndINI
		StrCmp $PROFILEDIRECTORY "$EXEDIR\Data\profile" "" EndINI
		StrCpy $SETTINGSDIRECTORY "$EXEDIR\Data\settings" "" EndINI
		StrCpy $ISDEFAULTDIRECTORY "true"
	
	EndINI:
		IfFileExists "$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" FoundProgramEXE NoProgramEXE

	NoINI:
		;=== No INI file, so we'll use the defaults
		StrCpy $ADDITIONALPARAMETERS ""
		StrCpy $ALLOWMULTIPLEINSTANCES "false"
		StrCpy $SKIPCOMPREGFIX "false"
		StrCpy $WAITFORPROGRAM "true"
		StrCpy $PROGRAMEXECUTABLE "${DEFAULTEXE}"
		StrCpy $DISABLESPLASHSCREEN "false"
		StrCpy $DISABLEINTELLIGENTSTART "false"

		IfFileExists "$EXEDIR\App\${DEFAULTAPPDIR}\${DEFAULTEXE}" "" NoProgramEXE
			StrCpy $PROGRAMDIRECTORY "$EXEDIR\App\${DEFAULTAPPDIR}"
			StrCpy $SQLITEDIRECTORY "$EXEDIR\App\SQLite"
			StrCpy $PROFILEDIRECTORY "$EXEDIR\Data\profile"
			StrCpy $SETTINGSDIRECTORY "$EXEDIR\Data\settings"
			StrCpy $ISDEFAULTDIRECTORY "true"
			Goto FoundProgramEXE

	NoProgramEXE:
		;=== Program executable not where expected
		StrCpy $MISSINGFILEORPATH $PROGRAMEXECUTABLE
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Abort
		
	FoundProgramEXE:
;		IfFileExists "$APPDATA\Songbird1\*.*" CheckForCrashReports
;			StrCpy $WAITFORPROGRAM "true"
;			${registry::KeyExists} "HKEY_CURRENT_USER\Software\mozilla.org" $R0
;			StrCmp $R0 "-1" CheckForCrashReports ;=== If it doesn't exist, skip the next line
;			StrCpy $MOZILLAORGKEYEXISTS "true"
;			
;	CheckForCrashReports:
		IfFileExists "$APPDATA\Songbird2\Crash Reports\*.*" "" CheckIfRunning
			StrCpy $CRASHREPORTSDIREXISTS "true"
	
	CheckIfRunning:
		;=== Check if running
		StrCmp $ALLOWMULTIPLEINSTANCES "true" ProfileWork
		FindProcDLL::FindProc "songbird.exe"
		StrCmp $R0 "1" "" ProfileWork
			;=== Already running, check if it is using the portable profile
			IfFileExists "$PROFILEDIRECTORY\parent.lock" "" WarnAnotherInstance
				StrCpy $SECONDARYLAUNCH "true"
				Goto RunProgram
		
	WarnAnotherInstance:
		MessageBox MB_OK|MB_ICONINFORMATION `$(LauncherAlreadyRunning)`
		Abort
	
	ProfileWork:
	;=== Check for an existing profile
	IfFileExists "$PROFILEDIRECTORY\prefs.js" ProfileFound
		;=== No profile was found
		StrCmp $ISDEFAULTDIRECTORY "true" CopyDefaultProfile CreateProfile
	
	CopyDefaultProfile:
		CreateDirectory "$EXEDIR\Data"
		CreateDirectory "$EXEDIR\Data\profile"
		CreateDirectory "$EXEDIR\Data\settings"
		CopyFiles /SILENT $EXEDIR\App\DefaultData\profile\*.* $EXEDIR\Data\profile
		GoTo ProfileFound
	
	CreateProfile:
		IfFileExists "$PROFILEDIRECTORY\*.*" ProfileFound
		CreateDirectory "$PROFILEDIRECTORY"

	ProfileFound:
		IfFileExists "$SETTINGSDIRECTORY\SongbirdPortableSettings.ini" SettingsFound
			CreateDirectory "$SETTINGSDIRECTORY"
			FileOpen $R0 "$SETTINGSDIRECTORY\SongbirdPortableSettings.ini" w
			FileClose $R0
			WriteINIStr "$SETTINGSDIRECTORY\SongbirdPortableSettings.ini" "SongbirdPortableSettings" "SongbirdPortableSettings" "NONE"
			
	SettingsFound:
		;=== Check for read/write
		StrCmp $RUNLOCALLY "true" DisplaySplash
		ClearErrors
		FileOpen $R0 "$PROFILEDIRECTORY\writetest.temp" w
		IfErrors "" WriteSuccessful
			;== Write failed, so we're read-only
			MessageBox MB_YESNO|MB_ICONQUESTION `$(LauncherAskCopyLocal)` IDYES SwitchToRunLocally
			MessageBox MB_OK|MB_ICONINFORMATION `$(LauncherNoReadOnly)`
			Abort
			
	SwitchToRunLocally:
		StrCpy $RUNLOCALLY "true"
		Goto DisplaySplash
	
	WriteSuccessful:
		FileClose $R0
		Delete "$PROFILEDIRECTORY\writetest.temp"
	
	DisplaySplash:
		StrCmp $DISABLESPLASHSCREEN "true" SkipSplashScreen
			;=== Show the splash screen before processing the files
			InitPluginsDir
			File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
			newadvsplash::show /NOUNLOAD 2000 0 0 -1 /L $PLUGINSDIR\splash.jpg

	SkipSplashScreen:
		;=== Run locally if needed (aka Portable Firefox Live)
		StrCmp $RUNLOCALLY "true" "" CompareProfilePath
		RMDir /r "$TEMP\${NAME}\"
		CreateDirectory $TEMP\${NAME}\profile
		CreateDirectory $TEMP\${NAME}\settings
		CreateDirectory $TEMP\${NAME}\program
		CopyFiles /SILENT $PROFILEDIRECTORY\*.* $TEMP\${NAME}\profile
		StrCpy $PROFILEDIRECTORY $TEMP\${NAME}\profile
		CopyFiles /SILENT $PROGRAMDIRECTORY\*.* $TEMP\${NAME}\program
		StrCpy $PROGRAMDIRECTORY $TEMP\${NAME}\program
		Push $TEMP\${NAME}
		Call Attrib

	CompareProfilePath:
		ReadINIStr $LASTPROFILEDIRECTORY "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastProfileDirectory"
		StrCmp $PROFILEDIRECTORY $LASTPROFILEDIRECTORY "" AdjustSettings
			StrCmp $DISABLEINTELLIGENTSTART "true" AdjustSettings
				StrCpy $SKIPCOMPREGFIX "true"

	AdjustSettings:
		ReadINIStr $LASTDRIVE "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter"
		${GetRoot} $EXEDIR $CURRENTDRIVE
		StrCmp $LASTDRIVE "" StoreCurrentDriveLetter
		StrCmp $LASTDRIVE $CURRENTDRIVE RunProgram
		IfFileExists "$PROFILEDIRECTORY\prefs.js" "" CheckMusicExists

		;=== Replace drive letter entries
		${ReplaceInFile} "$PROFILEDIRECTORY\prefs.js" "$LASTDRIVE\\" "$CURRENTDRIVE\\"
		${ReplaceInFile} "$PROFILEDIRECTORY\prefs.js" "$LASTDRIVE/" "$CURRENTDRIVE/"
		Delete "$PROFILEDIRECTORY\prefs.js.old"
		Goto FixDatabase

	CheckMusicExists:
		ReadEnvStr $MUSICDIR "PortableApps.comMusic"
		StrCmp $MUSICDIR "" ManuallyCheckForDocuments
		IfFileExists "$MUSICDIR\*.*" SetDefaultDownloadDir ManuallyCheckForDocuments

		ManuallyCheckForDocuments:
			IfFileExists "$CURRENTDRIVE\Documents\Music\*.*" "" UseRootPath
			StrCpy $MUSICDIR "$CURRENTDRIVE\Documents\Music"
			Goto SetDefaultDownloadDir

		UseRootPath:
			StrCpy $MUSICDIR "$CURRENTDRIVE\"

	SetDefaultDownloadDir:
		CreateDirectory "$SETTINGSDIRECTORY"
		CopyFiles /SILENT "$EXEDIR\App\DefaultData\profile\*.*" "$PROFILEDIRECTORY\"

		;=== Set the download directory before first run
		${ReplaceInFile} "$PROFILEDIRECTORY\prefs.js" "<<PortableApps.comMusic>>" "$MUSICDIR"

	FixDatabase:
		IfFileExists "$PROFILEDIRECTORY\db\main@library.songbirdnest.com.db" "" StoreCurrentDriveLetter

		StrCpy $SQLQUERY "SET content_url = 'file:///$CURRENTDRIVE' || SUBSTR(content_url,11,1024) WHERE content_url LIKE 'file:///$LASTDRIVE%'"

		;=== Replace in the main db
		nsExec::Exec `"$SQLITEDIRECTORY\sqlite3.exe" "$PROFILEDIRECTORY\db\main@library.songbirdnest.com.db" "UPDATE media_items $SQLQUERY; UPDATE library_media_item $SQLQUERY;"`
		;=== Replace the path to the web db
		nsExec::Exec `"$SQLITEDIRECTORY\sqlite3.exe" "$PROFILEDIRECTORY\db\web@library.songbirdnest.com.db" "UPDATE library_media_item $SQLQUERY;"`

	StoreCurrentDriveLetter:
		WriteINIStr "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter" "$CURRENTDRIVE"

	RunProgram:
		StrCmp $SKIPCOMPREGFIX "true" GetPassedParameters

		;=== Delete component registry to ensure compatibility with all extensions
		Delete $PROFILEDIRECTORY\compreg.dat

	GetPassedParameters:
		;=== Get any passed parameters
		${GetParameters} $0
		StrCmp "'$0'" "''" "" LaunchProgramParameters

		;=== No parameters
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" -profile "$PROFILEDIRECTORY"`
		Goto CheckMultipleInstances

	LaunchProgramParameters:
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" -profile "$PROFILEDIRECTORY" $0`

	CheckMultipleInstances:
		StrCmp $ALLOWMULTIPLEINSTANCES "true" "" AdditionalParameters
		StrCpy $EXECSTRING `$EXECSTRING -no-remote`

	AdditionalParameters:
		StrCmp $ADDITIONALPARAMETERS "" PluginsEnvironment

		;=== Additional Parameters
		StrCpy $EXECSTRING `$EXECSTRING $ADDITIONALPARAMETERS`

	PluginsEnvironment:
		;=== Set the plugins directory if we have a path
		StrCmp $PLUGINSDIRECTORY "" LaunchNow
		IfFileExists "$PLUGINSDIRECTORY\*.*" "" LaunchNow
		System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("MOZ_PLUGIN_PATH", "$PLUGINSDIRECTORY").r0'

	LaunchNow:
		StrCmp $SECONDARYLAUNCH "true" StartProgramAndExit
		StrCmp $WAITFORPROGRAM "true" "" StartProgramAndExit
		SetOutPath $PROGRAMDIRECTORY
		ExecWait $EXECSTRING

	CheckRunning:
		Sleep 2000
		StrCmp $ALLOWMULTIPLEINSTANCES "true" TheEnd
		FindProcDLL::FindProc "songbird.exe"
		StrCmp $R0 "1" CheckRunning CleanupRunLocally
	
	StartProgramAndExit:
		SetOutPath $PROGRAMDIRECTORY
		Exec $EXECSTRING
		Goto TheEnd
	
	CleanupRunLocally:
		StrCmp $RUNLOCALLY "true" "" CheckIfRemoveLocalFiles
		RMDir /r "$TEMP\${NAME}\"

	CheckIfRemoveLocalFiles:
		FindProcDLL::FindProc "songbird.exe"
		Pop $R0
		StrCmp $R0 "1" CheckIfRemoveLocalFiles RemoveLocalFiles

	RemoveLocalFiles:
		StrCmp $CRASHREPORTSDIREXISTS "true" RemoveLocalFiles2
		RMDir /r "$APPDATA\Songbird2\Crash Reports\"
		
	RemoveLocalFiles2:
		RMDir "$APPDATA\Songbird2\" ;=== Will only delete if empty (no /r switch)
		RMDir "$LOCALAPPDATA\Songbird2\Profiles\" ;=== Will only delete if empty (no /r switch)
		RMDir "$LOCALAPPDATA\Songbird2\" ;=== Will only delete if empty (no /r switch)

	TheEnd:
		${registry::Unload}
		newadvsplash::stop /WAIT
SectionEnd