# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $testConnection = Test-NetConnection -ComputerName www.google.com -InformationLevel Quiet
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = if ($PSVersionTable.PSEdition -eq "Core") { 
            "$env:userprofile\Documents\Powershell"
        } else {
            "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1]"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed."
        Write-Host "Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1]"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# Oh My Posh Install
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
    Write-Host "Oh My Posh installed successfully."
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
try {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip", ".\CascadiaCode.zip")
        
        Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
            If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item -Path ".\CascadiaCode" -Recurse -Force
        Remove-Item -Path ".\CascadiaCode.zip" -Force
        Write-Host "CaskaydiaCove NF font installed successfully."
    }
    else {
        Write-Host "CaskaydiaCove NF font is already installed."
    }
}
catch {
    Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
}

# Chocolatey install
try {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey installed successfully."
    }
    else {
        Write-Host "Chocolatey is already installed."
    }
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
try {
    if (!(Get-Module -ListAvailable -Name Terminal-Icons)) {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "Terminal Icons module installed successfully."
    }
    else {
        Write-Host "Terminal Icons module is already installed."
    }
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}

# zoxide Install
try {
    if (!(Get-Command zoxide -ErrorAction SilentlyContinue)) {
        winget install -e --id ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements
        Write-Host "zoxide installed successfully."
    }
    else {
        Write-Host "zoxide is already installed."
    }
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}

# Final check and message to the user
Write-Host "Setup completed. Please restart your PowerShell session to apply changes."
