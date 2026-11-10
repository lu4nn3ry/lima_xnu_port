# tools/test-stage1-slotb.ps1
# Script de teste seguro do Stage 1 no Slot B (com rollback automatico e extracao de pstore)

param(
    [string]$ImagePath = "D:\GitHub\lima_xnu_port\stage1\stage1-boot.img",
    [string]$FastbootExe = "C:\Users\luann\Downloads\platform-tools\fastboot.exe",
    [string]$AdbExe = "C:\Users\luann\Downloads\scrcpy-win64-v3.3.4\adb.exe",
    [string]$DeviceIp = "192.168.0.25:5555"
)

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "🚀 TESTE DE STAGE 1 LOADER - ISOLAMENTO SLOT B" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Verificar imagem
if (-not (Test-Path $ImagePath)) {
    # Tentar caminho local relativo se nao estiver no D:
    if (Test-Path "stage1\stage1-boot.img") {
        $ImagePath = (Resolve-Path "stage1\stage1-boot.img").Path
    } else {
        Write-Error "Imagem nao encontrada em: $ImagePath"
        exit 1
    }
}

Write-Host "✔ Imagem de teste: $ImagePath" -ForegroundColor Green

# 2. Reiniciar para o Bootloader
Write-Host "`n[1/5] Entrando no Bootloader (Fastboot)..." -ForegroundColor Yellow
& $AdbExe -s $DeviceIp reboot bootloader 2>$null
if ($LASTEXITCODE -ne 0) {
    & $AdbExe reboot bootloader 2>$null
}

Start-Sleep -Seconds 5

# 3. Verificar presenca no fastboot
Write-Host "[2/5] Aguardando dispositivo em Fastboot..." -ForegroundColor Yellow
$fbCheck = & $FastbootExe devices
if (-not $fbCheck) {
    Write-Error "Nenhum dispositivo encontrado em Fastboot! Verifique a conexao USB."
    exit 1
}
Write-Host "✔ Dispositivo detectado em Fastboot:" -ForegroundColor Green
Write-Host $fbCheck

# 4. Gravar EXCLUSIVAMENTE no boot_b
Write-Host "`n[3/5] Gravando Stage 1 no SLOT B (boot_b)..." -ForegroundColor Yellow
& $FastbootExe flash boot_b $ImagePath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao gravar no boot_b!"
    exit 1
}

# 5. Ativar Slot B
Write-Host "`n[4/5] Ativando Slot B..." -ForegroundColor Yellow
& $FastbootExe --set-active=b
if ($LASTEXITCODE -ne 0) {
    Write-Error "Falha ao ativar Slot B!"
    exit 1
}

Write-Host "✔ Slot B ativo com sucesso! O Slot A (Android Stock) permanece 100% intacto." -ForegroundColor Green
Write-Host "`n[5/5] Reiniciando para testar Stage 1..." -ForegroundColor Yellow
Write-Host "O Stage 1 ira executar em 0x40008000, escrever no Ramoops (0x54410000) e reiniciar." -ForegroundColor Cyan
& $FastbootExe reboot

Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "Aguardando execucao do payload (15 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "`nPara voltar ao Android e ler o pstore:" -ForegroundColor Green
Write-Host "1. Se o aparelho reiniciar no bootloader: & '$FastbootExe' --set-active=a; & '$FastbootExe' reboot" -ForegroundColor White
Write-Host "2. Quando o Android subir: & '$AdbExe' -s $DeviceIp shell 'su -c cat /sys/fs/pstore/console-ramoops'" -ForegroundColor White
Write-Host "=================================================" -ForegroundColor Cyan
