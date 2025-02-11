﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

if (-not $IsWindows -and -not $IsLinux) {return}

$ManualUri = "https://bitcointalk.org/index.php?topic=4432704.0"
$Port = "316{0:d2}"
$DevFee = 1.0

if ($IsLinux) {
    $Path = ".\Bin\NVIDIA-Trex\t-rex"
    $UriCuda = @(
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-linux-cuda10.0.tar.gz"
            Cuda = "10.0"
        },
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-linux-cuda9.2.tar.gz"
            Cuda = "9.2"
        },
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-linux-cuda9.1.tar.gz"
            Cuda = "9.1"
        }
    )
} else {
    $Path = ".\Bin\NVIDIA-Trex\t-rex.exe"
    $UriCuda = @(
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-win-cuda10.0.zip"
            Cuda = "10.0"
        },
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-win-cuda9.2.zip"
            Cuda = "9.2"
        },
        [PSCustomObject]@{
            Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v0.11.1-trex/t-rex-0.11.1-win-cuda9.1.zip"
            Cuda = "9.1"
        }
    )
}

if (-not $Session.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No NVIDIA present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "astralhash"; Params = ""} #GLTAstralHash (new with v0.8.6)
    [PSCustomObject]@{MainAlgorithm = "balloon"; Params = ""} #Balloon
    [PSCustomObject]@{MainAlgorithm = "bcd"; Params = ""} #Bcd
    [PSCustomObject]@{MainAlgorithm = "bitcore"; Params = ""} #BitCore
    [PSCustomObject]@{MainAlgorithm = "c11"; Params = ""} #C11
    [PSCustomObject]@{MainAlgorithm = "dedal"; Params = ""; ExtendInterval = 3; FaultTolerance = 0.7; HashrateDuration = "Day"} #Dedal (broken in v0.8.6, fixed in v0.8.8)
    [PSCustomObject]@{MainAlgorithm = "geek"; Params = ""} #Geek (new with v0.7.5)
    [PSCustomObject]@{MainAlgorithm = "hmq1725"; Params = ""} #HMQ1725 (new with v0.6.4)
    [PSCustomObject]@{MainAlgorithm = "hsr"; Params = ""} #HSR
    [PSCustomObject]@{MainAlgorithm = "jeonghash"; Params = ""} #GLTJeongHash  (new with v0.8.6)
    [PSCustomObject]@{MainAlgorithm = "lyra2z"; Params = ""} #Lyra2z
    [PSCustomObject]@{MainAlgorithm = "mtp"; Params = ""; ExtendInterval = 2} #MTP
    [PSCustomObject]@{MainAlgorithm = "phi"; Params = ""} #PHI
    #[PSCustomObject]@{MainAlgorithm = "phi2"; Params = ""} #PHI2
    [PSCustomObject]@{MainAlgorithm = "padihash"; Params = ""} #GLTPadiHash  (new with v0.8.6)
    [PSCustomObject]@{MainAlgorithm = "pawelhash"; Params = ""} #GLTPawelHash  (new with v0.8.6)
    [PSCustomObject]@{MainAlgorithm = "polytimos"; Params = ""} #Polytimos
    [PSCustomObject]@{MainAlgorithm = "renesis"; Params = ""} #Renesis
    [PSCustomObject]@{MainAlgorithm = "sha256q"; Params = ""} #SHA256q (Pyrite)
    [PSCustomObject]@{MainAlgorithm = "sha256t"; Params = ""} #SHA256t
    [PSCustomObject]@{MainAlgorithm = "skunk"; Params = ""} #Skunk
    [PSCustomObject]@{MainAlgorithm = "sonoa"; Params = ""} #Sonoa
    [PSCustomObject]@{MainAlgorithm = "timetravel"; Params = ""} #Timetravel
    [PSCustomObject]@{MainAlgorithm = "tribus"; Params = ""} #Tribus
    [PSCustomObject]@{MainAlgorithm = "veil"; Params = ""; ExtendInterval = 3; FaultTolerance = 0.7; HashrateDuration = "Day"; Algorithm = "x16rt"} #Veil
    [PSCustomObject]@{MainAlgorithm = "x16r"; Params = ""; ExtendInterval = 3; FaultTolerance = 0.7; HashrateDuration = "Day"} #X16r (fastest)
    [PSCustomObject]@{MainAlgorithm = "x16rt"; Params = ""; ExtendInterval = 3; FaultTolerance = 0.7; HashrateDuration = "Day"} #X16rt (Veil)
    [PSCustomObject]@{MainAlgorithm = "x16s"; Params = ""; FaultTolerance = 0.5} #X16s
    [PSCustomObject]@{MainAlgorithm = "x17"; Params = ""} #X17
    [PSCustomObject]@{MainAlgorithm = "x21s"; Params = ""; ExtendInterval = 3; FaultTolerance = 0.7; HashrateDuration = "Day"} #X21s (broken in v0.8.6, fixed in v0.8.8)
    [PSCustomObject]@{MainAlgorithm = "x22i"; Params = ""} #X22i
    [PSCustomObject]@{MainAlgorithm = "x25x"; Params = ""} #X25X
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $UriCuda.Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

$Uri = ""
for($i=0;$i -le $UriCuda.Count -and -not $Uri;$i++) {
    if (Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $UriCuda[$i].Cuda -Warning $(if ($i -lt $UriCuda.Count-1) {""}else{$Name})) {
        $Uri = $UriCuda[$i].Uri
        $Cuda= $UriCuda[$i].Cuda
    }
}
if (-not $Uri) {return}

$Session.DevicesByTypes.NVIDIA | Select-Object Vendor, Model -Unique | ForEach-Object {
    $Miner_Device = $Session.DevicesByTypes."$($_.Vendor)" | Where-Object Model -EQ $_.Model
    $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
    $Miner_Model = $_.Model
    $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
    $Miner_Port = Get-MinerPort -MinerName $Name -DeviceName @($Miner_Device.Name) -Port $Miner_Port

    $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ','

    $Commands | ForEach-Object {
        $Algorithm = if ($_.Algorithm) {$_.Algorithm} else {$_.MainAlgorithm}
        $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm
        
		foreach($Algorithm_Norm in @($Algorithm_Norm,"$($Algorithm_Norm)-$($Miner_Model)")) {
			if ($Pools.$Algorithm_Norm.Host -and $Miner_Device) {
				$Pool_Port = if ($Pools.$Algorithm_Norm.Ports -ne $null -and $Pools.$Algorithm_Norm.Ports.GPU) {$Pools.$Algorithm_Norm.Ports.GPU} else {$Pools.$Algorithm_Norm.Port}
				[PSCustomObject]@{
					Name = $Miner_Name
					DeviceName = $Miner_Device.Name
					DeviceModel = $Miner_Model
					Path = $Path
					Arguments = "-N 10 -r 5 -b 127.0.0.1:$($Miner_Port) -d $($DeviceIDsAll) -a $($Algorithm) -o $($Pools.$Algorithm_Norm.Protocol)://$($Pools.$Algorithm_Norm.Host):$($Pool_Port) -u $($Pools.$Algorithm_Norm.User)$(if ($Pools.$Algorithm_Norm.Pass) {" -p $($Pools.$Algorithm_Norm.Pass)"})$($Pools.$Algorithm_Norm.Failover | Select-Object | Foreach-Object {" -o $($_.Protocol)://$($_.Host):$($_.Port) -u $($_.User)$(if ($_.Pass) {" -p $($_.Pass)"})"})$(if (-not $Session.Config.ShowMinerWindow){" --no-color"}) --no-nvml --no-watchdog --quiet --api-bind-http 0 $($_.Params)"
					HashRates = [PSCustomObject]@{$Algorithm_Norm = $Session.Stats."$($Miner_Name)_$($Algorithm_Norm -replace '\-.*$')_HashRate"."$(if ($_.HashrateDuration){$_.HashrateDuration}else{"Week"})"}
					API = "Ccminer"
					Port = $Miner_Port
					Uri = $Uri
					FaultTolerance = $_.FaultTolerance
					ExtendInterval = $_.ExtendInterval
					DevFee = $DevFee
					ManualUri = $ManualUri
				}
			}
		}
    }
}