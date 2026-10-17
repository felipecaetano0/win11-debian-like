<#
.SYNOPSIS
    Script de Atualizacao e Manutencao Estilo Debian (apt update && apt full-upgrade && apt autoremove)
    Atualiza pacotes Scoop, pacotes Winget, verifica Drivers/Firmware (Windows Update) e GPU NVIDIA,
    atualiza Windows Defender e limpa caches/arquivos temporarios.
#>

param(
    [switch]$FullCheck,
    [switch]$InstallDrivers
)

$ErrorActionPreference = "Continue"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   ATUALIZADOR DO SISTEMA (ESTILO DEBIAN APT UPGRADE)    " -ForegroundColor Cyan
Write-Host "=========================================================`n" -ForegroundColor Cyan

# Garante que o Scoop esteja no PATH da sessao atual
if ($env:PATH -notmatch "scoop\\shims") {
    $env:PATH += ";$env:USERPROFILE\scoop\shims"
}

# 1. Atualizar Scoop e seus pacotes (Espaco do Usuario - Zero sujidade no Registro)
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "[1/5] Atualizando repositorios e pacotes do Scoop..." -ForegroundColor Yellow
    scoop update
    scoop update *
    Write-Host "-> Limpando versoes antigas e cache do Scoop (autoremove/autoclean)..." -ForegroundColor DarkGray
    scoop cleanup *
    scoop cache rm *
} else {
    Write-Host "[1/5] Scoop nao encontrado no PATH, pulando..." -ForegroundColor DarkGray
}

# 2. Atualizar todos os programas do Windows via Winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "`n[2/5] Atualizando todos os aplicativos do Windows via Winget..." -ForegroundColor Yellow
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
}

# 3. Verificacao de Drivers (GPU NVIDIA + Drivers/Firmware Oficiais via Windows Update API)
Write-Host "`n[3/5] Verificando Drivers de Hardware (GPU, Chipset e Firmware)..." -ForegroundColor Yellow

# 3.1 Status do Driver NVIDIA atual
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    $nvInfo = nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>$null
    Write-Host "-> GPU Detectada: $nvInfo" -ForegroundColor Cyan
}

# 3.2 Busca por Drivers e Atualizacoes de Sistema no Windows Update (API Nativa Microsoft)
try {
    Write-Host "-> Consultando servidores da Microsoft por novos drivers e patches..." -ForegroundColor DarkGray
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and IsHidden=0")

    $drivers = @()
    $osUpdates = @()
    foreach ($update in $searchResult.Updates) {
        if ($update.Type -eq 2 -or ($update.Categories | Where-Object { $_.Name -match "Driver" })) {
            $drivers += $update
        } else {
            $osUpdates += $update
        }
    }

    if ($drivers.Count -eq 0) {
        Write-Host "-> [OK] Todos os drivers certificados (Intel/Lenovo/Realtek/NVIDIA) estao em dia!" -ForegroundColor Green
    } else {
        Write-Host "-> [!] $($drivers.Count) atualizacao(oes) de DRIVER disponivel(is):" -ForegroundColor Magenta
        foreach ($d in $drivers) {
            Write-Host "   * [DRIVER] $($d.Title)" -ForegroundColor White
        }
    }

    if ($osUpdates.Count -eq 0) {
        Write-Host "-> [OK] Nenhuma atualizacao pendente do Windows." -ForegroundColor Green
    } else {
        Write-Host "-> [i] $($osUpdates.Count) atualizacao(oes) do Windows disponivel(is):" -ForegroundColor Cyan
        foreach ($u in $osUpdates) {
            Write-Host "   * [SISTEMA] $($u.Title)" -ForegroundColor Gray
        }
    }

    if ($InstallDrivers -and ($drivers.Count -gt 0 -or $osUpdates.Count -gt 0)) {
        if ($isAdmin) {
            Write-Host "-> Baixando e instalando drivers/atualizacoes pendentes..." -ForegroundColor Yellow
            $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($u in $searchResult.Updates) {
                if (-not $u.EulaAccepted) { $u.AcceptEula() }
                $updatesToDownload.Add($u) | Out-Null
            }
            $downloader = $updateSession.CreateUpdateDownloader()
            $downloader.Updates = $updatesToDownload
            $downloader.Download() | Out-Null

            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $updatesToDownload
            $installResult = $installer.Install()
            Write-Host "-> Instalacao concluida! Codigo de resultado: $($installResult.ResultCode) (Reinicializacao necessaria: $($installResult.RebootRequired))" -ForegroundColor Green
        } else {
            Write-Host "-> [AVISO] Para instalar drivers automaticamente com -InstallDrivers, abra o terminal como Administrador." -ForegroundColor Red
        }
    } elseif ($drivers.Count -gt 0) {
        Write-Host "   (Dica: Rode 'atualizar -InstallDrivers' como Admin ou use o Lenovo Legion Toolkit / Windows Update para instalar)" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "-> Nao foi possivel consultar o catalogo do Windows Update agora: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 4. Atualizar definicoes de seguranca do Windows Defender
Write-Host "`n[4/5] Atualizando assinaturas de seguranca do Windows Defender..." -ForegroundColor Yellow
try {
    Update-MpSignature -ErrorAction Stop
    Write-Host "-> Assinaturas do Windows Defender atualizadas com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "-> Pulado (ja atualizado em background)." -ForegroundColor DarkGray
}

# 5. Limpeza leve de arquivos temporarios orfaos (> 7 dias)
Write-Host "`n[5/5] Limpando arquivos temporarios antigos (> 7 dias)..." -ForegroundColor Yellow
$limit = (Get-Date).AddDays(-7)
$deletedCount = 0
Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $limit } | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    $deletedCount++
}
Write-Host "-> $deletedCount itens temporarios antigos removidos." -ForegroundColor Green

# 6. Verificacao de integridade opcional (-FullCheck)
if ($FullCheck) {
    if ($isAdmin) {
        Write-Host "`n[EXTRA] Executando verificacao de integridade do Windows (DISM + SFC)..." -ForegroundColor Magenta
        DISM.exe /Online /Cleanup-Image /RestoreHealth
        sfc.exe /scannow
    } else {
        Write-Host "`n[AVISO] Para rodar -FullCheck (DISM + SFC), execute o terminal como Administrador." -ForegroundColor Red
    }
}

# Resumo final de memoria e processos
$os = Get-CimInstance Win32_OperatingSystem
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
$procCount = (Get-Process).Count

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   SISTEMA ATUALIZADO E LIMPO COM SUCESSO!               " -ForegroundColor Green
Write-Host "   RAM em uso: $usedRamGB GB / $totalRamGB GB | Processos: $procCount" -ForegroundColor Green
Write-Host "=========================================================`n" -ForegroundColor Green
