#!/usr/bin/env bash
# Deploy Debian 12 Virtual Machine on Azure (Standard_B2s) for FreePBX 17
# Assigned FQDN: voice.bridge.ng
# Carrier: IPNX Telecoms (sip.ipnxtelecoms.com:5060, DID: 02016335890)

set -e

RESOURCE_GROUP="rg-freepbx-voice"
LOCATION="uksouth"      # UK South (London) - Cost-optimized and low latency for Nigeria
VNET_NAME="vnet-freepbx"
SUBNET_NAME="snet-freepbx"
PUBLIC_IP_NAME="pip-freepbx"
NSG_NAME="nsg-freepbx"
VM_NAME="vm-freepbx-voice"
VM_SIZE="Standard_B2s"
ADMIN_USER="azureuser"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 1. Creating Resource Group: ${RESOURCE_GROUP} (${LOCATION})..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

echo "==> 2. Creating Static Standard Public IP..."
az network public-ip create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${PUBLIC_IP_NAME}" \
    --sku Standard \
    --allocation-method Static \
    --dns-name "voice-bridge-pbx"

echo "==> 3. Creating Network Security Group (NSG)..."
az network nsg create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${NSG_NAME}"

echo "==> 4. Adding Inbound VoIP & Web Security Rules to NSG..."
az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "${NSG_NAME}" --name "Allow-SSH" \
    --priority 100 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22

az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "${NSG_NAME}" --name "Allow-HTTP" \
    --priority 110 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80

az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "${NSG_NAME}" --name "Allow-HTTPS" \
    --priority 120 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 443

az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "${NSG_NAME}" --name "Allow-SIP-5060" \
    --priority 130 --direction Inbound --access Allow --protocol "*" --destination-port-ranges 5060

az network nsg rule create --resource-group "${RESOURCE_GROUP}" --nsg-name "${NSG_NAME}" --name "Allow-RTP-Audio" \
    --priority 140 --direction Inbound --access Allow --protocol Udp --destination-port-ranges 10000-20000

echo "==> 5. Creating Virtual Network & Subnet with NSG..."
az network vnet create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VNET_NAME}" \
    --address-prefix 10.10.0.0/16 \
    --subnet-name "${SUBNET_NAME}" \
    --subnet-prefix 10.10.1.0/24 \
    --network-security-group "${NSG_NAME}"

echo "==> 6. Deploying Debian 12 VM (${VM_SIZE})..."
az vm create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${VM_NAME}" \
    --image "Debian:debian-12:12-gen2:latest" \
    --size "${VM_SIZE}" \
    --admin-username "${ADMIN_USER}" \
    --generate-ssh-keys \
    --public-ip-address "${PUBLIC_IP_NAME}" \
    --vnet-name "${VNET_NAME}" \
    --subnet "${SUBNET_NAME}" \
    --custom-data "${SCRIPT_DIR}/cloud_init.yaml"

PUBLIC_IP=$(az network public-ip show --resource-group "${RESOURCE_GROUP}" --name "${PUBLIC_IP_NAME}" --query "ipAddress" -o tsv)

echo "--------------------------------------------------------"
echo "DEPLOYMENT COMPLETE!"
echo "FreePBX VM Public IP: ${PUBLIC_IP}"
echo "Action: Point DNS 'voice.bridge.ng' (A record) -> ${PUBLIC_IP}"
echo "Connect with: ssh ${ADMIN_USER}@${PUBLIC_IP}"
echo "--------------------------------------------------------"
