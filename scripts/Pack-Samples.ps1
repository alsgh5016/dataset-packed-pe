<#
.SYNOPSIS
    Pack PE samples from not-packed/ with a specified packer, embedding packer
    name, version, and options in the output filename.

.DESCRIPTION
    For each PE file in -InputDir matching -Filter, invokes the packer recipe
    in recipes/<Packer>.ps1 and writes the result to <OutputDir>\<Packer>\
    with the naming convention:

        <packer>-<version>__<options>__<original>.ext

    Failures are appended to <OutputDir>\<Packer>\_failures.log and the run
    continues. Existing outputs are skipped unless -Force is given.

.PARAMETER Packer
    Recipe name (case-insensitive). Must match a file in scripts/recipes/.
    Also used as the output sub-directory name.

.PARAMETER PackerExe
    Absolute path to the packer's CLI executable.

.PARAMETER PackerVersion
    Version string embedded in output filenames (e.g. 4.2.4).

.PARAMETER PackerOptions
    Options string passed to the packer, excluding input/output paths.
    Tokens are split on whitespace; quoted spaces are not supported.

.PARAMETER InputDir
    Source directory of PE samples. Default: <script>\..\not-packed.

.PARAMETER OutputDir
    Root output directory. Default: <script>\..\my-packed.

.PARAMETER Filter
    Filename filter applied to InputDir. Default: *.exe.

.PARAMETER Force
    Overwrite existing outputs.

.EXAMPLE
    .\Pack-Samples.ps1 -Packer UPX `
        -PackerExe "C:\tools\upx-4.2.4\upx.exe" `
        -PackerVersion "4.2.4" `
        -PackerOptions "-9 --lzma"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Packer,
    [Parameter(Mandatory)][string]$PackerExe,
    [Parameter(Mandatory)][string]$PackerVersion,
    [string]$PackerOptions = '',
    [string]$InputDir,
    [string]$OutputDir,
    [string]$Filter = '*.exe',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if (-not $InputDir)  { $InputDir  = Join-Path $PSScriptRoot '..\not-packed' }
if (-not $OutputDir) { $OutputDir = Join-Path $PSScriptRoot '..\my-packed' }

if (-not (Test-Path $PackerExe -PathType Leaf)) {
    throw "PackerExe not found: $PackerExe"
}
if (-not (Test-Path $InputDir -PathType Container)) {
    throw "InputDir not found: $InputDir"
}

$recipesDir = Join-Path $PSScriptRoot 'recipes'
$recipeFile = Get-ChildItem $recipesDir -Filter '*.ps1' |
    Where-Object { $_.BaseName -ieq $Packer } |
    Select-Object -First 1

if (-not $recipeFile) {
    $available = (Get-ChildItem $recipesDir -Filter '*.ps1' | ForEach-Object BaseName) -join ', '
    throw "No recipe for packer '$Packer'. Available: $available"
}

. $recipeFile.FullName
if (-not (Get-Command Invoke-Pack -ErrorAction SilentlyContinue)) {
    throw "Recipe $($recipeFile.Name) did not define Invoke-Pack"
}

$packerLower = $Packer.ToLowerInvariant()

function Format-OptionSlug {
    param([string]$Options)
    if (-not $Options) { return '' }
    $tokens = $Options -split '\s+' | Where-Object { $_ } | ForEach-Object {
        ($_ -replace '^-+', '')
    } | Where-Object { $_ }
    $slug = ($tokens -join '-')
    return ($slug -replace '[<>:"/\\|?*]', '')
}

$optSlug = Format-OptionSlug -Options $PackerOptions

function Build-OutputName {
    param([string]$OriginalName)
    $base = [IO.Path]::GetFileNameWithoutExtension($OriginalName)
    $ext  = [IO.Path]::GetExtension($OriginalName)
    if ($optSlug) {
        return "${packerLower}-${PackerVersion}__${optSlug}__${base}${ext}"
    }
    return "${packerLower}-${PackerVersion}__${base}${ext}"
}

$packerOutDir = Join-Path $OutputDir $Packer
New-Item -ItemType Directory -Path $packerOutDir -Force | Out-Null

$failureLog = Join-Path $packerOutDir '_failures.log'
if (Test-Path $failureLog) { Remove-Item $failureLog -Force }

$samples = Get-ChildItem $InputDir -Filter $Filter -File
$total   = $samples.Count
$ok      = 0
$skipped = 0
$failed  = 0

Write-Host "Packer:  $Packer ($PackerVersion)" -ForegroundColor Cyan
Write-Host "Exe:     $PackerExe" -ForegroundColor Cyan
Write-Host "Options: $PackerOptions" -ForegroundColor Cyan
Write-Host "Input:   $InputDir ($total files)" -ForegroundColor Cyan
Write-Host "Output:  $packerOutDir" -ForegroundColor Cyan
Write-Host ''

foreach ($sample in $samples) {
    $outName = Build-OutputName -OriginalName $sample.Name
    $outPath = Join-Path $packerOutDir $outName

    if ((Test-Path $outPath) -and -not $Force) {
        Write-Host "[SKIP] $($sample.Name)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    try {
        $result = Invoke-Pack `
            -PackerExe $PackerExe `
            -InputPath $sample.FullName `
            -OutputPath $outPath `
            -Options $PackerOptions
    } catch {
        $result = @{ ExitCode = -1; Output = $_.Exception.Message }
    }

    if ($result.ExitCode -eq 0 -and (Test-Path $outPath)) {
        Write-Host "[ OK ] $($sample.Name) -> $outName" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "[FAIL] $($sample.Name) (exit $($result.ExitCode))" -ForegroundColor Red
        $failed++
        $stamp = (Get-Date).ToString('s')
        $shortOut = ($result.Output -replace '\s+', ' ').Trim()
        if ($shortOut.Length -gt 300) { $shortOut = $shortOut.Substring(0, 300) + '...' }
        Add-Content -Path $failureLog -Value "$stamp`t$($sample.Name)`texit=$($result.ExitCode)`t$shortOut"
        if (Test-Path $outPath) { Remove-Item $outPath -Force }
    }
}

Write-Host ''
Write-Host "Done. ok=$ok fail=$failed skip=$skipped total=$total" -ForegroundColor Cyan
if ($failed -gt 0) {
    Write-Host "Failures logged to: $failureLog" -ForegroundColor Yellow
}
