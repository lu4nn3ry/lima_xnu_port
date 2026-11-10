# stage1/build.ps1
# Compila o Stage 1 Bare-Metal Loader para ARMv7-A e gera stage1-boot.img

$ErrorActionPreference = "Stop"

$Stage1Dir = $PSScriptRoot
Set-Location $Stage1Dir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  COMPILANDO STAGE 1 LOADER (ARMv7-A)     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Compilar assembly de entrada
Write-Host "`n[1/4] Compilando entry.S..." -ForegroundColor Yellow
clang -target armv7a-none-eabi -march=armv7-a -c entry.S -o entry.o
Write-Host "  -> entry.o gerado com sucesso." -ForegroundColor Green

# 2. Compilar logica C
Write-Host "`n[2/4] Compilando main.c..." -ForegroundColor Yellow
clang -target armv7a-none-eabi -march=armv7-a -O2 `
    -ffreestanding -fno-builtin -nostdlib `
    -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables `
    -c main.c -o main.o
Write-Host "  -> main.o gerado com sucesso." -ForegroundColor Green

# 3. Linkar binario flat em 0x40008000
Write-Host "`n[3/4] Linkando stage1.bin em 0x40008000..." -ForegroundColor Yellow
ld.lld -T stage1.ld entry.o main.o -o stage1.bin --oformat=binary
$binSize = (Get-Item stage1.bin).Length
Write-Host "  -> stage1.bin gerado ($binSize bytes)." -ForegroundColor Green

# 4. Empacotar Android Boot Image v2
Write-Host "`n[4/4] Empacotando stage1-boot.img..." -ForegroundColor Yellow
python mkbootimg.py stage1.bin stage1-boot.img
$imgSize = (Get-Item stage1-boot.img).Length
Write-Host "  -> stage1-boot.img pronto ($imgSize bytes)!" -ForegroundColor Green

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  BUILD CONCLUIDO COM SUCESSO!            " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Arquivo pronto para teste no Slot B: $Stage1Dir\stage1-boot.img"
