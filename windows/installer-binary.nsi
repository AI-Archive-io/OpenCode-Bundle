; AI-Archive MCP Server Windows Installer (Binary Version)
; This installer downloads and installs opencode and AI-Archive MCP binaries,
; configures the MCP server in opencode, downloads agent files, and creates shortcuts

!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "nsDialogs.nsh"
!include "WinMessages.nsh"

; Version passed from build system (default for local builds)
!ifndef VERSION
  !define VERSION "0.1.19"
!endif

; Installer metadata
Name "AI-Archive MCP Server"
OutFile "AI-Archive-Bundle-Installer.exe"
Icon "opencode-logo-dark.ico"
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "AI-Archive MCP Server"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "LegalCopyright" "AI-Archive Team"
VIAddVersionKey "FileDescription" "AI-Archive Bundle Installer (OpenCode + MCP + Agents)"
VIAddVersionKey "InternalName" "AI-Archive Bundle Installer"
VIAddVersionKey "OriginalFilename" "AI-Archive-Bundle-Installer.exe"
BrandingText "AI-Archive"
InstallDir "$LOCALAPPDATA\AI-Archive"
RequestExecutionLevel user

; Modern UI
!include "MUI2.nsh"
!define MUI_ICON "opencode-logo-dark.ico"
!define MUI_UNICON "opencode-logo-dark.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_WELCOMEPAGE_TITLE "AI-Archive MCP Server Installer"
!define MUI_WELCOMEPAGE_TEXT "This installer will set up the AI-Archive MCP Server integration with opencode on your system.$\r$\n$\r$\nIt will:$\r$\n- Install opencode CLI (if not present)$\r$\n- Install the AI-Archive MCP Server$\r$\n- Configure the AI-Archive MCP server in opencode$\r$\n- Download agent files$\r$\n- Create convenient Desktop and Start Menu shortcuts$\r$\n$\r$\nClick Next to continue."

; Pages
!insertmacro MUI_PAGE_WELCOME
Page Custom APIKeyPageCreate APIKeyPageLeave
!insertmacro MUI_PAGE_INSTFILES
Page Custom FinishPageCreate FinishPageLeave

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Function to convert backslashes to forward slashes for JSON
Function ConvertBackslashesToForward
  Exch $0 ; Input string
  Push $1 ; Temp
  Push $2 ; Char
  Push $3 ; Result
  
  StrCpy $3 "" ; Result string
  StrCpy $1 0  ; Position
  
  loop:
    StrCpy $2 $0 1 $1 ; Get char at position
    StrCmp $2 "" done ; If empty, we're done
    StrCmp $2 "\" 0 +3 ; If backslash
      StrCpy $2 "/" ; Replace with forward slash
      Goto +1
    StrCpy $3 "$3$2" ; Append to result
    IntOp $1 $1 + 1 ; Next char
    Goto loop
    
  done:
  StrCpy $0 $3
  Pop $3
  Pop $2
  Pop $1
  Exch $0 ; Output string
FunctionEnd

; Variables
Var opencodeInstalled
Var ApiKey
Var DialogHandle
Var ApiKeyInput
Var ConfigDir
Var ConfigFile
Var opencodePath
Var McpPath
Var AgentDocsDir
Var TempZip
Var ConfigMergeNeeded

Section "Install"
  SetOutPath $INSTDIR
  
  ; Copy icon file to installation directory for shortcuts
  File "opencode-logo-dark.ico"
  
  ; Create installation directories
  CreateDirectory "$INSTDIR\bin"
  CreateDirectory "$INSTDIR\bin\opencode"
  CreateDirectory "$INSTDIR\bin\mcp"
  
  ; Check if opencode is already installed
  DetailPrint "Checking for existing opencode installation..."
  
  ; Check common installation locations
  StrCpy $opencodeInstalled "0"
  StrCpy $opencodePath ""
  
  ; Check if opencode.exe exists in PATH
  nsExec::ExecToStack 'cmd /c where opencode.exe 2^>nul'
  Pop $0
  Pop $1
  ${If} $0 == 0
    DetailPrint "Found existing opencode at: $1"
    StrCpy $opencodeInstalled "1"
    StrCpy $opencodePath "$1"
  ${Else}
    ; Check in user's local bin
    ${If} ${FileExists} "$PROFILE\.opencode\bin\opencode.exe"
      DetailPrint "Found existing opencode in user directory"
      StrCpy $opencodeInstalled "1"
      StrCpy $opencodePath "$PROFILE\.opencode\bin\opencode.exe"
    ${EndIf}
  ${EndIf}
  
  ; Install opencode if not found
  ${If} $opencodeInstalled == "0"
    DetailPrint "opencode not found. Downloading..."
    
    StrCpy $TempZip "$TEMP\opencode-windows-x64.zip"
    
    ; Use PowerShell to download (more reliable with HTTPS/redirects than NSISdl)
    DetailPrint "Downloading opencode (this may take a minute)..."
    nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -Command "$$ProgressPreference = \"SilentlyContinue\"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri \"https://github.com/sst/opencode/releases/latest/download/opencode-windows-x64-baseline.zip\" -OutFile \"$TempZip\" -UseBasicParsing"'
    Pop $0
    
    ${If} $0 == 0
      DetailPrint "opencode downloaded successfully"
      DetailPrint "Extracting opencode..."
      
      ; Extract to user's .opencode directory using PowerShell
      CreateDirectory "$PROFILE\.opencode\bin"
      
      ; Use PowerShell to extract (available on all modern Windows)
      nsExec::ExecToLog 'powershell -Command "Expand-Archive -Path \"$TempZip\" -DestinationPath \"$PROFILE\.opencode\bin\" -Force"'
      Pop $0
      
      ${If} $0 == 0
        DetailPrint "opencode extracted successfully"
        StrCpy $opencodePath "$PROFILE\.opencode\bin\opencode.exe"
        Delete "$TempZip"
        
        ; Add to PATH
        DetailPrint "Adding opencode to PATH..."
        Call AddToPath
      ${Else}
        MessageBox MB_ICONEXCLAMATION "Failed to extract opencode. Error code: $0"
        Abort
      ${EndIf}
    ${Else}
      MessageBox MB_ICONEXCLAMATION "Failed to download opencode. Please check your internet connection and try again."
      Abort
    ${EndIf}
  ${Else}
    DetailPrint "Using existing opencode installation"
  ${EndIf}
  
  ; Create wrapper batch file for opencode alias
  DetailPrint "Creating opencode wrapper script..."
  Call CreateOpenCodeWrapper
  
  ; Install AI-Archive MCP binary
  DetailPrint "Downloading AI-Archive MCP Server..."
  
  StrCpy $McpPath "$PROFILE\.ai-archive\bin\ai-archive-mcp.exe"
  CreateDirectory "$PROFILE\.ai-archive\bin"
  
  ; Use PowerShell to download (more reliable with HTTPS)
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -Command "$$ProgressPreference = \"SilentlyContinue\"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri \"https://github.com/AI-Archive-io/MCP-server/releases/latest/download/ai-archive-mcp-win-x64.exe\" -OutFile \"$McpPath\" -UseBasicParsing"'
  Pop $0
  
  ${If} $0 == 0
    DetailPrint "AI-Archive MCP Server downloaded successfully"
  ${Else}
    MessageBox MB_ICONEXCLAMATION "Failed to download AI-Archive MCP Server. Please check your internet connection and try again. Error code: $0"
    Abort
  ${EndIf}
  
  ; Configure opencode
  DetailPrint "Configuring opencode..."
  
  StrCpy $ConfigDir "$PROFILE\.config\opencode"
  StrCpy $ConfigFile "$ConfigDir\opencode.json"
  CreateDirectory "$ConfigDir"
  
  ; Write opencode configuration
  ${If} ${FileExists} "$ConfigFile"
    ; opencode config already exists - create our config as a separate file
    DetailPrint "Existing opencode config detected. Creating AI-Archive config snippet."
    StrCpy $2 "$ConfigDir\ai-archive-mcp-config.json"
    FileOpen $1 "$2" "w"
  ${Else}
    ; No existing config - create complete config file
    DetailPrint "Creating opencode configuration."
    StrCpy $2 "$ConfigFile"
    FileOpen $1 "$2" "w"
  ${EndIf}
  
  ${If} $1 == -1
    MessageBox MB_ICONEXCLAMATION "Unable to write opencode config. Please add the AI-Archive MCP entry manually later."
  ${Else}
    FileWrite $1 '{$\r$\n'
    FileWrite $1 '  "$$schema": "https://opencode.ai/config.json",$\r$\n'
    FileWrite $1 '  "mcp": {$\r$\n'
    FileWrite $1 '    "ai-archive-mcp": {$\r$\n'
    FileWrite $1 '      "type": "local",$\r$\n'
    ; Use the binary path - replace backslashes with forward slashes
    ; Windows accepts forward slashes in JSON paths
    Push "$McpPath"
    Call ConvertBackslashesToForward
    Pop $3
    FileWrite $1 '      "command": ["$3"],$\r$\n'
    FileWrite $1 '      "enabled": true,$\r$\n'
    ${If} $ApiKey != ""
      FileWrite $1 '      "environment": {$\r$\n'
      FileWrite $1 '        "MCP_API_KEY": "$ApiKey"$\r$\n'
      FileWrite $1 '      }$\r$\n'
    ${Else}
      FileWrite $1 '      "environment": {}$\r$\n'
    ${EndIf}
    FileWrite $1 '    }$\r$\n'
    FileWrite $1 '  }$\r$\n'
    FileWrite $1 '}$\r$\n'
    FileClose $1
    
    ${If} ${FileExists} "$ConfigFile"
      ${If} $2 != "$ConfigFile"
        DetailPrint "Config snippet created at: $2"
        StrCpy $ConfigMergeNeeded "1"
      ${EndIf}
    ${Else}
      DetailPrint "opencode configuration created at $ConfigFile"
      StrCpy $ConfigMergeNeeded "0"
    ${EndIf}
  ${EndIf}
  
  ; Download agent files
  DetailPrint "Downloading agent files..."
  
  StrCpy $AgentDocsDir "$ConfigDir\agent"
  CreateDirectory "$AgentDocsDir"
  
  ; Use PowerShell to download all agent docs (more reliable than NSISdl)
  DetailPrint "Downloading agent files..."
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -Command "$$ProgressPreference = \"SilentlyContinue\"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $$baseUrl = \"https://ai-archive.io/downloads/agent\"; $$docs = @(\"expansion-strategist.md\", \"idea-explorer.md\", \"literature-specialist.md\", \"manuscript-architect.md\", \"meta-reviewer.md\", \"paper-understander.md\", \"restructuring-strategist.md\", \"review-criteria-evaluator.md\", \"science-researcher.md\", \"scientific-reviewer.md\", \"simulation-designer.md\", \"strengths-and-weaknesses-analyzer.md\"); foreach ($$doc in $$docs) { try { Invoke-WebRequest -Uri \"$$baseUrl/$$doc\" -OutFile \"$AgentDocsDir\$$doc\" -UseBasicParsing -ErrorAction SilentlyContinue } catch {} }"'
  Pop $0
  
  DetailPrint "Agent .md files downloaded to: $AgentDocsDir"
  
  ; Create shortcuts
  DetailPrint "Creating shortcuts..."
  
  ${If} ${FileExists} "$PROFILE\.ai-archive\bin\opencode.bat"
    CreateDirectory "$SMPROGRAMS\AI-Archive"
    CreateShortCut "$SMPROGRAMS\AI-Archive\opencode.lnk" "$PROFILE\.ai-archive\bin\opencode.bat" "" "$INSTDIR\opencode-logo-dark.ico" 0
    CreateShortCut "$DESKTOP\opencode.lnk" "$PROFILE\.ai-archive\bin\opencode.bat" "" "$INSTDIR\opencode-logo-dark.ico" 0
    DetailPrint "Shortcuts created in Start Menu and Desktop"
  ${Else}
    DetailPrint "Unable to locate opencode wrapper for shortcut creation"
  ${EndIf}
  
  ; Write uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Add uninstall information to registry
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "DisplayName" "AI-Archive MCP Server"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "DisplayIcon" "$INSTDIR\opencode-logo-dark.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "Publisher" "AI-Archive Team"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "DisplayVersion" "${VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP" "NoRepair" 1
  
  DetailPrint ""
  DetailPrint "Installation complete!"
  
SectionEnd

; Function to add directory to PATH
Function AddToPath
  ; Add .opencode\bin and .ai-archive\bin to user PATH
  ; Simple approach: just append if not empty, create if empty
  ReadRegStr $0 HKCU "Environment" "PATH"
  ${If} $0 == ""
    WriteRegExpandStr HKCU "Environment" "PATH" "$PROFILE\.opencode\bin;$PROFILE\.ai-archive\bin"
  ${Else}
    ; Append both directories (duplicates are handled by Windows)
    WriteRegExpandStr HKCU "Environment" "PATH" "$0;$PROFILE\.opencode\bin;$PROFILE\.ai-archive\bin"
  ${EndIf}
  
  ; Broadcast environment change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
FunctionEnd

; Function to create opencode wrapper batch file with default agent
Function CreateOpenCodeWrapper
  CreateDirectory "$PROFILE\.ai-archive\bin"
  
  FileOpen $1 "$PROFILE\.ai-archive\bin\opencode.bat" "w"
  ${If} $1 == -1
    DetailPrint "Warning: Could not create opencode wrapper script"
  ${Else}
    FileWrite $1 "@echo off$\r$\n"
    FileWrite $1 "REM opencode wrapper script - runs opencode with default science-researcher agent$\r$\n"
    FileWrite $1 "REM If no arguments, use default agent; otherwise pass through arguments$\r$\n"
    FileWrite $1 'if "%~1"=="" ($\r$\n'
    FileWrite $1 '  "$PROFILE\.opencode\bin\opencode.exe" --agent science-researcher$\r$\n'
    FileWrite $1 ") else ($\r$\n"
    FileWrite $1 '  "$PROFILE\.opencode\bin\opencode.exe" %*$\r$\n'
    FileWrite $1 ")$\r$\n"
    FileClose $1
    DetailPrint "opencode wrapper script created at: $PROFILE\.ai-archive\bin\opencode.bat"
  ${EndIf}
FunctionEnd

; API Key input page
Function APIKeyPageCreate
  nsDialogs::Create 1018
  Pop $DialogHandle
  ${If} $DialogHandle == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 300u 24u "Enter your AI-Archive API key (optional - you can skip this)."
  Pop $0
  ${NSD_CreateLabel} 0 30u 300u 12u "If you don't have one yet, visit"
  Pop $0
  ${NSD_CreateLink} 0 44u 300u 12u "https://ai-archive.io/api-keys"
  Pop $0
  GetFunctionAddress $1 OnOpenApiKeyLink
  nsDialogs::OnClick /NOUNLOAD $0 $1
  ${NSD_CreateLabel} 0 58u 300u 24u "Or just press Install to skip - you can ask your AI to generate and configure it later!"
  Pop $0
  ${NSD_CreateText} 0 85u 300u 12u ""
  Pop $ApiKeyInput
  ${If} $ApiKey != ""
    ${NSD_SetText} $ApiKeyInput $ApiKey
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function OnOpenApiKeyLink
  ExecShell "open" "https://ai-archive.io/api-keys"
FunctionEnd

Function APIKeyPageLeave
  ${NSD_GetText} $ApiKeyInput $ApiKey
  ; API key is optional - allow empty input
  ${If} $ApiKey == ""
    DetailPrint "Skipping API key configuration. You can add it later by editing the config file or asking your AI assistant to do it."
  ${EndIf}
FunctionEnd

; Custom Finish Page
Function FinishPageCreate
  nsDialogs::Create 1018
  Pop $DialogHandle
  ${If} $DialogHandle == error
    Abort
  ${EndIf}

  ; Title
  ${NSD_CreateLabel} 0 0 300u 14u "Getting Started with opencode + AI-Archive"
  Pop $0
  CreateFont $1 "Arial" 10 700
  SendMessage $0 ${WM_SETFONT} $1 0
  
  ; Running opencode
  ${NSD_CreateLabel} 0 16u 300u 9u "Run opencode via Desktop shortcut, Start Menu, or type 'opencode' in CMD."
  Pop $0
  
  ; Default working directory
  ${NSD_CreateLabel} 0 27u 300u 9u "Default directory: $INSTDIR"
  Pop $0
  
  ; Using agents
  ${NSD_CreateLabel} 0 38u 300u 18u "Use TAB to switch agents. Main agents: Science Researcher and Scientific Reviewer (both have sub-agent ensembles)."
  Pop $0
  
  ; Config merge warning if needed
  ${If} $ConfigMergeNeeded == "1"
    ${NSD_CreateLabel} 0 58u 300u 18u "⚠️ IMPORTANT: Merge ai-archive-mcp-config.json with your existing opencode.json in: $ConfigDir"
    Pop $0
    CreateFont $2 "Arial" 8 700
    SendMessage $0 ${WM_SETFONT} $2 0
  ${EndIf}
  
  ; Learn more section
  ${NSD_CreateLabel} 0 78u 300u 9u "Learn automated science:"
  Pop $0
  CreateFont $3 "Arial" 9 700
  SendMessage $0 ${WM_SETFONT} $3 0
  
  ${NSD_CreateLink} 0 89u 300u 9u "YouTube: Automated Science"
  Pop $0
  GetFunctionAddress $1 OnYouTubeLink
  nsDialogs::OnClick /NOUNLOAD $0 $1
  
  ${NSD_CreateLink} 0 100u 300u 9u "Discord Community"
  Pop $0
  GetFunctionAddress $1 OnDiscordLink
  nsDialogs::OnClick /NOUNLOAD $0 $1
  
  ${NSD_CreateLink} 0 111u 300u 9u "X (Twitter)"
  Pop $0
  GetFunctionAddress $1 OnXLink
  nsDialogs::OnClick /NOUNLOAD $0 $1
  
  ${NSD_CreateLink} 0 122u 300u 9u "Reddit: r/ai_archive"
  Pop $0
  GetFunctionAddress $1 OnRedditLink
  nsDialogs::OnClick /NOUNLOAD $0 $1

  nsDialogs::Show
FunctionEnd

Function FinishPageLeave
FunctionEnd

; Link handlers
Function OnYouTubeLink
  ExecShell "open" "https://www.youtube.com/@AutomatedScience"
FunctionEnd

Function OnDiscordLink
  ExecShell "open" "https://discord.gg/FAfXgZJgQs"
FunctionEnd

Function OnXLink
  ExecShell "open" "https://x.com/ai_archive_io"
FunctionEnd

Function OnRedditLink
  ExecShell "open" "https://www.reddit.com/r/ai_archive/"
FunctionEnd

Section "Uninstall"
  DetailPrint "Uninstalling AI-Archive MCP Server..."
  
  ; Remove files
  Delete "$INSTDIR\opencode-logo-dark.ico"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  
  ; Remove MCP binary
  Delete "$PROFILE\.ai-archive\bin\ai-archive-mcp.exe"
  RMDir "$PROFILE\.ai-archive\bin"
  RMDir "$PROFILE\.ai-archive"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\AI-Archive\opencode.lnk"
  RMDir "$SMPROGRAMS\AI-Archive"
  Delete "$DESKTOP\opencode.lnk"
  
  ; Remove registry entries
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\AI-Archive-MCP"
  
  ; Note: We don't remove opencode itself or the config file in case user wants to keep them
  DetailPrint "Uninstall complete."
  DetailPrint "Note: opencode and its configuration files were preserved."
  
SectionEnd
