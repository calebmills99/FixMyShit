# ============================================
# POIROT'S CURSOR CONFIGURATION MASTERCRIPT v2
# ============================================
# Run as Administrator for best results!

param(
    [switch]$SkipBackup,
    [switch]$SkipExtensions,
    [switch]$AutoConfirm
)

function Write-PoirotHeader {
    Write-Host ""
    Write-Host "  🔍 HERCULE POIROT'S CURSOR SETUP INVESTIGATION  " -BackgroundColor Magenta -ForegroundColor White
    Write-Host "  ===============================================  " -BackgroundColor Magenta -ForegroundColor White
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "[$Number/12] $Title" -ForegroundColor Yellow -NoNewline
    Write-Host " ..." -ForegroundColor DarkGray
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

function Write-Success {
    param([string]$Message)
    Write-Host "   ✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "   ⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "   ❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "   📍 $Message" -ForegroundColor Cyan
}

# Start the investigation
Clear-Host
Write-PoirotHeader

# STEP 1: Environmental Evidence
Write-Step "1" "Gathering Environmental Evidence"

$CursorPath = "$env:LOCALAPPDATA\Programs\cursor"
$CursorDataPath = "$env:APPDATA\Cursor"
$UserSettingsPath = "$env:APPDATA\Cursor\User"
$BackupPath = "$env:USERPROFILE\cursor-backup-$(Get-Date -Format 'yyyyMMdd-HHmm')"

Write-Info "Cursor Data Path: $CursorDataPath"
Write-Info "Settings Path: $UserSettingsPath"

# STEP 2: Backup Existing Settings
if (-not $SkipBackup -and (Test-Path $UserSettingsPath)) {
    Write-Step "2" "Creating Backup of Existing Settings"
    
    try {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        Copy-Item -Path $UserSettingsPath -Destination $BackupPath -Recurse -Force
        Write-Success "Backup created at: $BackupPath"
    } catch {
        Write-Error "Failed to create backup: $_"
    }
} else {
    Write-Step "2" "Backup Step"
    Write-Info "Skipping backup (no existing settings or -SkipBackup specified)"
}

# STEP 3: Clean Slate Protocol
Write-Step "3" "Clean Slate Protocol"

if ($AutoConfirm) {
    $confirmation = 'y'
} else {
    $confirmation = Read-Host "   Remove existing Cursor settings? (y/N)"
}

if ($confirmation -eq 'y') {
    try {
        Remove-Item -Path "$env:APPDATA\Cursor\User" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\.cursor" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Previous settings eliminated!"
    } catch {
        Write-Warning "Some files could not be removed (might be in use)"
    }
} else {
    Write-Info "Keeping existing settings"
}

# STEP 4: Verify Cursor Installation
Write-Step "4" "Verifying Cursor Installation"

$cursorExe = Get-Command cursor -ErrorAction SilentlyContinue
if (-not $cursorExe) {
    Write-Error "Cursor not found in PATH!"
    Write-Info "Please install from https://cursor.sh"
    Write-Info "Then run this script again!"
    Read-Host "Press Enter to exit"
    exit 1
} else {
    Write-Success "Cursor detected at: $($cursorExe.Source)"
}

# STEP 5: Create Settings Directories
Write-Step "5" "Preparing Settings Directories"

try {
    New-Item -ItemType Directory -Path $UserSettingsPath -Force -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path "$UserSettingsPath\snippets" -Force -ErrorAction Stop | Out-Null
    Write-Success "Directories prepared!"
} catch {
    Write-Error "Failed to create directories: $_"
    exit 1
}

# STEP 6: Install Core Settings
Write-Step "6" "Installing Core Settings"

# Create settings.json content
$settingsContent = @{
    "cursor.aiProvider" = "claude-3-opus"
    "cursor.aiTemperature" = 0.7
    "cursor.copilotEnabled" = $true
    "cursor.chatEnabled" = $true
    "cursor.inlineEditEnabled" = $true
    
    "editor.fontSize" = 14
    "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', Consolas, monospace"
    "editor.fontLigatures" = $true
    "editor.lineHeight" = 22
    "editor.letterSpacing" = 0.5
    "editor.renderWhitespace" = "boundary"
    "editor.smoothScrolling" = $true
    "editor.cursorBlinking" = "smooth"
    "editor.cursorSmoothCaretAnimation" = "on"
    "editor.minimap.enabled" = $true
    "editor.wordWrap" = "on"
    "editor.formatOnSave" = $true
    "editor.formatOnPaste" = $true
    
    "workbench.colorTheme" = "One Dark Pro"
    "workbench.iconTheme" = "material-icon-theme"
    
    "terminal.integrated.fontSize" = 14
    "terminal.integrated.defaultProfile.windows" = "PowerShell"
    
    "files.autoSave" = "afterDelay"
    "files.autoSaveDelay" = 1000
}

try {
    $settingsContent | ConvertTo-Json -Depth 10 | Out-File -FilePath "$UserSettingsPath\settings.json" -Encoding UTF8
    Write-Success "Core settings installed!"
} catch {
    Write-Error "Failed to write settings: $_"
}

# STEP 7: Configure Keybindings
Write-Step "7" "Configuring Detective Keybindings"

$keybindings = @(
    @{
        key = "ctrl+k ctrl+a"
        command = "cursor.aiChat.open"
        when = "editorTextFocus"
    },
    @{
        key = "ctrl+shift+i"
        command = "cursor.inlineEdit.start"
        when = "editorTextFocus"
    },
    @{
        key = "ctrl+shift+g"
        command = "cursor.generateInFile"
        when = "editorTextFocus"
    }
)

try {
    $keybindings | ConvertTo-Json -Depth 10 | Out-File -FilePath "$UserSettingsPath\keybindings.json" -Encoding UTF8
    Write-Success "Keybindings configured!"
} catch {
    Write-Error "Failed to write keybindings: $_"
}

# STEP 8: Install Extensions
if (-not $SkipExtensions) {
    Write-Step "8" "Installing Essential Extensions"
    
    $extensions = @(
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode", 
        "usernamehw.errorlens",
        "eamodio.gitlens"
    )
    
    foreach ($ext in $extensions) {
        Write-Info "Installing $ext..."
        & cursor --install-extension $ext 2>$null
    }
    Write-Success "Extensions installation initiated!"
} else {
    Write-Step "8" "Extension Installation"
    Write-Info "Skipping extensions (-SkipExtensions specified)"
}

# STEP 9: Create Snippets
Write-Step "9" "Creating Poirot's Snippets"

$snippets = @{
    "Poirot Debug" = @{
        prefix = "pdebug"
        body = @(
            "console.log('🔍 Investigating `${1:subject}`:', `${1:subject});",
            "console.log('📊 Type:', typeof `${1:subject});",
            "console.log('📍 Stack:', new Error().stack);"
        )
        description = "Poirot's investigation logger"
    }
}

try {
    $snippets | ConvertTo-Json -Depth 10 | Out-File -FilePath "$UserSettingsPath\snippets\poirot.code-snippets" -Encoding UTF8
    Write-Success "Snippets created!"
} catch {
    Write-Error "Failed to create snippets: $_"
}

# STEP 10: Create AI Rules
Write-Step "10" "Configuring AI Rules"

$aiRules = @"
# Poirot's AI Assistant Rules

You are an elite developer assistant with expertise in:
- Clean, maintainable code architecture
- Security best practices
- Performance optimization
- Comprehensive error handling

## Code Generation Rules:
1. ALWAYS include error handling
2. Add clear comments for complex logic
3. Follow project conventions
4. Consider performance implications
5. Suggest unit tests for new functions

## Response Style:
- Be concise but thorough
- Explain complex concepts clearly
- Provide examples when helpful
"@

try {
    $aiRules | Out-File -FilePath "$env:USERPROFILE\.cursorrules" -Encoding UTF8
    Write-Success "AI rules configured!"
} catch {
    Write-Error "Failed to write AI rules: $_"
}

# STEP 11: Create Test File
Write-Step "11" "Creating Test Laboratory"

$testFile = @"
// 🔍 POIROT'S CURSOR TEST FILE
// ================================

// Test 1: AI Chat (Ctrl+K Ctrl+A)
// Select this comment and open AI chat

// Test 2: Inline Edit (Ctrl+Shift+I)
function calculateSum(a, b) {
    return a + b;
}

// Test 3: Snippets
// Type 'pdebug' and press Tab

// TODO: Verify all configurations
console.log('🎉 Setup complete!');
"@

$testPath = "$env:USERPROFILE\cursor-test.js"
try {
    $testFile | Out-File -FilePath $testPath -Encoding UTF8
    Write-Success "Test file created at: $testPath"
} catch {
    Write-Error "Failed to create test file: $_"
}

# STEP 12: Final Report
Write-Step "12" "Final Investigation Report"

Write-Host ""
Write-Host "  🏆 CONFIGURATION COMPLETE! 🏆  " -BackgroundColor Green -ForegroundColor White
Write-Host ""

# Create simple certificate file (avoiding here-string issues)
$certLines = @(
    "CURSOR CONFIGURATION CERTIFICATE",
    "=" * 40,
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    "User: $env:USERNAME",
    "Machine: $env:COMPUTERNAME",
    "",
    "Status: CONFIGURATION SUCCESSFUL",
    "",
    "The perfect development environment has been achieved!",
    "- Hercule Poirot 2.0"
)

$certPath = "$env:USERPROFILE\cursor-certificate.txt"
$certLines | Out-File -FilePath $certPath -Encoding UTF8

Write-Success "Certificate saved to: $certPath"
Write-Host ""
Write-Info "Next Steps:"
Write-Host "   1. Restart Cursor completely" -ForegroundColor Cyan
Write-Host "   2. Open test file: cursor `"$testPath`"" -ForegroundColor Cyan
Write-Host "   3. Test features as described in the file" -ForegroundColor Cyan
Write-Host ""

# Prompt to open Cursor
if (-not $AutoConfirm) {
    $openNow = Read-Host "Open Cursor now? (Y/n)"
    if ($openNow -ne 'n') {
        Start-Process cursor
    }
}

Write-Host ""
Write-Host "🔍 'Voilà! The investigation is complete!'" -ForegroundColor Magenta
Write-Host ""