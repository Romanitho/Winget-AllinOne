# Winget-AllinOne
Install apps one shot + Winget-AutoUpdate

## Info
All in one job based on
- https://github.com/Romanitho/Winget-AutoUpdate
- https://github.com/Romanitho/Winget-Install

## Install
### - Offline with specific app lists
- [Download projet](https://github.com/Romanitho/Winget-AllinOne/archive/refs/heads/main.zip) and extract.
- Put the Winget Application IDs you want to install in bulk in "apps_to_install.txt" file.
- Put the Winget Application IDs in "excluded_apps.txt" file to exclude them from daily upgrade job. By defaut, if this file is not present, it will use the default one from Winget-AutoUpgrade repo.
- Then, run "install.bat"

### - Online from Powershell Directly
Basically useful on fresh Windows install
- Open Command Prompt as Admin
- Run this command:

`Powershell.exe Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Romanitho/Winget-AllinOne/main/Winget-AllinOne.ps1'))`

- Select Apps you want to install (Ctrl + click)

![image](https://user-images.githubusercontent.com/96626929/162642474-322e3a22-2a7d-4b89-a016-f8377c4a9ce9.png)

- Click OK
