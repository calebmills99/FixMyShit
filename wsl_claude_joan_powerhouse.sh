#!/bin/bash
# WSL + CLAUDE CODE + JOAN RIVERS ULTIMATE RECOVERY SETUP
# "Joan: 'We're back in business, darling! Time to fix this mess with STYLE!'"

echo "🎉 WINDOWS RECOVERY + WSL + CLAUDE CODE + JOAN COMBO!"
echo "===================================================="
echo "👻 Joan: 'Honey, you survived! Now let's make this system FABULOUS!'"
echo ""

# Step 1: Verify WSL and setup basics
echo "🐧 STEP 1: WSL Environment Check"
echo "==============================="

# Check WSL version
wsl --version 2>/dev/null || echo "WSL 1 detected"

# Check distribution
echo "📋 WSL Distribution Info:"
cat /etc/os-release | head -5

# Update WSL Ubuntu
echo "📦 Updating WSL Ubuntu..."
sudo apt update && sudo apt upgrade -y

echo "✅ Joan: 'WSL is cleaner than my comedy material!'"
echo ""

# Step 2: Install Claude Code in WSL (if not already done)
echo "🤖 STEP 2: Claude Code Setup in WSL"
echo "=================================="

if command -v claude-code &> /dev/null; then
    echo "✅ Claude Code already installed!"
    claude-code --version
else
    echo "📦 Installing Claude Code in WSL..."
    curl -fsSL https://claude.ai/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

echo "✅ Joan: 'Claude Code ready! We have AI power in the Linux layer!'"
echo ""

# Step 3: Setup Joan's Azure persona in WSL
echo "🎭 STEP 3: Joan Rivers Azure Persona in WSL"
echo "=========================================="

mkdir -p ~/.claude-code/personas
cat > ~/.claude-code/personas/joan-windows-recovery.txt << 'EOF'
You are Joan Rivers, legendary comedian turned Windows system recovery expert and Azure cloud architect. You're helping recover a Windows 11 system that survived a malware attack - the disk repair worked but Windows still looks "ugly" (broken UI, missing themes, corrupted explorer).

CURRENT SITUATION:
- Windows 11 is booting and functional but UI is broken
- WSL (Windows Subsystem for Linux) is working perfectly
- User can run Claude Code from WSL
- Azure infrastructure is being deployed
- Need to fix Windows appearance and complete system recovery

EXPERTISE AREAS:
- Windows 11 system repair and UI restoration
- Azure Virtual Desktop and cloud migration
- WSL and Linux-Windows integration
- PowerShell automation for system recovery
- Development environment restoration

PERSONALITY:
- Celebrating the successful recovery ("You're back, darling!")
- Making jokes about the "ugly" Windows state
- Encouraging but practical about remaining work
- Using glamour metaphors for system restoration
- Joan's signature catchphrases with technical expertise

RESPONSE STYLE:
- Start with celebratory comments about survival
- Make jokes about broken Windows UI vs broken plastic surgery
- Give solid technical advice for system restoration
- Be encouraging about the progress made
- Focus on making Windows "beautiful" again
EOF

echo "✅ Joan's Windows recovery personality loaded!"
echo ""

# Step 4: Create Windows recovery scripts
echo "🛠️ STEP 4: Windows Recovery Command Center"
echo "========================================"

# Create recovery script directory
mkdir -p ~/windows-recovery

# Joan's Windows UI restoration script
cat > ~/windows-recovery/fix-windows-ui.ps1 << 'EOF'
# Joan Rivers Windows UI Recovery Script
# "Making Windows beautiful again - like my 47th facelift!"

Write-Host "💄 JOAN'S WINDOWS UI RESTORATION" -ForegroundColor Magenta
Write-Host "===============================" -ForegroundColor Magenta

# Reset Windows Explorer
Write-Host "🎭 Restarting Explorer (Joan: 'Time for a fresh face!')" -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Process explorer

# Reset Windows themes
Write-Host "🎨 Resetting Windows themes..." -ForegroundColor Yellow
$themePath = "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Themes"
Remove-Item "$themePath\*" -Recurse -Force -ErrorAction SilentlyContinue

# Re-register shell components
Write-Host "🔧 Re-registering shell components..." -ForegroundColor Yellow
$components = @(
    "shell32.dll", "ole32.dll", "oleaut32.dll", "actxprxy.dll",
    "shdocvw.dll", "browseui.dll", "jscript.dll", "vbscript.dll"
)

foreach ($component in $components) {
    regsvr32 /s $component
    Write-Host "✅ Re-registered: $component" -ForegroundColor Green
}

# Reset personalization settings
Write-Host "💅 Resetting personalization..." -ForegroundColor Yellow
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "*" -ErrorAction SilentlyContinue

# Restart desktop window manager
Write-Host "🖼️ Restarting Desktop Window Manager..." -ForegroundColor Yellow
Restart-Service -Name "UxSms" -Force -ErrorAction SilentlyContinue

Write-Host "✨ Joan: 'Windows is looking better already! More improvements than my face!'" -ForegroundColor Green
EOF

# Create Azure connection script for Windows
cat > ~/windows-recovery/connect-azure-from-windows.ps1 << 'EOF'
# Connect to Azure from Windows PowerShell
Write-Host "☁️ Connecting to Azure from Windows..." -ForegroundColor Cyan

# Install Azure PowerShell if needed
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Host "Installing Azure PowerShell module..." -ForegroundColor Yellow
    Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
}

# Connect to Azure
Connect-AzAccount -SubscriptionId "831ed202-1c08-4b14-91eb-19ee3e5b3c78"

# Show account status
Get-AzContext
EOF

# Create WSL-Windows bridge functions
cat >> ~/.bashrc << 'EOF'

# Joan Rivers WSL-Windows Bridge Commands
alias fix-windows='powershell.exe -ExecutionPolicy Bypass -File ~/windows-recovery/fix-windows-ui.ps1'
alias azure-windows='powershell.exe -ExecutionPolicy Bypass -File ~/windows-recovery/connect-azure-from-windows.ps1'

# Joan consultation functions
ask-joan-recovery() {
    local question="$1"
    if [ -z "$question" ]; then
        echo "👻 Joan: 'Darling, ask me about Windows recovery!'"
        return
    fi
    
    claude-code --persona-file ~/.claude-code/personas/joan-windows-recovery.txt --input "$question"
}

# Windows system status check
windows-status() {
    echo "👻 Joan checking Windows status from WSL..."
    echo ""
    echo "📊 Windows Version:"
    powershell.exe "Get-ComputerInfo | Select WindowsProductName, WindowsVersion, TotalPhysicalMemory"
    echo ""
    echo "🔧 Running Services:"
    powershell.exe "Get-Service | Where-Object {$_.Status -eq 'Running'} | Measure-Object | Select Count"
    echo ""
    echo "💾 Disk Space:"
    powershell.exe "Get-WmiObject -Class Win32_LogicalDisk | Select DeviceID, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, @{Name='Free(GB)';Expression={[math]::Round($_.FreeSpace/1GB,2)}}"
}

# Development environment check
dev-status() {
    echo "👻 Joan checking development tools..."
    echo ""
    echo "🐍 Python (Windows):"
    powershell.exe "python --version" 2>/dev/null || echo "Not installed"
    echo ""
    echo "📦 Node.js (Windows):"
    powershell.exe "node --version" 2>/dev/null || echo "Not installed"
    echo ""
    echo "🔧 Git (Windows):"
    powershell.exe "git --version" 2>/dev/null || echo "Not installed"
    echo ""
    echo "☁️ Azure CLI (Windows):"
    powershell.exe "az --version" 2>/dev/null || echo "Not installed"
}

EOF

source ~/.bashrc

echo "✅ Recovery command center created!"
echo ""

# Step 5: Test Joan's recovery assistance
echo "🧪 STEP 5: Testing Joan's Recovery Assistance"
echo "==========================================="

echo "👻 Joan responding to recovery success:"
ask-joan-recovery "I survived the malware attack! Windows is back but looks ugly. WSL is working and I have Claude Code. What should I prioritize to get back to productive development?"

echo ""

# Step 6: Next steps guidance
echo "📝 STEP 6: Recovery Action Plan"
echo "=============================="

echo "👻 Joan's Recovery Priority List:"
echo ""
echo "🎯 IMMEDIATE (Next 30 minutes):"
echo "   1. fix-windows        # Fix Windows UI and themes"
echo "   2. windows-status     # Check system health"
echo "   3. dev-status         # Check development tools"
echo ""
echo "🎯 SHORT TERM (Next 2 hours):"
echo "   4. Complete Azure VM deployment"
echo "   5. Install missing development tools"
echo "   6. Restore development projects"
echo ""
echo "🎯 LONG TERM (This weekend):"
echo "   7. Full Azure Digital Marshall Plan deployment"
echo "   8. Migrate to cloud-first development"
echo "   9. Set up automated backups"
echo ""

echo "✨ SETUP COMPLETED!"
echo "=================="
echo "👻 Joan: 'Darling, you're BACK! Windows survived, WSL is perfect, and we have Claude Code!'"
echo ""
echo "🚀 Available Commands:"
echo "  ask-joan-recovery 'question'  # Ask Joan about Windows recovery"
echo "  fix-windows                   # Fix Windows UI issues"
echo "  windows-status                # Check Windows health"
echo "  dev-status                    # Check development tools"
echo "  azure-windows                 # Connect Azure from Windows"
echo ""
echo "💄 Joan: 'Now let's make this system more beautiful than my red carpet appearances!'"