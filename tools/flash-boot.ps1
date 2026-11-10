# Grava o boot patchado pelo Magisk — `lima_32`
#
# UNICA operacao deste projeto que escreve no aparelho.
# Escreve somente `boot` (slot ativo) e exige -Confirm.
#
# Pre-requisitos:
#   - boot.img original guardado (para rollback);
#   - imagem patchada pelo Magisk (magisk_patched-*.img);
#   - aparelho em fastboot, bootloader desbloqueado.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tools\flash-boot.ps1 `
#       -Patched dumps\magisk_patched.img -Stock dumps\firmware\boot.img -Confirm

param(
    [Parameter(Mandatory = $true)][string]$Patched,
    [string]$Stock,
    [string]$Adb = "C:\Users\luann\Downloads\platform-tools\adb.exe",
    [string]$Fastboot = "C:\Users\luann\Downloads\platform-tools\fastboot.exe",
    [switch]$Confirm
)

$ErrorActionPreference = "Stop"

if (-not $Confirm) { throw "recusado: use -Confirm explicitamente" }
if (-not (Test-Path $Patched)) { throw "imagem patchada nao encontrada: $Patched" }
if ($Stock -and -not (Test-Path $Stock)) { throw "imagem stock nao encontrada: $Stock" }

# --- validacao: assinatura de boot image Android ---
$bytes = [IO.File]::ReadAllBytes((Resolve-Path $Patched))
$magic = [Text.Encoding]::ASCII.GetString($bytes, 0, 8)
if ($magic -ne "ANDROID!") { throw "nao parece um boot.img Android (magic='$magic')" }
Write-Host ("imagem: {0} bytes, magic OK" -f $bytes.Length)

# --- dispositivo em fastboot? ---
$dev = (& $Fastboot devices) | Select-String "fastboot"
if (-not $dev) { throw "nenhum aparelho em fastboot. Rode: adb reboot bootloader" }
Write-Host ("fastboot: " + $dev.ToString().Trim())

$ErrorActionPreference = "Continue"
$slotOut = & $Fastboot getvar current-slot 2>&1
$slot = ($slotOut | Out-String).Trim()
$ErrorActionPreference = "Stop"
Write-Host ("slot ativo: " + $slot)

Write-Host ""
Write-Host "VAI ESCREVER: boot (slot ativo) <- $Patched"
if ($Stock) { Write-Host "ROLLBACK:     fastboot flash boot $Stock" }

& $Fastboot flash boot $Patched
if ($LASTEXITCODE -ne 0) { throw "falha ao gravar boot" }

& $Fastboot reboot
Write-Host "gravado. Se nao bootar: entre em fastboot e restaure a imagem stock."
