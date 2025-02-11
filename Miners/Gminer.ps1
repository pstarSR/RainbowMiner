﻿using module ..\Include.psm1

param(
    [PSCustomObject]$Pools,
    [Bool]$InfoOnly
)

if (-not $IsWindows -and -not $IsLinux) {return}

if ($IsLinux) {
    $Path = ".\Bin\NVIDIA-Gminer\miner"
    $Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.45-gminer/gminer_1_45_linux64.tar.xz"
} else {
    $Path = ".\Bin\NVIDIA-Gminer\miner.exe"
    $Uri = "https://github.com/RainbowMiner/miner-binaries/releases/download/v1.45-gminer/gminer_1_45_windows64.zip"
}
$ManualUri = "https://bitcointalk.org/index.php?topic=5034735.0"
$Port = "329{0:d2}"
$DevFee = 2.0
$Cuda = "9.0"

if (-not $Session.DevicesByTypes.AMD -and -not $Session.DevicesByTypes.NVIDIA -and -not $InfoOnly) {return} # No AMD, NVIDIA present in system

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{MainAlgorithm = "Aeternity";    MinMemGb = 4;   MinMemGbW10 = 6;  Params = "--algo aeternity"; Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true; NoCPUMining = $true} #Equihash Cuckoo29/Aeternity
    [PSCustomObject]@{MainAlgorithm = "Cuckaroo29";   MinMemGb = 4;   MinMemGbW10 = 6;  Params = "--algo grin29";    Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true; NoCPUMining = $true} #Equihash Cuckaroo29/GRIN
    [PSCustomObject]@{MainAlgorithm = "Cuckaroo29s";  MinMemGb = 4;   MinMemGbW10 = 6;  Params = "--algo swap";      Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true; NoCPUMining = $true} #Equihash Cuckaroo29s/SWAP
    [PSCustomObject]@{MainAlgorithm = "Cuckatoo31";   MinMemGb = 8;   MinMemGbW10 = 10; Params = "--algo grin31";    Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true; NoCPUMining = $true} #Equihash Cuckatoo31/GRIN31
    [PSCustomObject]@{MainAlgorithm = "Equihash16x5"; MinMemGb = 2;                     Params = "--algo 96_5";      Vendor = @("NVIDIA");       ExtendInterval = 2; NH = $true} #Equihash 96,5
    [PSCustomObject]@{MainAlgorithm = "Equihash24x5"; MinMemGb = 2;                     Params = "--algo 144_5";     Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true} #Equihash 144,5
    [PSCustomObject]@{MainAlgorithm = "Equihash25x5"; MinMemGb = 3;                     Params = "--algo 150_5";     Vendor = @("AMD","NVIDIA"); ExtendInterval = 2; NH = $true} #Equihash 150,5/BEAM
    [PSCustomObject]@{MainAlgorithm = "Equihash24x7"; MinMemGb = 3.0;                   Params = "--algo 192_7";     Vendor = @("NVIDIA");       ExtendInterval = 2; NH = $true} #Equihash 192,7
    [PSCustomObject]@{MainAlgorithm = "Equihash21x9"; MinMemGb = 0.5;                   Params = "--algo 210_9";     Vendor = @("NVIDIA");       ExtendInterval = 2; NH = $true} #Equihash 210,9
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

if ($InfoOnly) {
    [PSCustomObject]@{
        Type      = @("AMD","NVIDIA")
        Name      = $Name
        Path      = $Path
        Port      = $Miner_Port
        Uri       = $Uri
        DevFee    = $DevFee
        ManualUri = $ManualUri
        Commands  = $Commands
    }
    return
}

if ($Session.DevicesByTypes.NVIDIA) {$Cuda = Confirm-Cuda -ActualVersion $Session.Config.CUDAVersion -RequiredVersion $Cuda -Warning $Name}

foreach ($Miner_Vendor in @("AMD","NVIDIA")) {
	$Session.DevicesByTypes.$Miner_Vendor | Where-Object Type -eq "GPU" | Where-Object {$_.Vendor -ne "NVIDIA" -or $Cuda} | Select-Object Vendor, Model -Unique | ForEach-Object {
        $Device = $Session.DevicesByTypes."$($_.Vendor)" | Where-Object Model -EQ $_.Model
        $Miner_Model = $_.Model

        $Commands | Where-Object {$_.Vendor -icontains $Miner_Vendor} | ForEach-Object {
            $MinMemGb = if ($_.MinMemGbW10 -and $Session.WindowsVersion -ge "10.0.0.0") {$_.MinMemGbW10} else {$_.MinMemGb}
            $Miner_Device = $Device | Where-Object {$_.OpenCL.GlobalMemsize -ge ($MinMemGb * 1gb - 0.25gb)}

            $Algorithm_Norm = Get-Algorithm $_.MainAlgorithm

            $Miner_Port = $Port -f ($Miner_Device | Select-Object -First 1 -ExpandProperty Index)
            $Miner_Name = (@($Name) + @($Miner_Device.Name | Sort-Object) | Select-Object) -join '-'
            $Miner_Port = Get-MinerPort -MinerName $Name -DeviceName @($Miner_Device.Name) -Port $Miner_Port

            $DeviceIDsAll = $Miner_Device.Type_Vendor_Index -join ' '
        
		    foreach($Algorithm_Norm in @($Algorithm_Norm,"$($Algorithm_Norm)-$($Miner_Model)")) {
			    if ($Pools.$Algorithm_Norm.Host -and $Miner_Device -and ($_.NH -or $Pools.$Algorithm_Norm.Name -ne "Nicehash")) {
				    $Pool_Port = if ($Pools.$Algorithm_Norm.Ports -ne $null -and $Pools.$Algorithm_Norm.Ports.GPU) {$Pools.$Algorithm_Norm.Ports.GPU} else {$Pools.$Algorithm_Norm.Port}
				    [PSCustomObject]@{
					    Name = $Miner_Name
					    DeviceName = $Miner_Device.Name
					    DeviceModel = $Miner_Model
					    Path = $Path
					    Arguments = "--api $($Miner_Port) --devices $($DeviceIDsAll) --server $($Pools.$Algorithm_Norm.Host) --port $($Pool_Port) --user $($Pools.$Algorithm_Norm.User)$(if ($Pools.$Algorithm_Norm.Pass) {" --pass $($Pools.$Algorithm_Norm.Pass)"})$(if ($Algorithm_Norm -match "^Equihash") {" --pers $(Get-EquihashCoinPers $Pools.$Algorithm_Norm.CoinSymbol -Default "auto")"})$(if ($Pools.$Algorithm_Norm.SSL) {" --ssl 1"}) --cuda $([int]($Miner_Vendor -eq "NVIDIA")) --opencl $([int]($Miner_Vendor -eq "AMD")) --watchdog 0 $($_.Params)"
					    HashRates = [PSCustomObject]@{$Algorithm_Norm = $($Session.Stats."$($Miner_Name)_$($Algorithm_Norm -replace '\-.*$')_HashRate".Week * $(if ($_.Penalty) {1-$_.Penalty/100} else {1}))}
					    API = "Gminer"
					    Port = $Miner_Port
					    DevFee = $DevFee
					    Uri = $Uri
					    FaultTolerance = $_.FaultTolerance
					    ExtendInterval = $_.ExtendInterval
					    ManualUri = $ManualUri
					    NoCPUMining = $_.NoCPUMining
				    }
			    }
		    }
        }
    }
}