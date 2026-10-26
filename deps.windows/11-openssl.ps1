param(
    [string] $Name = 'openssl',
    [string] $Version = '3.5.9',
    [string] $Cpe = 'openssl:openssl',
    [string] $Uri = 'https://github.com/openssl/openssl/releases/download/openssl-3.5.9/openssl-3.5.9.tar.gz',
    [string] $Hash = "${PSScriptRoot}/checksums/openssl-3.5.9.tar.gz.sha256",
    [array] $Targets = @('x64'),
    # OpenSSL's Configure needs a native Windows perl; the MSYS2 perl produces unusable paths.
    [string] $StrawberryPerl = 'C:\Strawberry\perl\bin\perl.exe'
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath .

    if ( ! ( $SkipAll -or $SkipDeps ) ) {
        Invoke-External pacman.exe -S --noconfirm --needed --noprogressbar mingw-w64-x86_64-nasm

        if ( ! ( Test-Path $StrawberryPerl ) ) {
            Invoke-External winget install --id StrawberryPerl.StrawberryPerl --exact --accept-package-agreements --accept-source-agreements --silent
        }
    }
}

function Clean {
    Set-Location "${Name}-${Version}"

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Invoke-OpenSSLBuild {
    param([string] $BuildCommand)

    $MsysRoot = Split-Path -Parent (Split-Path -Parent (Get-Command pacman.exe).Source)

    $Params = @{
        BasePath = (Get-Location | Convert-Path)
        BuildPath = "build_${Target}"
        BuildCommand = $BuildCommand
        Target = $Target
    }

    $Backup = @{
        PATH = $env:PATH
    }
    # Only nasm is needed from MSYS2; perl is called by full path so the MSYS2 perl is never picked up.
    $NasmPath = "${MsysRoot}\mingw64\bin"
    $env:PATH = "$(Split-Path -Parent $StrawberryPerl);${NasmPath};${env:PATH}"
    Invoke-DevShell @Params
    $Backup.GetEnumerator() | ForEach-Object { Set-Item -Path "env:\$($_.Key)" -Value $_.Value }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location "${Name}-${Version}"

    $ConfigureTargets = @{
        x64 = 'VC-WIN64A'
    }

    New-Item -ItemType Directory -Force "build_${Target}" > $null

    $ConfigureCommand = @(
        "'${StrawberryPerl}'"
        '../Configure'
        $ConfigureTargets[$Target]
        "--prefix=`"$($script:ConfigData.OutputPath)`""
        "--openssldir=`"$($script:ConfigData.OutputPath)\ssl`""
        'no-tests'
        'no-docs'
        $(if ( $Configuration -eq 'Debug' ) { '--debug' } else { '--release' })
    )

    Invoke-OpenSSLBuild -BuildCommand ($ConfigureCommand -join ' ')
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location "${Name}-${Version}"

    Invoke-OpenSSLBuild -BuildCommand 'nmake'
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location "${Name}-${Version}"

    Invoke-OpenSSLBuild -BuildCommand 'nmake install_sw'
}
