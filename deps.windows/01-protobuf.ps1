param(
    [string] $Name = 'protobuf',
    [string] $Version = '3.21.12',
    [string] $Uri = 'https://github.com/protocolbuffers/protobuf.git',
    [string] $Hash = "f0dc78d7e6e331b8c6bb2d5283e06aa26883ca7c",
    [array] $Targets = @('x64'),
    [switch] $ForceShared = $false,
    [array] $Patches = @(
    ),
    # protoc-gen-doc settings
    [string] $ProtocGenDocVersion = '1.5.1',
    [string] $ProtocGenDocUri = 'https://github.com/pseudomuto/protoc-gen-doc/releases/download/v1.5.1/protoc-gen-doc_1.5.1_windows_amd64.tar.gz',
    [string] $ProtocGenDocHash = "$PSScriptRoot/checksums/protoc-gen-doc_1.5.1_windows_amd64.tar.gz.sha256"
)

function Setup {
  Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
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
        "-Dprotobuf_BUILD_SHARED_LIBS:BOOL=$($OnOff[$Shared])"
        "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
        "-Dprotobuf_MSVC_STATIC_RUNTIME:BOOL=$($OnOff[$Shared])"
        "-Dprotobuf_BUILD_PROTOC_BINARIES:BOOL=ON"
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

    # Install protoc-gen-doc
    Install-ProtocGenDoc
}

function Install-ProtocGenDoc {
    Log-Information "Install protoc-gen-doc"
    
    $DownloadDir = Join-Path $Path "protoc-gen-doc-download"
    if ( -not ( Test-Path $DownloadDir ) ) {
        New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    }
    
    Set-Location $DownloadDir
    
    $ArchiveFile = "protoc-gen-doc_${ProtocGenDocVersion}_windows_amd64.tar.gz"
    $TarFile = "protoc-gen-doc_${ProtocGenDocVersion}_windows_amd64.tar"
    
    # Download if hash file exists
    if ( Test-Path $ProtocGenDocHash ) {
        $Params = @{
            Uri = $ProtocGenDocUri
            HashFile = $ProtocGenDocHash
            Resume = $true
        }
        
        if ( Test-Path $ArchiveFile ) {
            $Params += @{ CheckExisting = $true }
        }
        
        Invoke-SafeWebRequest @Params
        
        # Extract archive using 7z (handles tar.gz properly in two steps)
        if ( Get-Command 7z -ErrorAction SilentlyContinue ) {
            # First extract .tar.gz to get .tar
            Invoke-External 7z x -y $ArchiveFile
            # Then extract .tar to get contents
            if ( Test-Path $TarFile ) {
                Invoke-External 7z x -y $TarFile
            }
        } else {
            throw "7-zip not found. Please install 7-zip first."
        }
        
        # Copy binary to output bin directory
        $BinDir = "$($ConfigData.OutputPath)/bin"
        if ( -not ( Test-Path $BinDir ) ) {
            New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
        }
        
        Copy-Item -Path "protoc-gen-doc.exe" -Destination $BinDir -Force
        Log-Information "Installed protoc-gen-doc.exe to ${BinDir}"
    } else {
        Log-Warning "Checksum file not found for protoc-gen-doc, skipping installation"
    }
}