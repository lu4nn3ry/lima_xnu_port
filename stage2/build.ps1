# stage2/build.ps1
# Compila o Stage 2 Loader (ARMv7-A) com MMU 1:1, GICv3 e Timer 13MHz

$ErrorActionPreference = "Stop"

$Stage2Dir = $PSScriptRoot
Set-Location $Stage2Dir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  COMPILANDO STAGE 2 LOADER (ARMv7-A)     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Compilar assembly de entrada
Write-Host "`n[1/5] Compilando entry.S..." -ForegroundColor Yellow
clang -target armv7a-none-eabi -march=armv7-a -c entry.S -o entry.o
Write-Host "  -> entry.o gerado com sucesso." -ForegroundColor Green

# 2. Compilar modulos C
$cFlags = "-target armv7a-none-eabi -march=armv7-a -O2 -ffreestanding -fno-builtin -nostdlib -fno-exceptions -fno-unwind-tables -fno-asynchronous-unwind-tables -c"

Write-Host "`n[2/5] Compilando mmu.c..." -ForegroundColor Yellow
clang $cFlags.Split(' ') mmu.c -o mmu.o

Write-Host "[3/5] Compilando gicv3.c e timer.c..." -ForegroundColor Yellow
clang $cFlags.Split(' ') gicv3.c -o gicv3.o
clang $cFlags.Split(' ') timer.c -o timer.o
clang $cFlags.Split(' ') main.c -o main.o
Write-Host "  -> Objetos C gerados com sucesso." -ForegroundColor Green

# 3. Linkar binario flat em 0x40008000
Write-Host "`n[4/5] Linkando stage2.bin em 0x40008000..." -ForegroundColor Yellow
ld.lld -T stage2.ld entry.o mmu.o gicv3.o timer.o main.o -o stage2.bin --oformat=binary
$binSize = (Get-Item stage2.bin).Length
Write-Host "  -> stage2.bin gerado ($binSize bytes)." -ForegroundColor Green

# 4. Empacotar Android Boot Image v2
Write-Host "`n[5/5] Empacotando stage2-boot.img..." -ForegroundColor Yellow
python mkbootimg.py stage2.bin stage2-boot.img
$imgSize = (Get-Item stage2-boot.img).Length
Write-Host "  -> stage2-boot.img pronto ($imgSize bytes)!" -ForegroundColor Green

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  BUILD CONCLUIDO COM SUCESSO!            " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Arquivo pronto: $Stage2Dir\stage2-boot.img"
