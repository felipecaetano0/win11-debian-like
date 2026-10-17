<#
.SYNOPSIS
    Script de configuracao rapida (Bootstrap) para novas instalacoes ou para reaplicar o setup.
#>

param(
    [switch]$SkipElevated
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "    SETUP WINDOWS 11 DEBIAN-LIKE (BOOTSTRAP)             " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Garantir Scoop
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "`n[1/4] Instalando Scoop..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

if ($env:PATH -notmatch "scoop\\shims") {
    $env:PATH += ";$env:USERPROFILE\scoop\shims"
}

# 2. Instalar baldes e ferramentas essenciais
Write-Host "`n[2/4] Configurando baldes e instalando ferramentas essenciais via Scoop..." -ForegroundColor Yellow
scoop bucket add extras 2>$null
scoop install 7zip geekuninstaller everything gh 2>$null

# 3. Configurar atalhos de atualizacao global (atualizar / apt-upgrade)
Write-Host "`n[3/4] Criando atalhos de comando 'atualizar' e 'apt-upgrade'..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$atualizarScript = Join-Path $scriptDir "atualizar-sistema.ps1"

# Copiar script para home caso nao esteja la
$targetScript = "C:\Users\felip\atualizar-sistema.ps1"
if (-not (Test-Path $targetScript)) {
    Copy-Item $atualizarScript $targetScript -Force
}

$shimDir = "$env:USERPROFILE\scoop\shims"
if (Test-Path $shimDir) {
    $cmdShim = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$targetScript`" %*"
    Set-Content -Path "$shimDir\atualizar.cmd" -Value $cmdShim -Encoding ASCII
    Set-Content -Path "$shimDir\apt-upgrade.cmd" -Value $cmdShim -Encoding ASCII
}

# Atalho na Area de Trabalho
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Atualizar Sistema.lnk"
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($shortcutPath)
$sc.TargetPath = "powershell.exe"
$sc.Arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$targetScript`""
$sc.WorkingDirectory = "C:\Users\felip"
$sc.IconLocation = "shell32.dll,46"
$sc.Description = "Atualiza todos os pacotes do Windows (Winget + Scoop), verifica drivers e limpa caches"
$sc.Save()

Write-Host "`n[4/4] Limpando inicializacao do usuario..." -ForegroundColor Yellow
$hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$toRemoveRun = @("Steam", "electron.app.Notion", "Teams", "Docker Desktop", "LenovoVantage", "GoogleChromeAutoLaunch*")
foreach ($item in $toRemoveRun) {
    Get-ItemProperty -Path $hkcuRun -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like $item } | ForEach-Object {
        Remove-ItemProperty -Path $hkcuRun -Name $_.Name -ErrorAction SilentlyContinue
        Write-Host "Removido do boot: $($_.Name)" -ForegroundColor Green
    }
}

if (-not $SkipElevated) {
    Write-Host "`nPara aplicar as politicas de sistema, servicos e desinstalar bloatware pesado:" -ForegroundColor Cyan
    Write-Host "Execute o Terminal como Administrador e rode:" -ForegroundColor White
    Write-Host "powershell -ExecutionPolicy Bypass -File `"$scriptDir\admin_debloat.ps1`"" -ForegroundColor Yellow
}

Write-Host "`nSetup concluido com sucesso!" -ForegroundColor Green
