;Copyright (C) 2004-2008 John T. Haller of PortableApps.com
;Copyright (C) 2007-2008 Ryan McCue of PortableApps.com

;Website: http://PortableApps.com/WinMergePortable

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

!define PORTABLEAPPNAME "WinMerge Portable"
!define APPNAME "WinMerge"
!define NAME "WinMergePortable"
!define VER "1.6.1.0"
!define WEBSITE "PortableApps.com/WinMergePortable"
!define DEFAULTEXE "WinMergeU.exe"
!define DEFAULTAPPDIR "WinMerge"
!define DEFAULTSETTINGSDIR "settings"
!define LAUNCHERLANGUAGE "English"

;=== Program Details
Name "${PORTABLEAPPNAME}"
OutFile "..\..\${NAME}.exe"
Caption "${PORTABLEAPPNAME} | PortableApps.com"
VIProductVersion "${VER}"
VIAddVersionKey ProductName "${PORTABLEAPPNAME}"
VIAddVersionKey Comments "Allows ${APPNAME} to be run from a removable drive.  For additional details, visit ${WEBSITE}"
VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "PortableApps.com & Contributors"
VIAddVersionKey FileDescription "${PORTABLEAPPNAME}"
VIAddVersionKey FileVersion "${VER}"
VIAddVersionKey ProductVersion "${VER}"
VIAddVersionKey InternalName "${PORTABLEAPPNAME}"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${NAME}.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""

;=== Runtime Switches
CRCCheck On
WindowIcon Off
SilentInstall Silent
AutoCloseWindow True
RequestExecutionLevel user

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard NSIS)
!include Registry.nsh
!include FileFunc.nsh
!insertmacro GetRoot

;(Custom)
!include GetParameters.nsh
!include GetWindowsVersion.nsh
!include ReplaceInFile.nsh
!include StrRep.nsh
;!include "MUI.nsh"

;=== Program Icon
Icon "..\..\App\AppInfo\appicon.ico"

;=== Icon & Stye ===
;!define MUI_ICON "..\..\App\AppInfo\appicon.ico"

;=== Languages
;!insertmacro MUI_LANGUAGE "${LAUNCHERLANGUAGE}"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\${LAUNCHERLANGUAGE}.nlf"
!include PortableApps.comLauncherLANG_${LAUNCHERLANGUAGE}.nsh

Var PROGRAMDIRECTORY
Var SETTINGSDIRECTORY
Var ADDITIONALPARAMETERS
Var EXECSTRING
Var SECONDARYLAUNCH
Var DISABLESPLASHSCREEN
Var FAILEDTORESTOREKEY
Var WINDOWSVERSION
Var MISSINGFILEORPATH
Var APPLANGUAGE


Section "Main"
	;=== Check if already running
	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${NAME}") i .r1 ?e'
	Pop $0
	StrCmp $0 0 CheckINI
		StrCpy $SECONDARYLAUNCH "true"

	CheckINI:
		ReadINIStr $ADDITIONALPARAMETERS "$EXEDIR\${NAME}.ini" "${NAME}" "AdditionalParameters"
		ReadINIStr $DISABLESPLASHSCREEN "$EXEDIR\${NAME}.ini" "${NAME}" "DisableSplashScreen"
		StrCpy $PROGRAMDIRECTORY "$EXEDIR\App\${DEFAULTAPPDIR}"
		StrCpy $SETTINGSDIRECTORY "$EXEDIR\Data\settings"

		IfFileExists "$PROGRAMDIRECTORY\${DEFAULTEXE}" FoundProgramEXE

	;NoProgramEXE:
		;=== Program executable not where expected
		StrCpy $MISSINGFILEORPATH ${DEFAULTEXE}
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Abort

	FoundProgramEXE:
		;=== Check if running
		StrCmp $SECONDARYLAUNCH "true" GetPassedParameters
		FindProcDLL::FindProc "WinMergeU.exe"
		StrCmp $R0 "1" WarnAnotherInstance
		FindProcDLL::FindProc "WinMerge.exe"
		StrCmp $R0 "1" WarnAnotherInstance DisplaySplash

	WarnAnotherInstance:
		MessageBox MB_OK|MB_ICONINFORMATION `$(LauncherAlreadyRunning)`
		Abort

	DisplaySplash:
		StrCmp $DISABLESPLASHSCREEN "true" CheckWindowsVersion
			;=== Show the splash screen while processing registry entries
			InitPluginsDir
			File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
			newadvsplash::show /NOUNLOAD 1400 100 0 -1 /L $PLUGINSDIR\splash.jpg

	CheckWindowsVersion:
		Call GetWindowsVersion
		Pop $WINDOWSVERSION
		StrCpy $WINDOWSVERSION $WINDOWSVERSION 2
		StrCmp $WINDOWSVERSION '95' UseANSIEXE
		StrCmp $WINDOWSVERSION '98' UseANSIEXE
		StrCmp $WINDOWSVERSION 'ME' UseANSIEXE

	;UseUnicodeEXE:
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\WinMergeU.exe"`
		Goto AdjustSettings
	
	UseANSIEXE:
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\WinMerge.exe"`

	AdjustSettings:
		${GetRoot} $EXEDIR $0
		ReadINIStr $1 "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter"
		StrCmp $1 "" StoreCurrentDriveLetter
		StrCmp $1 $0 GetPassedParameters
		IfFileExists "$SETTINGSDIRECTORY\WinMerge.reg" "" StoreCurrentDriveLetter
		${ReplaceInFile} "$SETTINGSDIRECTORY\WinMerge.reg" "$1\\" "$0\\"
		Delete "$SETTINGSDIRECTORY\WinMerge.reg.old"

	StoreCurrentDriveLetter:
		WriteINIStr "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter" "$0"

	GetPassedParameters:
		;=== Get any passed parameters
		Call GetParameters
		Pop $0
		StrCmp "'$0'" "''" AdditionalParameters
		StrCpy $EXECSTRING `$EXECSTRING $0`

	AdditionalParameters:
		StrCmp $ADDITIONALPARAMETERS "" SettingsDirectory

		;=== Additional Parameters
		StrCpy $EXECSTRING `$EXECSTRING $ADDITIONALPARAMETERS`

	SettingsDirectory:
		;=== Set the settings directory if we have a path
		IfFileExists "$SETTINGSDIRECTORY\*.*" RegistryBackup
			CreateDirectory $SETTINGSDIRECTORY

	RegistryBackup:
		StrCmp $SECONDARYLAUNCH "true" LaunchAndExit
		;=== Backup the registry
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\Thingamahoochie-BackupByWinMergePortable" $R0
		StrCmp $R0 "0" RestoreSettings
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\Thingamahoochie" $R0
		StrCmp $R0 "-1" RestoreSettings
		${registry::MoveKey} "HKEY_CURRENT_USER\Software\Thingamahoochie" "HKEY_CURRENT_USER\Software\Thingamahoochie-BackupByWinMergePortable" $R0
		Sleep 100

	RestoreSettings:
		IfFileExists "$SETTINGSDIRECTORY\WinMerge.reg" "" LaunchNow

	;RestoreTheKey:
		IfFileExists "$WINDIR\system32\reg.exe" "" RestoreTheKey9x
			nsExec::ExecToStack `"$WINDIR\system32\reg.exe" import "$SETTINGSDIRECTORY\WinMerge.reg"`
			Pop $R0
			StrCmp $R0 '0' GetAppLanguage ;successfully restored key
	RestoreTheKey9x:
		${registry::RestoreKey} "$SETTINGSDIRECTORY\WinMerge.reg" $R0
		StrCmp $R0 '0' GetAppLanguage ;successfully restored key
		StrCpy $FAILEDTORESTOREKEY "true"
		
	GetAppLanguage:
		ReadEnvStr $APPLANGUAGE "PortableApps.comLocaleID"
		StrCmp $APPLANGUAGE "" LaunchNow ;if not set, move on
		StrCmp $APPLANGUAGE 1033 SetAppLanguage ;English
		StrCmp $APPLANGUAGE 1046 SetAppLanguage ;Portuguese - Brazil
		StrCmp $APPLANGUAGE 1026 SetAppLanguage ;Bulgarian
		StrCmp $APPLANGUAGE 1027 SetAppLanguage ;Catalan
		StrCmp $APPLANGUAGE 2052 SetAppLanguage ;Chinese - Simp.
		StrCmp $APPLANGUAGE 1028 SetAppLanguage ;Chinese - Trad.
		StrCmp $APPLANGUAGE 1051 SetAppLanguage ;Croatian
		StrCmp $APPLANGUAGE 1029 SetAppLanguage ;Czech
		StrCmp $APPLANGUAGE 1030 SetAppLanguage ;Danish
		StrCmp $APPLANGUAGE 1043 SetAppLanguage ;Dutch
		StrCmp $APPLANGUAGE 1036 SetAppLanguage ;French
		StrCmp $APPLANGUAGE 1031 SetAppLanguage ;German
		StrCmp $APPLANGUAGE 1038 SetAppLanguage ;Hungarian
		StrCmp $APPLANGUAGE 1040 SetAppLanguage ;Italian
		StrCmp $APPLANGUAGE 1041 SetAppLanguage ;Japanese
		StrCmp $APPLANGUAGE 1042 SetAppLanguage ;Korean
		StrCmp $APPLANGUAGE 1044 SetAppLanguage ;Norwegian
		StrCmp $APPLANGUAGE 1045 SetAppLanguage ;Polish
		StrCmp $APPLANGUAGE 2070 SetAppLanguage ;Portuguese - Portugal
		StrCmp $APPLANGUAGE 1049 SetAppLanguage ;Russian
		StrCmp $APPLANGUAGE 1051 SetAppLanguage ;Slovak
		StrCmp $APPLANGUAGE 1034 SetAppLanguage ;Spanish
		StrCmp $APPLANGUAGE 1053 SetAppLanguage ;Swedish
		StrCmp $APPLANGUAGE 1055 SetAppLanguage ;Turkish
		Goto LaunchNow ;Language not available, just run
	
	SetAppLanguage:
		${registry::Write} "HKEY_CURRENT_USER\Software\Thingamahoochie\WinMerge\Locale" "LanguageID" $APPLANGUAGE "REG_DWORD" $R0

	LaunchNow:
		Sleep 100
		;=== Set install location
		${registry::Write} "HKEY_CURRENT_USER\Software\Thingamahoochie\WinMerge" "Executable" "$EXEDIR\WinMergePortable.exe" "REG_SZ" $R0
		${registry::Write} "HKEY_CURRENT_USER\Software\Thingamahoochie\WinMerge\Settings" "DisableSplash" "1" "REG_DWORD" $R0
		Sleep 100
		ExecWait $EXECSTRING

	CheckRunning:
		Sleep 1000
		FindProcDLL::FindProc "WinMergeU.exe"
		StrCmp $R0 "1" CheckRunning
		FindProcDLL::FindProc "WinMerge.exe"
		StrCmp $R0 "1" CheckRunning

	;DoneRunning:
		StrCmp $FAILEDTORESTOREKEY "true" SetOriginalKeyBack
		${registry::SaveKey} "HKEY_CURRENT_USER\Software\Thingamahoochie" "$SETTINGSDIRECTORY\WinMerge.reg" "" $0
		Sleep 100

	SetOriginalKeyBack:
		${registry::DeleteKey} "HKEY_CURRENT_USER\Software\Thingamahoochie" $R0
		Sleep 100
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\Thingamahoochie-BackupByWinMergePortable" $R0
		StrCmp $R0 "-1" TheEnd
		${registry::MoveKey} "HKEY_CURRENT_USER\Software\Thingamahoochie-BackupByWinMergePortable" "HKEY_CURRENT_USER\Software\Thingamahoochie" $R0
		Sleep 100
		Goto TheEnd

	LaunchAndExit:
		Exec $EXECSTRING

	TheEnd:
		${registry::Unload}
		newadvsplash::stop /WAIT
SectionEnd