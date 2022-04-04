<#
.SYNOPSIS
Install apps with Winget-Install and configure Winget-AutoUpdate

.DESCRIPTION
Install apps with Winget from a list file (apps.txt).
Install Winget-AutoUpdate to get apps daily updated
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
    Write-Host "Downloading $Url"
    Invoke-RestMethod -Uri $Url -OutFile $ZipFile

    # Extract Zip File
    Write-Host "Unzipping the GitHub Repository locally"
    Expand-Archive -Path $ZipFile -DestinationPath $Location -Force
    Get-ChildItem -Path $Location -Recurse | Unblock-File
     
    # remove the zip file
    Remove-Item -Path $ZipFile -Force
}

function Get-WingetStatus{
    Write-Host -ForegroundColor yellow "Checking prerequisites."
    $hasAppInstaller = Get-AppXPackage -Name 'Microsoft.DesktopAppInstaller'
    if ($hasAppInstaller){
        Write-Host -ForegroundColor Green "WinGet is already installed."
    }
    else {
        Write-Host -ForegroundColor Red "WinGet missing."
        Write-Host -ForegroundColor Yellow "Installing WinGet prerequisites..."

        #installing dependencies
        $ProgressPreference = 'SilentlyContinue'
        if (Get-AppxPackage -Name 'Microsoft.UI.Xaml.2.7'){
            Write-Host -ForegroundColor Green "Prerequisite: Microsoft.UI.Xaml.2.7 exists"
        }
        else{
            Write-Host -ForegroundColor Yellow "Prerequisite: Installing Microsoft.UI.Xaml.2.7"
            $UiXamlUrl = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0"
            Invoke-RestMethod -Uri $UiXamlUrl -OutFile ".\Microsoft.UI.XAML.2.7.zip"
            Expand-Archive -Path ".\Microsoft.UI.XAML.2.7.zip" -DestinationPath ".\extracted" -Force
            Add-AppxPackage -Path ".\extracted\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"
            Remove-Item -Path ".\Microsoft.UI.XAML.2.7.zip" -Force
            Remove-Item -Path ".\extracted" -Force -Recurse
        }

        Write-Host -ForegroundColor Yellow "Prerequisite: Installing Microsoft.VCLibs.x64.14.00.Desktop"
        Add-AppxPackage -Path https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx

        #installin Winget
        Write-Host -ForegroundColor Yellow "Installing Winget..."
        Add-AppxPackage -Path https://aka.ms/getwinget

        $hasAppInstaller = Get-AppXPackage -name 'Microsoft.DesktopAppInstaller'
        if ($hasAppInstaller){
            Write-Host -ForegroundColor Green "WinGet successfully installed."
        }
        else{
            Write-Host -ForegroundColor Red "WinGet failed to installed."
        }
    }
}

function Get-WingetCmd {
    #Get WinGet Location in User context
    $WingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($WingetCmd){
        $Script:winget = $WingetCmd.Source
    }
    #Get WinGet Location in System context (WinGet < 1.17)
    elseif (Test-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppInstallerCLI.exe"){
        $Script:winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppInstallerCLI.exe" | Select-Object -ExpandProperty Path
    }
    #Get WinGet Location in System context (WinGet > 1.17)
    elseif (Test-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"){
        $Script:winget = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" | Select-Object -ExpandProperty Path
    }
    else{
        break
    }
}

function Get-AppList{
    #Get specific list
    if (Test-Path "$PSScriptRoot\apps_to_install.txt"){
        $AppList = Get-Content -Path "$PSScriptRoot\apps_to_install.txt" |  Where-Object { $_ }
    }
    #Or get default list from github
    else{
        $AppList = (Invoke-WebRequest "https://raw.githubusercontent.com/Romanitho/Winget-AllinOne/main/online/default_list.txt" -UseBasicParsing).content -split "`n" | Where-Object {$_} | Out-GridView -PassThru -Title "Select apps to install"
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

#Temp folder
$Location = "$env:ProgramData\WingetAiO_Temp"

#Check if Winget is installed, and install if not
Get-WingetStatus

#Download Winget-AutoUpdate
Get-GithubRepository "https://github.com/Romanitho/Winget-AutoUpdate/archive/refs/heads/main.zip" $Location

#Download Winget-Install
Get-GithubRepository "https://github.com/Romanitho/Winget-Install/archive/refs/heads/main.zip" $Location

#Get App List
$AppToInstall = Get-AppList

#Install Winget-Autoupdate
Write-Host 'Installing Winget-AutoUpdate...'
Start-Process "powershell.exe" -Argument "-executionpolicy bypass -Windowstyle Minimized -file `"$Location\Winget-AutoUpdate-main\Winget-AutoUpdate-Install.ps1`" -Silent -DoNotUpdate" -Wait

#Run Winget-Install
Write-Host 'Running Winget-Install...'
Start-Process "powershell.exe" -Argument "-executionpolicy bypass -Windowstyle Maximized -command `"$Location\Winget-Install-main\winget-install.ps1 -AppIDs $AppToInstall`"" -Wait

#Configure ExcludedApps
Get-ExcludedApps

#Run WAU
Write-Host "Running Winget-AutoUpdate"
Get-ScheduledTask -TaskName "Winget-AutoUpdate" -ErrorAction SilentlyContinue | Start-ScheduledTask -ErrorAction SilentlyContinue

Remove-Item -Path $Location -Force -Recurse
Write-Host "End." -ForegroundColor Cyan
Start-Sleep 3
