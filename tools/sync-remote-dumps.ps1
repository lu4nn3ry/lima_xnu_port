param(
    [string]$SourceHost = "192.168.0.19:8080",
    [string]$DestDir = "dumps"
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================="
Write-Host "SINCRONIZADOR DE DUMPS (AGY-1 -> AGY-2)"
Write-Host "Servidor de Origem: http://$SourceHost"
Write-Host "Destino Local:      $DestDir"
Write-Host "=========================================="
Write-Host ""

$manifestUrl = "http://$SourceHost/manifest.json"
try {
    $resp = Invoke-RestMethod -Uri $manifestUrl -TimeoutSec 10
} catch {
    Write-Error "Nao foi possivel conectar a $manifestUrl. O servidor esta rodando no AGY-1?"
    exit 1
}

$files = $resp.files
Write-Host "Total de arquivos no manifesto remoto: $($files.Count)"
Write-Host ""

$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [System.TimeSpan]::FromMinutes(10)

$count = 0
foreach ($item in $files) {
    $count++
    $relPath = $item.path
    $rSize = [long]$item.size
    $localFile = Join-Path $DestDir ($relPath -replace '/', '\')
    $localParent = Split-Path -Parent $localFile

    if (-not (Test-Path $localParent)) {
        New-Item -ItemType Directory -Force -Path $localParent | Out-Null
    }

    $needsDownload = $true
    if (Test-Path $localFile) {
        $lSize = (Get-Item $localFile).Length
        if ($lSize -eq $rSize -and $rSize -gt 0) {
            Write-Host ("[{0}/{1}] (Ja existe) {2} ({3:N1} MB)" -f $count, $files.Count, $relPath, ($rSize / 1MB))
            $needsDownload = $false
        }
    }

    if ($needsDownload) {
        Write-Host ("[{0}/{1}] Baixando {2} ({3:N1} MB)..." -f $count, $files.Count, $relPath, ($rSize / 1MB))
        $fileUrl = "http://$SourceHost/$relPath"
        
        try {
            $stream = $httpClient.GetStreamAsync($fileUrl).GetAwaiter().GetResult()
            $fileStream = [System.IO.File]::Create($localFile)
            $stream.CopyTo($fileStream)
            $fileStream.Close()
            $stream.Close()
            Write-Host "  -> Concluido!"
        } catch {
            Write-Warning "Falha ao baixar $relPath : $_"
        }
    }
}

$httpClient.Dispose()

Write-Host ""
Write-Host "=========================================="
Write-Host "SINCRONIZACAO CONCLUIDA!"
Write-Host "Arquivos salvos em: $DestDir"
Write-Host "=========================================="
