# Backup de /sdcard (dados pessoais) — `lima_32`
#
# O que faz:
#   - verifica se o aparelho esta no Android (adb), nao no fastboot;
#   - copia /sdcard para dumps/sdcard-AAAA-MM-DD-HHMMSS/;
#   - gera manifest.sha256 de tudo que foi copiado;
#   - grava um log da operacao.
#
# O que NAO faz:
#   - nao escreve nada no aparelho (somente leitura via adb pull);
#   - nao faz root, nao instala nada, nao reinicia o aparelho.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tools\backup-sdcard.ps1
#   powershell -ExecutionPolicy Bypass -File tools\backup-sdcard.ps1 -Adb "C:\caminho\adb.exe"

param(
    [string]$Adb = "C:\Users\luann\Downloads\platform-tools\adb.exe",
    [string]$OutRoot = "dumps"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Adb)) {
    Write-Error "adb nao encontrado em: $Adb"
    exit 1
}

$devices = & $Adb devices | Select-String "device$"
if (-not $devices) {
    Write-Error "nenhum aparelho em modo adb. Saia do fastboot primeiro (fastboot reboot) e autorize a depuracao USB."
    exit 1
}

$stamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$dest = Join-Path $OutRoot "sdcard-$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
$log = Join-Path $dest "backup.log"

function Log($msg) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Write-Host $line
    Add-Content -Path $log -Value $line
}

Log "destino: $dest"
Log ("modelo: " + (& $Adb shell getprop ro.product.model).Trim())
Log ("build:  " + (& $Adb shell getprop ro.build.fingerprint).Trim())

$size = (& $Adb shell "du -sh /sdcard 2>/dev/null").Trim()
Log "tamanho de /sdcard: $size"

Log "copiando /sdcard (pode demorar; nao interrompa)"
& $Adb pull /sdcard/. $dest
if ($LASTEXITCODE -ne 0) {
    Log "aviso: adb pull retornou codigo $LASTEXITCODE (arquivos em uso/ilegiveis sao normais)"
}
Log "copia concluida"

Log "gerando manifest.sha256"
$files = Get-ChildItem -Path $dest -Recurse -File | Where-Object { $_.Name -notin @("backup.log", "manifest.sha256") }
$manifest = Join-Path $dest "manifest.sha256"
foreach ($f in $files) {
    $h = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash.ToLower()
    $rel = $f.FullName.Substring($dest.Length + 1).Replace("\", "/")
    "$h  $rel" | Add-Content -Path $manifest
}
Log ("arquivos: {0}; manifest: {1}" -f $files.Count, $manifest)

Log "pronto. Guarde uma segunda copia em outra midia."
