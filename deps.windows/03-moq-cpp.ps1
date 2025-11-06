param(
    [string] $Name = 'moq-cpp',
    [string] $Version = 'v0.0.7',
    [string] $Uri = 'https://github.com/stinkydev/moq-cpp.git',
    [string] $Hash = "f674e3f33d0238f778abb25e3760c7a031dce9a4",
    [array] $Targets = @('x64'),
    [switch] $ForceShared = $false,
    [array] $Patches = @(
    )
)

function Setup {
  Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path -Branch "main"
}

function Clean {
  Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Patch {
    Log-Information "Patch (${Target})"
    Set-Location $Path

    $Patches | ForEach-Object {
        $Params = $_
        Safe-Patch @Params
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }
  
    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    $Options += @($CmakePostfix)

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}