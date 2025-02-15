param(
    [string] $Name = 'vulkansdk',
    [string] $Version = '1.3.275.0',
    [string] $Uri = 'local://VulkanSDK-1.3.275.0-components.7z',
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
            "$($ConfigData.OutputPath)/include"
        )
        ItemType = "Directory"
        Force = $true
    }

    New-Item @Params *> $null

    $Items = @(
        @{
            Path = "include/vulkan"
            Destination = "$($ConfigData.OutputPath)/include"
            Recurse = $true
            ErrorAction = 'SilentlyContinue'
        }
        @{
          Path = "include/vk_video"
          Destination = "$($ConfigData.OutputPath)/include"
          Recurse = $true
          ErrorAction = 'SilentlyContinue'
        }
        @{
          Path = "include/vma"
          Destination = "$($ConfigData.OutputPath)/include"
          Recurse = $true
          ErrorAction = 'SilentlyContinue'
        }
        @{
            Path = "lib$(if ( $Target -eq "x86" ) { "32" })/vulkan-1.lib"
            Destination = "$($ConfigData.OutputPath)/lib"
            ErrorAction = 'SilentlyContinue'
        }
        @{
          Path = "bin"
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
