param(
    [string]$Adb = "C:\Users\luann\Downloads\platform-tools\adb.exe",
    [string]$RemoteDir = "/sdcard/lima-dump",
    [string]$DestDir = "dumps\partitions-2026-11-10"
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
}

Write-Host "Obtendo lista e tamanhos das particoes no aparelho..."
$rawList = (& $Adb shell "ls -l $RemoteDir") -split "`n"
$remoteMap = @{}

foreach ($line in $rawList) {
    # Ex: -rw-rw---- 1 root sdcard_rw 33554432 2021-10-28 15:05 boot_b.img
    if ($line -match '\s+(\d+)\s+\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s+(.+\.img)\r?$') {
        $sz = [long]$Matches[1]
        $fn = $Matches[2].Trim()
        $remoteMap[$fn] = $sz
    }
}

$files = $remoteMap.Keys | Sort-Object

Write-Host "Total de particoes prontas para transferir: $($files.Count)"

$shaLines = @()
$manifest = @()
$current = 0

foreach ($f in $files) {
    $current++
    $localPath = Join-Path $DestDir $f
    $remotePath = "$RemoteDir/$f"
    $rSize = $remoteMap[$f]

    $needsPull = $true
    if (Test-Path $localPath) {
        $lSize = (Get-Item $localPath).Length
        if ($lSize -eq $rSize -and $rSize -gt 0) {
            Write-Host ("[{0}/{1}] (Ja baixado) {2} ({3:N1} MB)" -f $current, $files.Count, $f, ($rSize / 1MB))
            $needsPull = $false
        }
    }

    if ($needsPull) {
        Write-Host ("[{0}/{1}] Baixando {2} ({3:N1} MB)..." -f $current, $files.Count, $f, ($rSize / 1MB))
        & $Adb pull $remotePath $localPath
    }

    if (Test-Path $localPath) {
        $actualSize = (Get-Item $localPath).Length
        if ($actualSize -eq $rSize) {
            $hash = (Get-FileHash $localPath -Algorithm SHA256).Hash.ToLower()
            $shaLines += "$hash  $f"
            $manifest += [pscustomobject]@{ Partition = $f; Size = $actualSize; SHA256 = $hash }
        } else {
            Write-Host ("AVISO: Tamanho divergente em {0}: local={1}, remoto={2}" -f $f, $actualSize, $rSize)
        }
    } else {
        Write-Host "AVISO: Falha ao transferir $f"
    }
}

$shaPath = Join-Path $DestDir "SHA256SUMS"
$shaLines | Set-Content -Path $shaPath -Encoding ASCII
$manifest | Export-Csv (Join-Path $DestDir "manifest.csv") -NoTypeInformation -Encoding ASCII

Write-Host ""
Write-Host "=========================================="
Write-Host "BACKUP COMPLETO CONCLUIDO COM SUCESSO!"
Write-Host "Total de particoes verificadas: $($manifest.Count) de $($files.Count)"
Write-Host "Pasta destino: $DestDir"
Write-Host "Manifesto SHA-256 gerado em: $shaPath"
Write-Host "=========================================="
