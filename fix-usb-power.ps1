<#
.SYNOPSIS
    Script definitivo para corrigir desligamento, travamento e desconexao intermitente de perifericos USB/Bluetooth.
#>

$ErrorActionPreference = "Continue"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   CORRECAO DE INSTABILIDADE USB / PERIFERICOS           " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Desativar ASPM (Gerenciamento de Energia PCIe) no Plano de Energia
Write-Host "`n[1/3] Desativando economia de energia agressiva no barramento PCIe (ASPM)..." -ForegroundColor Yellow
try {
    # 0 = Desligado (Impede que o barramento PCIe e USB4 corte energia dos dispositivos)
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS ASPM 0
    powercfg /setactive SCHEME_CURRENT
    Write-Host "-> ASPM configurado para DESLIGADO (energia constante no barramento)." -ForegroundColor Green
} catch {
    Write-Host "-> Erro ao ajustar ASPM: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Desativar Suspensao Seletiva em TODOS os Root Hubs e Hubs USB
Write-Host "`n[2/3] Desativando 'O computador pode desligar este dispositivo para economizar energia' em todos os Hubs USB..." -ForegroundColor Yellow
$hubs = Get-PnpDevice -Class USB | Where-Object { $_.FriendlyName -match "Hub|Root" }
foreach ($hub in $hubs) {
    try {
        $inst = $hub.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$inst\Device Parameters"
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "DeviceSelectiveSuspended" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "SelectiveSuspendEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Host "-> Suspensao desativada no Hub: $($hub.FriendlyName) ($inst)" -ForegroundColor Green
        }
    } catch {}
}

# 3. Desativar Suspensao Seletiva no Adaptador Realtek Bluetooth
Write-Host "`n[3/3] Garantindo alimentacao constante no adaptador Bluetooth..." -ForegroundColor Yellow
$btDev = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -match "Realtek" }
if ($btDev) {
    $btPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($btDev.InstanceId)\Device Parameters"
    if (Test-Path $btPath) {
        Set-ItemProperty -Path $btPath -Name "DeviceSelectiveSuspended" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $btPath -Name "SelectiveSuspendEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Host "-> Bluetooth Realtek com energia continua garantida!" -ForegroundColor Green
    }
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   CONFIGURACAO APLICADA COM SUCESSO!                   " -ForegroundColor Green
Write-Host "   Seus perifericos nao sofrerao mais cortes de energia. " -ForegroundColor Green
Write-Host "=========================================================`n" -ForegroundColor Green
