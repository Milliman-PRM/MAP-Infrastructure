Connect-AzureRmAccount

Get-AzureRmSubscription

Select-AzureRmSubscription -SubscriptionName "PRM-Map Production"

$inf_version = "v1.0"

$GWVNetName  = "gateway-vnet" + $inf_version
$subnet_default = "default"
$GWSubName = "GatewaySubnet"
$VNetPrefixGW = "10.254.0.0/22"
$VNetPrefixGW2 = "176.16.252.0/23"
$gwdefsubnetPrefix = "176.16.253.0/24"
$GWSubPrefix = "10.254.1.0/24"
$VPNClientAddressPool = "192.168.10.0/24"

$RGGW = "map-production-asr-1-1"
$Location = "East US 2"
$GWName = "PRM-MAP-GW" + $inf_version
$GWIPName = "PRM-MAP-GW" + $inf_version
$GWIPconfName = "gwipconf"
$P2SRootCertName = "prm-asr-p2srootcert.cer"
$filePathForCert = "C:\temp\$($P2SRootCertName)"

$clientVnetName = "map-client-vnet-asr-asr"

$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCertMAP" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject "CN=P2SChildCertMAP" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

Export-Certificate -Cert $cert -FilePath $filePathForCert

$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
$p2srootcert = New-AzureRmVpnClientRootCertificate -Name $P2SRootCertName `
    -PublicCertData $CertBase64

