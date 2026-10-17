Write-Host "=== ENCERRANDO E DESATIVANDO BLOATWARE RESIDUAL E SPOOLER ===" -ForegroundColor Cyan

# 1. Desativar servicos residuais
$services = @(
    "Spooler",
    "NahimicService",
    "FoxitReaderUpdateService",
    "FoxitPDFReaderUpdateService",
    "UDCService",
    "LenovoSmartService",
    "LSDaemon",
    "LenovoUtilityService",
    "ReadyForService"
)

foreach ($s in $services) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "Parando e desativando: $s ($($svc.DisplayName))"
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# 2. Encerrar processos remanescentes
$procs = @("Nahimic*", "nahimicNotifSys", "Foxit*Update*", "LenovoNow*", "VantageBridge*")
foreach ($p in $procs) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== STATUS ATUAL DOS PROCESSOS E MEMORIA ===" -ForegroundColor Green
$os = Get-CimInstance Win32_OperatingSystem
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB = [math]::Round($totalRamGB - $freeRamGB, 2)
$procCount = (Get-Process).Count

Write-Host "Processos ativos: $procCount"
Write-Host "RAM em uso: $usedRamGB GB / $totalRamGB GB (Livre: $freeRamGB GB)"
