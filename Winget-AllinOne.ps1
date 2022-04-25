<#
.SYNOPSIS
Install apps with Winget-Install and configure Winget-AutoUpdate

.DESCRIPTION
This script will:
 - Install Winget if not present
 - Install apps with Winget from a custom list file (apps.txt) or directly from popped up default list.
 - Install Winget-AutoUpdate to get apps daily updated
https://github.com/Romanitho/Winget-AllinOne
#>


<# FUNCTIONS #>

function Get-GithubRepository { 
    param( 
       [Parameter()] [string] $Url,
       [Parameter()] [string] $Location
    ) 
     
    # Force to create a zip file 
    $ZipFile = "$Location\temp.zip"
    New-Item $ZipFile -ItemType File -Force | Out-Null

    # Download the zip 
    Write-Host "-> Downloading $Url"
    Invoke-RestMethod -Uri $Url -OutFile $ZipFile

    # Extract Zip File
    Write-Host "-> Unzipping the GitHub Repository locally"
    Expand-Archive -Path $ZipFile -DestinationPath $Location -Force
    Get-ChildItem -Path $Location -Recurse | Unblock-File
     
    # remove the zip file
    Remove-Item -Path $ZipFile -Force
}

function Get-WingetStatus{
    Write-Host -ForegroundColor yellow "Checking prerequisites..."
    $hasAppInstaller = Get-AppXPackage -Name 'Microsoft.DesktopAppInstaller'
    [Version]$AppInstallerVers = $hasAppInstaller.version
    if ($AppInstallerVers -gt "1.16.0.0"){
        Write-Host -ForegroundColor Green "WinGet is already installed."
    }
    else {
        Write-Host -ForegroundColor Red "WinGet missing."
        Write-Host -ForegroundColor Yellow "-> Installing WinGet prerequisites..."

        #installing dependencies
        $ProgressPreference = 'SilentlyContinue'
        if (Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.7'){
            Write-Host -ForegroundColor Green "-> Prerequisite: Microsoft.UI.Xaml.2.7 exists"
        }
        else{
            Write-Host -ForegroundColor Yellow "-> Prerequisite: Installing Microsoft.UI.Xaml.2.7"
            $UiXamlUrl = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0"
            Invoke-RestMethod -Uri $UiXamlUrl -OutFile ".\Microsoft.UI.XAML.2.7.zip"
            Expand-Archive -Path ".\Microsoft.UI.XAML.2.7.zip" -DestinationPath ".\extracted" -Force
            Add-AppxPackage -Path ".\extracted\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
            Remove-Item -Path ".\Microsoft.UI.XAML.2.7.zip" -Force
            Remove-Item -Path ".\extracted" -Force -Recurse
        }

        Write-Host -ForegroundColor Yellow "-> Prerequisite: Installing Microsoft.VCLibs.x64.14.00.Desktop"
        Add-AppxPackage -Path https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx

        #installin Winget
        Write-Host -ForegroundColor Yellow "-> Installing Winget..."
        Add-AppxPackage -Path https://github.com/microsoft/winget-cli/releases/download/v1.3.431/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle


        $hasAppInstaller = Get-AppXPackage -Name 'Microsoft.DesktopAppInstaller'
        [Version]$AppInstallerVers = $hasAppInstaller.version
        if ($AppInstallerVers -gt "1.16.0.0"){
            Write-Host -ForegroundColor Green "WinGet successfully installed."
        }
        else{
            Write-Host -ForegroundColor Red "WinGet failed to installed."
        }
    }
}

function Get-AppList{
    #Get specific list
    if (Test-Path "$PSScriptRoot\apps_to_install.txt"){
        Write-Host "Will install apps from 'apps_to_install.txt' file" -ForegroundColor Magenta
        $AppList = Get-Content -Path "$PSScriptRoot\apps_to_install.txt" |  Where-Object { $_ }
    }
    #Or get default list from github
    else{
        Write-Host "Application selection from list..." -ForegroundColor Magenta
        $AppIDList = (Invoke-WebRequest "https://raw.githubusercontent.com/Romanitho/Winget-AllinOne/main/online/default_list.txt" -UseBasicParsing).content | ConvertFrom-Csv -Delimiter "," | Out-GridView -PassThru -Title "Select apps to install"
        $AppList = $AppIDList.AppID
    }
    return $AppList -join ","
}

function Get-ExcludedApps{
    if (Test-Path "$PSScriptRoot\excluded_apps.txt"){
        Write-Host "Installing Custom 'excluded_apps.txt' file"
        Copy-Item -Path "$PSScriptRoot\excluded_apps.txt" -Destination "$env:ProgramData\Winget-AutoUpdate" -Recurse -Force -ErrorAction SilentlyContinue
    }
    else{
        Write-Host "Keeping default 'excluded_apps.txt' file"
    }
}


<# MAIN #>

Write-Host "`n"
Write-Host "`t###################################"
Write-Host "`t#                                 #"
Write-Host "`t#         Winget AllinOne         #"
Write-Host "`t#                                 #"
Write-Host "`t###################################"
Write-Host "`n"
Write-Host "###" -ForegroundColor Cyan

#Temp folder
$Location = "$env:ProgramData\WingetAiO_Temp"

#Check if Winget is installed, and install if not
Get-WingetStatus
Write-Host "###" -ForegroundColor Cyan

#Get App List
$AppToInstall = Get-AppList

#Download and install Winget-AutoUpdate if not installed
if(Test-Path "$env:ProgramData\Winget-AutoUpdate\config\about.xml"){
    Write-Host "Winget-AutoUpdate already installed!" -ForegroundColor Green
}
else{
    Write-Host "Installing Winget-AutoUpdate..." -ForegroundColor Yellow

    #Download Winget-AutoUpdate
    Get-GithubRepository "https://github.com/Romanitho/Winget-AutoUpdate/archive/refs/tags/v1.8.0.zip" $Location

    #Install Winget-Autoupdate
    $WAUInstallFile = (Resolve-Path "$Location\*Winget-AutoUpdate*\Winget-AutoUpdate-Install.ps1").Path
    Start-Process "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Minimized -Command `"$WAUInstallFile -Silent -DoNotUpdate`"" -Wait -Verb RunAs
    Write-Host "Winget-AutoUpdate installed!" -ForegroundColor Green
}

Write-Host "###" -ForegroundColor Cyan
Write-Host "Running Winget-Install..." -ForegroundColor Yellow

#Download Winget-Install
Get-GithubRepository "https://github.com/Romanitho/Winget-Install/archive/refs/tags/v1.5.0.zip" $Location

#Run Winget-Install
$InstallFile = (Resolve-Path "$Location\*Winget-Install*\winget-install.ps1").Path
Start-Process "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Maximized -Command `"$InstallFile -AppIDs $AppToInstall`"" -Wait -Verb RunAs

#Configure ExcludedApps
Get-ExcludedApps
Write-Host "###" -ForegroundColor Cyan

#Run WAU
Write-Host "Running Winget-AutoUpdate..." -ForegroundColor Yellow
Get-ScheduledTask -TaskName "Winget-AutoUpdate" -ErrorAction SilentlyContinue | Start-ScheduledTask -ErrorAction SilentlyContinue

Remove-Item -Path $Location -Force -Recurse
Write-Host "###" -ForegroundColor Cyan
Write-Host "Finished." -ForegroundColor Green
Write-Host "###" -ForegroundColor Cyan
Start-Sleep 3
