param(
    [string] $Name = 'tweeny',
    [string] $Version = '3.2.0',
    [string] $Uri = 'https://github.com/mobius3/tweeny/releases/download/v3.2.0/tweeny-3.2.0.h',
    [string] $Hash = "${PSScriptRoot}/checksums/tweeny-3.2.0.h.sha256",
    [array] $Targets = @('x64')
)

function Setup {
    Invoke-SafeWebRequest -Uri $Uri -HashFile $Hash -Resume
}

function Install {
    Log-Information "Install (${Target})"

    New-Item -Path "$($ConfigData.OutputPath)/include/tweeny" -ItemType Directory -Force *> $null

    Log-Output "tweeny-3.2.0.h => $($ConfigData.OutputPath)/include/tweeny/tweeny.h"
    Copy-Item -Path 'tweeny-3.2.0.h' -Destination "$($ConfigData.OutputPath)/include/tweeny/tweeny.h"
}
