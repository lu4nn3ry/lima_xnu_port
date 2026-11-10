<#
.SYNOPSIS
    Baixa UMA entrada de um ZIP remoto usando HTTP Range, sem baixar o arquivo inteiro.

.DESCRIPTION
    Le o End Of Central Directory (EOCD) no fim do arquivo, depois o diretorio
    central, localiza a entrada desejada e baixa apenas os bytes comprimidos
    daquela entrada. Suporta metodo "stored" (0) e "deflate" (8).

    Usa curl.exe para as requisicoes Range (o HttpWebRequest do .NET trava com
    este mirror; curl tambem evita o 403 por falta de User-Agent).

.PARAMETER Url
    URL do arquivo .zip remoto.

.PARAMETER Entry
    Nome exato da entrada dentro do zip (ex.: "boot.img").

.PARAMETER OutFile
    Caminho local de saida.

.PARAMETER List
    Apenas lista o diretorio central e sai (nao baixa entrada).

.EXAMPLE
    powershell -File tools\fetch-zip-entry.ps1 -Url https://.../fw.zip -Entry boot.img -OutFile dumps\boot.img

.EXAMPLE
    powershell -File tools\fetch-zip-entry.ps1 -Url https://.../fw.zip -List
#>
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$Entry,
    [string]$OutFile,
    [switch]$List
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
$Curl = "curl.exe"
$script:tmpdir = Join-Path ([IO.Path]::GetTempPath()) ("fze-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $script:tmpdir | Out-Null

function Invoke-RangeToFile([string]$u, [long]$start, [long]$end, [string]$dest) {
    $range = "$start-$end"
    & $Curl -s --fail --max-time 600 -A $UA -r $range -o $dest $u
    if ($LASTEXITCODE -ne 0) { throw "curl range falhou (exit $LASTEXITCODE) para $range" }
    if (-not (Test-Path $dest)) { throw "curl nao gravou $dest" }
}

function Get-RemoteLength([string]$u) {
    $head = (& $Curl -sI --max-time 60 -A $UA $u) -join "`n"
    if ($head -notmatch '(?im)^Content-Length:\s*(\d+)') { throw "sem Content-Length em $u" }
    return [long]$Matches[1]
}

try {
    $total = Get-RemoteLength $Url
    Write-Host ("tamanho remoto: {0:N0} bytes" -f $total)

    # --- 1. EOCD (ultimos 64 KB + 22) ---
    $tailLen = [Math]::Min(65557, $total)
    $tailFile = Join-Path $script:tmpdir "tail.bin"
    Invoke-RangeToFile $Url ($total - $tailLen) ($total - 1) $tailFile
    $tail = [IO.File]::ReadAllBytes($tailFile)

    $eocd = -1
    for ($i = $tail.Length - 22; $i -ge 0; $i--) {
        if ($tail[$i] -eq 0x50 -and $tail[$i + 1] -eq 0x4b -and $tail[$i + 2] -eq 0x05 -and $tail[$i + 3] -eq 0x06) { $eocd = $i; break }
    }
    if ($eocd -lt 0) { throw "EOCD nao encontrado (zip64 ou arquivo invalido)" }

    $entries  = [BitConverter]::ToUInt16($tail, $eocd + 10)
    $cdSize   = [BitConverter]::ToUInt32($tail, $eocd + 12)
    $cdOffset = [BitConverter]::ToUInt32($tail, $eocd + 16)
    if ($cdSize -eq 0xFFFFFFFF -or $cdOffset -eq 0xFFFFFFFF) { throw "zip64 nao suportado por este script" }
    Write-Host ("entradas={0}  diretorio central: offset={1:N0} size={2:N0}" -f $entries, $cdOffset, $cdSize)

    # --- 2. diretorio central ---
    $cdFile = Join-Path $script:tmpdir "cd.bin"
    Invoke-RangeToFile $Url $cdOffset ($cdOffset + $cdSize - 1) $cdFile
    $cd = [IO.File]::ReadAllBytes($cdFile)

    $p = 0
    $found = $null
    $names = @()
    while ($p + 46 -le $cd.Length) {
        if ([BitConverter]::ToUInt32($cd, $p) -ne 0x02014b50) { break }
        $method   = [BitConverter]::ToUInt16($cd, $p + 10)
        $csize    = [BitConverter]::ToUInt32($cd, $p + 20)
        $usize    = [BitConverter]::ToUInt32($cd, $p + 24)
        $nameLen  = [BitConverter]::ToUInt16($cd, $p + 28)
        $extraLen = [BitConverter]::ToUInt16($cd, $p + 30)
        $commLen  = [BitConverter]::ToUInt16($cd, $p + 32)
        $lho      = [BitConverter]::ToUInt32($cd, $p + 42)
        $name     = [Text.Encoding]::ASCII.GetString($cd, $p + 46, $nameLen)
        $names += [pscustomobject]@{ Name = $name; Method = $method; Compressed = $csize; Size = $usize; LocalOffset = $lho }
        if (-not $found -and $name -ieq $Entry) { $found = $names[-1] }
        $p += 46 + $nameLen + $extraLen + $commLen
    }

    if ($List -or -not $Entry) {
        Write-Host ""
        Write-Host ("{0,-45} {1,6} {2,14} {3,14}" -f "entrada", "met", "comprimido", "original")
        foreach ($n in $names) {
            Write-Host ("{0,-45} {1,6} {2,14:N0} {3,14:N0}" -f $n.Name, $n.Method, $n.Compressed, $n.Size)
        }
        return
    }

    if (-not $found) { throw "entrada '$Entry' nao encontrada no zip" }
    if (-not $OutFile) { throw "-OutFile obrigatorio" }
    Write-Host ("entrada: {0}  metodo={1} comprimido={2:N0} original={3:N0}" -f $found.Name, $found.Method, $found.Compressed, $found.Size)

    # --- 3. cabecalho local -> inicio dos dados ---
    $lhFile = Join-Path $script:tmpdir "lh.bin"
    Invoke-RangeToFile $Url $found.LocalOffset ($found.LocalOffset + 29) $lhFile
    $lh = [IO.File]::ReadAllBytes($lhFile)
    if ([BitConverter]::ToUInt32($lh, 0) -ne 0x04034b50) { throw "cabecalho local invalido" }
    $lhName  = [BitConverter]::ToUInt16($lh, 26)
    $lhExtra = [BitConverter]::ToUInt16($lh, 28)
    $dataStart = $found.LocalOffset + 30 + $lhName + $lhExtra

    # --- 4. dados da entrada ---
    $dataFile = Join-Path $script:tmpdir "data.bin"
    Invoke-RangeToFile $Url $dataStart ($dataStart + $found.Compressed - 1) $dataFile
    Write-Host ("baixados {0:N0} bytes comprimidos" -f (Get-Item $dataFile).Length)

    New-Item -ItemType Directory -Force -Path (Split-Path $OutFile) | Out-Null

    if ($found.Method -eq 0) {
        Copy-Item $dataFile $OutFile -Force
    }
    elseif ($found.Method -eq 8) {
        $in = [IO.File]::OpenRead($dataFile)
        $ds = New-Object System.IO.Compression.DeflateStream($in, [System.IO.Compression.CompressionMode]::Decompress)
        $out = [IO.File]::Create($OutFile)
        $ds.CopyTo($out)
        $out.Close(); $ds.Close(); $in.Close()
    }
    else {
        throw "metodo de compressao nao suportado: $($found.Method)"
    }

    $result = Get-Item $OutFile
    $h = (Get-FileHash $OutFile -Algorithm SHA256).Hash.ToLower()
    Write-Host ("gravado: {0} ({1:N0} bytes)" -f $result.FullName, $result.Length)
    Write-Host ("sha256:  {0}" -f $h)
    if ($result.Length -ne $found.Size) { Write-Warning "tamanho diferente do esperado ($($found.Size))" }
}
finally {
    Remove-Item $script:tmpdir -Recurse -Force -ErrorAction SilentlyContinue
}
