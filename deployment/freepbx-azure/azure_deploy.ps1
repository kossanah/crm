<#
.SYNOPSIS
    Deploys a Debian 12 Virtual Machine on Azure (Standard_B2s) for FreePBX 17
    with optimized NSG rules for VoIP (SIP 5060 and RTP 10000-20000).

.NOTES
    Assigned FQDN: voice.bridge.ng
    Carrier: IPNX Telecoms (sip.ipnxtelecoms.com:5060, DID: 02016335890)
#>

$ResourceGroup = "rg-freepbx-voice"
$Location      = "uksouth"      # UK South (London) - Cost-optimized and low latency for Nigeria
$VnetName      = "vnet-freepbx"
$SubnetName    = "snet-freepbx"
$PublicIpName  = "pip-freepbx"
$NsgName       = "nsg-freepbx"
$VmName        = "vm-freepbx-voice"
$VmSize        = "Standard_B2s"
$AdminUsername = "azureuser"

Write-Host "==> 1. Creating Resource Group: $ResourceGroup ($Location)..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location

Write-Host "==> 2. Creating Static Standard Public IP..." -ForegroundColor Cyan
az network public-ip create `
    --resource-group $ResourceGroup `
    --name $PublicIpName `
    --sku Standard `
    --allocation-method Static `
    --dns-name "voice-bridge-pbx"

Write-Host "==> 3. Creating Network Security Group (NSG)..." -ForegroundColor Cyan
az network nsg create `
    --resource-group $ResourceGroup `
    --name $NsgName

Write-Host "==> 4. Adding Inbound VoIP & Web Security Rules to NSG..." -ForegroundColor Cyan
# SSH
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name "Allow-SSH" `
    --priority 100 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22

# HTTP (Let's Encrypt / Web)
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name "Allow-HTTP" `
    --priority 110 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80

# HTTPS (FreePBX GUI)
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name "Allow-HTTPS" `
    --priority 120 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 443

# SIP Signaling (PJSIP)
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name "Allow-SIP-5060" `
    --priority 130 --direction Inbound --access Allow --protocol "*" --destination-port-ranges 5060

# RTP Audio Stream (10000-20000 UDP)
az network nsg rule create --resource-group $ResourceGroup --nsg-name $NsgName --name "Allow-RTP-Audio" `
    --priority 140 --direction Inbound --access Allow --protocol Udp --destination-port-ranges 10000-20000

Write-Host "==> 5. Creating Virtual Network & Subnet with NSG..." -ForegroundColor Cyan
az network vnet create `
    --resource-group $ResourceGroup `
    --name $VnetName `
    --address-prefix 10.10.0.0/16 `
    --subnet-name $SubnetName `
    --subnet-prefix 10.10.1.0/24 `
    --network-security-group $NsgName

Write-Host "==> 6. Deploying Debian 12 VM ($VmSize)..." -ForegroundColor Cyan
$CloudInitPath = Join-Path $PSScriptRoot "cloud_init.yaml"

az vm create `
    --resource-group $ResourceGroup `
    --name $VmName `
    --image "Debian:debian-12:12-gen2:latest" `
    --size $VmSize `
    --admin-username $AdminUsername `
    --generate-ssh-keys `
    --public-ip-address $PublicIpName `
    --vnet-name $VnetName `
    --subnet $SubnetName `
    --custom-data $CloudInitPath

Write-Host "==> 7. Fetching Public IP Address..." -ForegroundColor Green
$PublicIp = az network public-ip show --resource-group $ResourceGroup --name $PublicIpName --query "ipAddress" -o tsv
Write-Host "--------------------------------------------------------" -ForegroundColor Yellow
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "FreePBX VM Public IP: $PublicIp" -ForegroundColor Cyan
Write-Host "Action Required: Update your DNS for voice.bridge.ng -> $PublicIp" -ForegroundColor Yellow
Write-Host "Connect with: ssh $AdminUsername@$PublicIp" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Yellow
