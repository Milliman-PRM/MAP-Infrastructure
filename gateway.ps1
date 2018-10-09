$ScriptPath = Split-Path $MyInvocation.InvocationName
& "$ScriptPath\shared.ps1"


New-AzureRmResourceGroup -Name $RGGW -Location $Location

$sub = New-AzureRmVirtualNetworkSubnetConfig -name $subnet_default -AddressPrefix $gwdefsubnetPrefix
$gwsub = New-AzureRmVirtualNetworkSubnetConfig -name $GWSubName -AddressPrefix $GWSubPrefix

$vnet = New-AzureRmVirtualNetwork -Name $GWVNetName -ResourceGroupName $RGGW `
    -Location $Location -AddressPrefix $VNetPrefixGW,$VNetPrefixGW2 -Subnet $sub, $gwsub


$vnetgw = Get-AzureRmVirtualNetwork -Name $GWVNetName -ResourceGroupName $RGGW
$gwsubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnetgw

$pip = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $RGGW `
    -Location $Location -AllocationMethod Dynamic
$ipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName `
    -Subnet $gwsubnet -PublicIpAddress $pip

$gateway = New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RGGW `
-Location $Location -IpConfigurations $ipconf -GatewayType Vpn `
-VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1 -VpnClientProtocol "SSTP","IKEv2"

Set-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $gateway `
    -VpnClientAddressPool $VPNClientAddressPool

Add-AzureRmVpnClientRootCertificate `
    -VpnClientRootCertificateName $P2SRootCertName `
    -VirtualNetworkGatewayName $GWName `
    -ResourceGroupName $RGGW `
    -PublicCertData $CertBase64

$cred = get-credential -Message "Enter credentials for JumpBox VM Login"

New-AzureRmVm -ResourceGroupname $RGGW -name $VGJumpBoxName -Location $Location `
    -SubnetName $subnet_default -SecurityGroupName $gwnsg.Name -Credential $cred

