$ScriptPath = Split-Path $MyInvocation.InvocationName
. "$ScriptPath\shared.ps1"

$sub = New-AzureRmVirtualNetworkSubnetConfig -name $subnet_default -AddressPrefix $gwdefsubnetPrefix
$gwsub = New-AzureRmVirtualNetworkSubnetConfig -name $GWSubName -AddressPrefix $GWSubPrefix

New-AzureRmVirtualNetwork -Name $GWVNetName -ResourceGroupName $RGGW `
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

$vnetclient = Get-AzureRmVirtualNetwork -Name $clientVnetName -ResourceGroupName $RGGW

Add-AzureRmVirtualNetworkPeering -name 'client-to-vpn' `
    -VirtualNetwork $vnetclient -RemoteVirtualNetworkId $vnetgw.Id

Add-AzureRmVirtualNetworkPeering -name 'vpn-to-client' `
    -VirtualNetwork $vnetgw -RemoteVirtualNetworkId $vnetclient.Id