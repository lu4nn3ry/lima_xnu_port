# Dump de particoes com root (Magisk) — `lima_32`
#
# Requer: aparelho em Android, depuracao USB autorizada, e root ativo (Magisk).
# Faz: dd de cada particao em /dev/block/by-name para /sdcard/lima-dump/,
#      depois puxa para o PC e gera manifest SHA-256.
#
# NAO escreve em nenhuma particao do aparelho.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tools\dump-partitions.ps1
#   powershell -ExecutionPolicy Bypass -File tools\dump-partitions.ps1 -IncludeUserdata
#   powershell -ExecutionPolicy Bypass -File tools\dump-partitions.ps1 -Only boot_a,dtb_a,dtbo_a

param(
    [string]$Adb = "C:\Users\luann\Downloads\platform-tools\adb.exe",
    [string]$OutRoot = "dumps",
    [switch]$IncludeUserdata,
    [string[]]$Only = @()
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Adb)) { throw "adb nao encontrado: $Adb" }
if (-not (& $Adb devices | Select-String "device$")) { throw "nenhum aparelho em modo adb" }

$id = (& $Adb shell "su -c id" 2>&1) -join ""
if ($id -notmatch "uid=0") { throw "sem root. Instale/ative o Magisk primeiro. (resposta: $id)" }
Write-Host "root: OK"

$stamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$remote = "/sdcard/lima-dump"
$dest = Join-Path $OutRoot "partitions-$stamp"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# lista de particoes
$names = (& $Adb shell "ls /dev/block/by-name") -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($Only.Count -gt 0) { $names = $names | Where-Object { $Only -contains $_ } }
if (-not $IncludeUserdata) { $names = $names | Where-Object { $_ -ne "userdata" -and $_ -ne "mmcblk0" -and $_ -ne "mmcblk0rpmb" } }
Write-Host ("particoes: " + $names.Count)

& $Adb shell "rm -rf $remote; mkdir -p $remote"

$manifest = @()
foreach ($n in $names) {
    # tamanho em bytes via blockdev (root)
    $sz = (& $Adb shell "su -c 'blockdev --getsize64 /dev/block/by-name/$n'" 2>&1) -join ""
    $sz = $sz.Trim()
    Write-Host ("{0,-20} {1,12} bytes" -f $n, $sz)
    & $Adb shell "su -c 'dd if=/dev/block/by-name/$n of=$remote/$n.img bs=4M 2>/dev/null'"
    $manifest += [pscustomobject]@{ name = $n; size = $sz }
}

Write-Host "puxando arquivos..."
& $Adb pull "$remote/." $dest | Out-Null

# manifesto com hash
$lines = @()
foreach ($f in Get-ChildItem $dest -File) {
    $h = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower()
    $lines += "$h  $($f.Name)"
}
$lines | Set-Content (Join-Path $dest "SHA256SUMS") -Encoding ASCII
$manifest | Export-Csv (Join-Path $dest "sizes.csv") -NoTypeInformation -Encoding ASCII

Write-Host ("pronto: {0} arquivos em {1}" -f (Get-ChildItem $dest -File).Count, $dest)
Write-Host "copie este diretorio para uma segunda midia."
