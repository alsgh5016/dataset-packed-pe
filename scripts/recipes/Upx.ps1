function Invoke-Pack {
    param(
        [Parameter(Mandatory)][string]$PackerExe,
        [Parameter(Mandatory)][string]$InputPath,
        [Parameter(Mandatory)][string]$OutputPath,
        [string]$Options = ''
    )

    $argList = @()
    if ($Options) {
        $argList += ($Options -split '\s+' | Where-Object { $_ })
    }
    $argList += @('-o', $OutputPath, $InputPath)

    $output = & $PackerExe @argList 2>&1 | Out-String
    return @{
        ExitCode = $LASTEXITCODE
        Output   = $output.Trim()
    }
}
