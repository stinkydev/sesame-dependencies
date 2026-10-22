param(
    [string] $Name = 'vectorclass',
    [string] $Version = '2.02.01',
    [string] $Uri = 'https://github.com/vectorclass/version2.git',
    [string] $Hash = 'fe6c4506c6e8301d2edd884284d69663ec2b68a1',
    [array] $Targets = @('x64')
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    New-Item -Path "$($ConfigData.OutputPath)/include/vectorclass" -ItemType Directory -Force *> $null

    # instrset_detect.cpp is compiled into the consumer alongside the headers.
    Log-Output "*.h, instrset_detect.cpp => $($ConfigData.OutputPath)/include/vectorclass"
    Copy-Item -Path '*.h', 'instrset_detect.cpp' -Destination "$($ConfigData.OutputPath)/include/vectorclass"
}
