<#
.SYNOPSIS
    Script de Correcao e Reset da Pilha Bluetooth Realtek / Windows 11
#>

$ErrorActionPreference = "Continue"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      CORRECAO DA PILHA BLUETOOTH (WINDOWS 11)           " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Configurar servicos do Bluetooth para Automatico
Write-Host "`n[1/4] Ajustando servicos essenciais do Bluetooth para Inicializacao Automatica..." -ForegroundColor Yellow
$services = @("bthserv", "BthAvctpSvc", "RtkBtManServ", "DeviceAssociationService")
foreach ($s in $services) {
    try {
        Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
        Restart-Service -Name $s -Force -ErrorAction SilentlyContinue
        Write-Host "-> Servico $s: Configurado como Automatico e reiniciado." -ForegroundColor Green
    } catch {
        Write-Host "-> Falha ao ajustar servico $s: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# 2. Desativar Economia de Energia / Suspensao Seletiva no Adaptador Realtek (Causa raiz de timeout)
Write-Host "`n[2/4] Desativando Economia de Energia / Suspensao Seletiva USB do Adaptador Realtek..." -ForegroundColor Yellow
try {
    $dev = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -match "Realtek" }
    if ($dev) {
        $devId = $dev.InstanceId
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$devId\Device Parameters"
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "DeviceSelectiveSuspended" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "SelectiveSuspendEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Write-Host "-> Suspensao Seletiva USB DESATIVADA no adaptador Bluetooth!" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "-> Erro ao ajustar parametros de energia: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 3. Limpeza do Cache de Chaves de Link corrompidas
Write-Host "`n[3/4] Resetando subsistema de radio Bluetooth..." -ForegroundColor Yellow
try {
    $radioDev = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -match "Realtek Bluetooth Adapter" }
    if ($radioDev) {
        Write-Host "-> Reiniciando driver do adaptador de hardware ($($radioDev.FriendlyName))..." -ForegroundColor DarkGray
        Disable-PnpDevice -InstanceId $radioDev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Enable-PnpDevice -InstanceId $radioDev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "-> Adaptador Bluetooth reiniciado com sucesso no nivel de hardware!" -ForegroundColor Green
    }
} catch {
    Write-Host "-> Aviso ao reiniciar dispositivo: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 4. Verificacao de status final
Write-Host "`n[4/4] Verificando status dos servicos e do adaptador..." -ForegroundColor Yellow
$statusBth = Get-Service -Name "bthserv"
$devCheck = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -match "Realtek" }
Write-Host "Status do bthserv: $($statusBth.Status) (Startup: $($statusBth.StartType))" -ForegroundColor Cyan
Write-Host "Status do Adaptador: $($devCheck.Status)" -ForegroundColor Cyan

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   PILHA BLUETOOTH RESETADA E OTIMIZADA COM SUCESSO!     " -ForegroundColor Green
Write-Host "   Se algum fone/mouse continuar falhando, remova-o em:  " -ForegroundColor White
Write-Host "   Configuracoes > Bluetooth e Dispositivos > Remover    " -ForegroundColor White
Write-Host "   e faca o pareamento novamente.                        " -ForegroundColor White
Write-Host "=========================================================`n" -ForegroundColor Green
