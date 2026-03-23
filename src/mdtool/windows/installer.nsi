# MDTool NSIS Installer Script
# This script is used by CPack to create the Windows installer

!include "MUI2.nsh"
!include "FileAssociation.nsh"

# Installer Information
Name "MDTool"
OutFile "MDTool-Setup.exe"
InstallDir "$PROGRAMFILES\MDTool"
InstallDirRegKey HKCU "Software\MDTool" ""
RequestExecutionLevel admin

# Modern UI Configuration
!define MUI_ABORTWARNING
!define MUI_ICON "runner\resources\app_icon.ico"
!define MUI_UNICON "runner\resources\app_icon.ico"

# Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS  
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

# Languages
!insertmacro MUI_LANGUAGE "English"

# Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "MDTool"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "MDTool"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright © 2025 MDTool"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "MDTool Installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "1.0.0.0"

# Components
Section "MDTool Application" SecApp
  SectionIn RO  ; Read-only (always installed)
  
  SetOutPath "$INSTDIR"
  
  # Install main executable and dependencies
  File "MDTool.exe"
  File "flutter_windows.dll"
  File /r "data"
  
  # Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  # Registry entries for uninstaller
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "DisplayName" "MDTool"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "DisplayIcon" "$INSTDIR\MDTool.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "Publisher" "MDTool"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "DisplayVersion" "1.0.0"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool" "NoRepair" 1
  
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
  CreateDirectory "$SMPROGRAMS\MDTool"
  CreateShortcut "$SMPROGRAMS\MDTool\MDTool.lnk" "$INSTDIR\MDTool.exe"
  CreateShortcut "$SMPROGRAMS\MDTool\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortcut "$DESKTOP\MDTool.lnk" "$INSTDIR\MDTool.exe"
SectionEnd

Section "File Associations" SecFileAssoc
  # Register file associations using FileAssociation macros
  ${registerExtension} "$INSTDIR\MDTool.exe" ".md" "Markdown Document"
  ${registerExtension} "$INSTDIR\MDTool.exe" ".markdown" "Markdown Document" 
  ${registerExtension} "$INSTDIR\MDTool.exe" ".mdown" "Markdown Document"
  ${registerExtension} "$INSTDIR\MDTool.exe" ".mkd" "Markdown Document"
  ${registerExtension} "$INSTDIR\MDTool.exe" ".mkdn" "Markdown Document"
  
  # Refresh shell to update file associations
  System::Call 'shell32.dll::SHChangeNotify(l, l, i, i) v (0x08000000, 0, 0, 0)'
SectionEnd

# Component Descriptions
LangString DESC_SecApp ${LANG_ENGLISH} "The main MDTool application and required files"
LangString DESC_SecStartMenu ${LANG_ENGLISH} "Add shortcuts to the Start Menu"
LangString DESC_SecDesktop ${LANG_ENGLISH} "Add a shortcut to the Desktop"
LangString DESC_SecFileAssoc ${LANG_ENGLISH} "Associate Markdown files (.md, .markdown, etc.) with MDTool"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecApp} $(DESC_SecApp)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_SecStartMenu)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
  !insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssoc} $(DESC_SecFileAssoc)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

# Uninstaller
Section "Uninstall"
  # Remove files
  Delete "$INSTDIR\MDTool.exe"
  Delete "$INSTDIR\flutter_windows.dll"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR\data"
  RMDir "$INSTDIR"
  
  # Remove shortcuts
  Delete "$SMPROGRAMS\MDTool\MDTool.lnk"
  Delete "$SMPROGRAMS\MDTool\Uninstall.lnk"
  RMDir "$SMPROGRAMS\MDTool"
  Delete "$DESKTOP\MDTool.lnk"
  
  # Remove file associations
  ${unregisterExtension} ".md" "Markdown Document"
  ${unregisterExtension} ".markdown" "Markdown Document"
  ${unregisterExtension} ".mdown" "Markdown Document" 
  ${unregisterExtension} ".mkd" "Markdown Document"
  ${unregisterExtension} ".mkdn" "Markdown Document"
  
  # Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\MDTool"
  DeleteRegKey HKCU "Software\MDTool"
  
  # Refresh shell
  System::Call 'shell32.dll::SHChangeNotify(l, l, i, i) v (0x08000000, 0, 0, 0)'
SectionEnd