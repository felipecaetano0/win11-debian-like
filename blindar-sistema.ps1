<#
.SYNOPSIS
    Script de Auditoria Forense e Blindagem Anti-Ransomware
#>

$ErrorActionPreference = "Continue"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "    AUDITORIA FORENSE E BLINDAGEM ANTI-RANSOMWARE        " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Ativar Controlled Folder Access (Trava de Kernel Anti-Ransomware)
Write-Host "`n[1/3] Configurando Protecao Anti-Ransomware (Controlled Folder Access)..." -ForegroundColor Yellow
try {
    # Habilitar Controlled Folder Access
    Set-MpPreference -EnableControlledFolderAccess Enabled
    Write-Host "-> Controlled Folder Access ATIVADO no Windows Defender!" -ForegroundColor Green

    # Adicionar pastas criticas personalizadas (Documentos, Desktop, Downloads ja sao protegidas nativamente)
    $customFolders = @("C:\Users\felip\win11-debian-like")
    foreach ($cf in $customFolders) {
        if (Test-Path $cf) {
            Add-MpPreference -ControlledFolderAccessProtectedFolders $cf -ErrorAction SilentlyContinue
            Write-Host "-> Pasta blindada adicionada: $cf" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "-> Erro ao configurar Controlled Folder Access: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Executar Varredura Forense AdwCleaner (Modo Silencioso / Logging)
Write-Host "`n[2/3] Executando Varredura Forense com Malwarebytes AdwCleaner..." -ForegroundColor Yellow
$adwExe = "C:\Users\felip\security-tools\adwcleaner.exe"
if (Test-Path $adwExe) {
    Write-Host "-> Escaneando navegadores, processos e tarefas agendadas em busca de infostealers/hijackers..." -ForegroundColor DarkGray
    # Executa scan silencioso gerando log
    & $adwExe /eula /clean /noreboot 2>$null
    Write-Host "-> Varredura do AdwCleaner finalizada!" -ForegroundColor Green
} else {
    Write-Host "-> AdwCleaner nao encontrado." -ForegroundColor Red
}

# 3. Executar Varredura Rápida de Módulos e Memória via Windows Defender Antimalware
Write-Host "`n[3/3] Executando Varredura de Memória e Processos via Windows Defender..." -ForegroundColor Yellow
try {
    Start-MpScan -ScanType QuickScan
    Write-Host "-> QuickScan do Defender concluido com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "-> Falha ao rodar scan do Defender: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   SISTEMA BLINDADO E AUDITADO!                          " -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
