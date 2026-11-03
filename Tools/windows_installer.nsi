Unicode True
!include "MUI2.nsh"
!include "x64.nsh"
!include "nsDialogs.nsh"

!ifndef SOURCE_DIR
  !error "Use Tools/package.py to supply SOURCE_DIR"
!endif
!ifndef OUTPUT_FILE
  !error "OUTPUT_FILE is required"
!endif
!ifndef PRODUCT_VERSION
  !error "PRODUCT_VERSION must come from project.godot via Tools/package.py"
!endif

Name "Tribes of Fire"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\TribesOfFire"
InstallDirRegKey HKCU "Software\felipealx\TribesOfFire" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
!ifndef PRODUCT_FILE_VERSION
  !define PRODUCT_FILE_VERSION "0.0.0.0"
!endif
VIProductVersion "${PRODUCT_FILE_VERSION}"
Icon "../Assets/icon.ico"
UninstallIcon "../Assets/icon.ico"
VIAddVersionKey "ProductName" "Tribes of Fire"
VIAddVersionKey "CompanyName" "felipealx"
VIAddVersionKey "FileDescription" "Tribes of Fire per-user installer"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "LegalCopyright" "felipealx"

!define MUI_ABORTWARNING
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "Software\felipealx\TribesOfFire"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"
!define MUI_LANGDLL_ALWAYSSHOW
!define MUI_FINISHPAGE_RUN "$INSTDIR\TribesOfFire.exe"
Var DesktopCheckbox
Var CreateDesktop
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
Page custom OptionsPage OptionsLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Japanese"
LangString DesktopOption ${LANG_PORTUGUESEBR} "Criar atalho na área de trabalho"
LangString DesktopOption ${LANG_ENGLISH} "Create a desktop shortcut"
LangString DesktopOption ${LANG_SPANISH} "Crear un acceso directo en el escritorio"
LangString DesktopOption ${LANG_FRENCH} "Créer un raccourci sur le Bureau"
LangString DesktopOption ${LANG_GERMAN} "Desktop-Verknüpfung erstellen"
LangString DesktopOption ${LANG_JAPANESE} "デスクトップにショートカットを作成"
LangString RequireX64 ${LANG_PORTUGUESEBR} "Tribes of Fire requer Windows de 64 bits."
LangString RequireX64 ${LANG_ENGLISH} "Tribes of Fire requires 64-bit Windows."
LangString RequireX64 ${LANG_SPANISH} "Tribes of Fire requiere Windows de 64 bits."
LangString RequireX64 ${LANG_FRENCH} "Tribes of Fire nécessite Windows 64 bits."
LangString RequireX64 ${LANG_GERMAN} "Tribes of Fire benötigt 64-Bit-Windows."
LangString RequireX64 ${LANG_JAPANESE} "Tribes of Fireには64ビット版Windowsが必要です。"
Function OptionsPage
  !insertmacro MUI_HEADER_TEXT "Tribes of Fire" "$(DesktopOption)"
  nsDialogs::Create 1018
  Pop $0
  ${NSD_CreateCheckbox} 0 10u 100% 20u "$(DesktopOption)"
  Pop $DesktopCheckbox
  ${NSD_Check} $DesktopCheckbox
  nsDialogs::Show
FunctionEnd
Function OptionsLeave
  ${NSD_GetState} $DesktopCheckbox $CreateDesktop
FunctionEnd

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
  StrCpy $CreateDesktop ${BST_CHECKED}
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "$(RequireX64)"
    Abort
  ${EndIf}
  SetShellVarContext current
FunctionEnd

Section "Tribes of Fire" SecGame
  SetOutPath "$INSTDIR"
  File "${SOURCE_DIR}/TribesOfFire.exe"
  File "${SOURCE_DIR}/SafeMode.cmd"
  File "${SOURCE_DIR}/README.md"
  File "${SOURCE_DIR}/ARCHITECTURE.md"
  File "${SOURCE_DIR}/PROGRESS.md"
  File "${SOURCE_DIR}/CREDITS.md"
  File "${SOURCE_DIR}/CHANGELOG.md"
  File "${SOURCE_DIR}/THIRD_PARTY.md"
  SetOutPath "$INSTDIR\Docs"
  File "${SOURCE_DIR}/Docs/COMMUNICATION.md"
  File "${SOURCE_DIR}/Docs/AUDIT.md"
  File "${SOURCE_DIR}/Docs/TEST_REPORT.md"
  File "${SOURCE_DIR}/Docs/PRIVACY.md"
  File "${SOURCE_DIR}/Docs/RELEASE_READINESS.md"
  SetOutPath "$INSTDIR\Tests"
  File "${SOURCE_DIR}/Tests/MANUAL.md"
  SetOutPath "$INSTDIR\Tools"
  File "${SOURCE_DIR}/Tools/Test-Windows.ps1"
  SetOutPath "$INSTDIR\LICENSES"
  File "${SOURCE_DIR}/LICENSES/Godot-LICENSE.txt"
  File "${SOURCE_DIR}/LICENSES/Godot-COPYRIGHT.txt"
  File "${SOURCE_DIR}/LICENSES/Noto-CJK-COPYRIGHT.txt"
  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  ${If} $CreateDesktop == ${BST_CHECKED}
    CreateShortcut "$DESKTOP\Tribes of Fire.lnk" "$INSTDIR\TribesOfFire.exe" "" "$INSTDIR\TribesOfFire.exe" 0
  ${EndIf}
  CreateDirectory "$SMPROGRAMS\Tribes of Fire"
  CreateShortcut "$SMPROGRAMS\Tribes of Fire\Tribes of Fire.lnk" "$INSTDIR\TribesOfFire.exe"
  CreateShortcut "$SMPROGRAMS\Tribes of Fire\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\felipealx\TribesOfFire" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "DisplayName" "Tribes of Fire"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "Publisher" "felipealx"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "UninstallString" '$\"$INSTDIR\Uninstall.exe$\"'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire" "NoRepair" 1
SectionEnd

Function un.onInit
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$DESKTOP\Tribes of Fire.lnk"
  Delete "$INSTDIR\TribesOfFire.exe"
  Delete "$INSTDIR\SafeMode.cmd"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\ARCHITECTURE.md"
  Delete "$INSTDIR\PROGRESS.md"
  Delete "$INSTDIR\CREDITS.md"
  Delete "$INSTDIR\CHANGELOG.md"
  Delete "$INSTDIR\THIRD_PARTY.md"
  Delete "$INSTDIR\Docs\COMMUNICATION.md"
  Delete "$INSTDIR\Docs\AUDIT.md"
  Delete "$INSTDIR\Docs\TEST_REPORT.md"
  Delete "$INSTDIR\Docs\PRIVACY.md"
  Delete "$INSTDIR\Docs\RELEASE_READINESS.md"
  RMDir "$INSTDIR\Docs"
  Delete "$INSTDIR\Tests\MANUAL.md"
  RMDir "$INSTDIR\Tests"
  Delete "$INSTDIR\Tools\Test-Windows.ps1"
  RMDir "$INSTDIR\Tools"
  Delete "$INSTDIR\LICENSES\Godot-LICENSE.txt"
  Delete "$INSTDIR\LICENSES\Godot-COPYRIGHT.txt"
  Delete "$INSTDIR\LICENSES\Noto-CJK-COPYRIGHT.txt"
  RMDir "$INSTDIR\LICENSES"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\Tribes of Fire\Tribes of Fire.lnk"
  Delete "$SMPROGRAMS\Tribes of Fire\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Tribes of Fire"
  DeleteRegKey HKCU "Software\felipealx\TribesOfFire"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\TribesOfFire"
  ; Godot user:// save data is intentionally preserved.
SectionEnd
