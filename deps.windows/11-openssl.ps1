param(
    [string] $Name = 'vulkansdk',
    [string] $Version = '1.3.275.0',
    [string] $Uri = 'local://openssl-1.1.1w.zip',
    [string] $Hash = ""
)

function Setup {
    Setup-Dependency -Uri $Uri -Hash $Hash -DestinationPath $Path
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Params = @{
        ErrorAction = "SilentlyContinue"
        Path = @(
            "$($ConfigData.OutputPath)/lib"
            "$($ConfigData.OutputPath)/bin"
            "$($ConfigData.OutputPath)/include"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "openssl-1.1/x64/include"
            Destination = "$($ConfigData.OutputPath)"
            Recurse = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
          Path = "openssl-1.1/x64/lib"
          Destination = "$($ConfigData.OutputPath)"
          Recurse = $true
          ErrorAction = 'SilentlyContinue'
        }
        @{
          Path = "openssl-1.1/x64/bin"
          Destination = "$($ConfigData.OutputPath)"
          Recurse = $true
          ErrorAction = 'SilentlyContinue'
        }
    )

    $Items | ForEach-Object {
        $Item = $_
        Log-Output ('{0} => {1}' -f ($Item.Path -join ", "), $Item.Destination)
        Copy-Item @Item
    }
}
