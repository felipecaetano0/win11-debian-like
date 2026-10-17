$ErrorActionPreference = "Continue"
$logFile = "C:\Users\felip\.gemini\antigravity\scratch\admin_debloat.log"
Start-Transcript -Path $logFile -Force

Write-Host "=== 1. CRIANDO PONTO DE RESTAURACAO DE SEGURANCA ===" -ForegroundColor Cyan
Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
Checkpoint-Computer -Description "Antes_Otimizacao_DebianLike" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue

Write-Host "`n=== 2. LIMPANDO CHAVES RUN DO SISTEMA (HKLM) ===" -ForegroundColor Cyan
$hklmRun = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
foreach ($item in @("Logitech Download Assistant", "Logi Download Assistant")) {
    if (Get-ItemProperty -Path $hklmRun -Name $item -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $hklmRun -Name $item -ErrorAction SilentlyContinue
        Write-Host "Removido de HKLM Run: $item"
    }
}

Write-Host "`n=== 3. APLICANDO POLITICAS DE SISTEMA (SEM BING, SEM EDGE BACKGROUND, SEM TELEMETRIA) ===" -ForegroundColor Cyan
New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0 -Type DWord

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord

# Desativar Hibernacao / Fast Startup para boot limpo estilo Debian
powercfg /h off

Write-Host "`n=== 4. PARANDO E DESATIVANDO SERVICOS DE TELEMETRIA E BLOAT ===" -ForegroundColor Cyan
$servicesToDisable = @(
    "DiagTrack",                  # Telemetria Microsoft
    "dmwappushservice",           # Roteamento de telemetria
    "MapsBroker",                 # Mapas em segundo plano
    "RetailDemo",                 # Servico de demonstracao de loja
    "FoxitReaderUpdateService",   # Updater Foxit constante
    "dptftcs",                    # Telemetria Intel Dynamic Tuning
    "UDCService",                 # Telemetria Lenovo Universal Device Client
    "GAService",                  # Lenovo Gaming AI Service
    "AISpeechService",            # AISpeech Control Service
    "LenovoVantageService",       # Lenovo Vantage (sera substituido pelo Legion Toolkit)
    "SmartConnect",               # Motorola/Lenovo SmartConnect
    "CCleaner7",                  # CCleaner 7
    "McAfee WebAdvisor",          # McAfee WebAdvisor
    "Warsaw Technology"           # Modulo bancario Warsaw (core.exe)
)

foreach ($svc in $servicesToDisable) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Write-Host "Parando e desativando servico: $svc ($($s.DisplayName))"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== 5. ENCERRANDO PROCESSOS PESADOS DESNECESSARIOS AGORA ===" -ForegroundColor Cyan
$procsToKill = @("core", "CCleaner*", "McAfee*", "LenovoVantage*", "Lenovo.Modern*", "steam", "steamwebhelper", "ms-teams")
foreach ($p in $procsToKill) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== 6. DESINSTALANDO CCLEANER, MCAFEE E WARSAW VIA WINGET ===" -ForegroundColor Cyan
winget uninstall --id "Piriform.CCleaner" --silent --accept-source-agreements
winget uninstall --id "ARP\Machine\X86\{35ED3F83-4BDC-4c44-8EC6-6A8301C7413A}" --silent --accept-source-agreements
winget uninstall --id "ARP\Machine\X64\{20E60725-16C8-4FB9-8BC2-AF92C5F8D06D}_is1" --silent --accept-source-agreements
winget uninstall "Windows Web Experience Pack" --silent --accept-source-agreements

Write-Host "`n=== 7. INSTALANDO LENOVO LEGION TOOLKIT (SUBSTITUTO LEVE DO VANTAGE) ===" -ForegroundColor Cyan
winget install --id "BartoszCichecki.LenovoLegionToolkit" --silent --accept-package-agreements --accept-source-agreements

Write-Host "`n=== CONCLUIDO COM SUCESSO! ===" -ForegroundColor Green
Stop-Transcript
