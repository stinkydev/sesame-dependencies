param(
    [string] $Name = 'stb',
    # stb has no releases; the version is that of stb_image.h, the header NVD tracks.
    [string] $Version = '2.26',
    [string] $Cpe = 'nothings:stb_image.h',
    [string] $Uri = 'https://github.com/nothings/stb.git',
    [string] $Hash = 'e140649ccf40818781b7e408f6228a486f6d254b',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/include/stb" -ItemType Directory -Force *> $null

    @('stb_image.h', 'stb_image_write.h') | ForEach-Object {
        Log-Output "$_ => $($ConfigData.OutputPath)/include/stb"
        Copy-Item -Path $_ -Destination "$($ConfigData.OutputPath)/include/stb"
    }
}
