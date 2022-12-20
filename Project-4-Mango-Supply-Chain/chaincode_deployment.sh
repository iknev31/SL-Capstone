#!/bin/bash
# Author: Venkatesan Mohanram
## Create chaincode
echo "---------------------------------------------------------------"
echo "Setting up environment variables"
echo "---------------------------------------------------------------"
export FABRIC_HOME=$HOME/fabric-samples/chaincode
export CHAINCODE_NAME=MangoSupplyChain
export CHAINCODE_FOLDER=$HOME/Eclipse
export CHANNEL_NAME=mscchannel
if [[ -d "$FABRIC_HOME" ]] && [[ -d "$CHAINCODE_FOLDER" ]]; then
  ### Take action if $FABRIC_HOME and $CHAINCODE_FOLDER doesn't exists ###
  echo "Checking required files and folders in $FABRIC_HOME and $CHAINCODE_FOLDER..."
else
  echo "Error: $FABRIC_HOME or $CHAINCODE_FOLDER not found. Can not continue."
  exit 1
fi
echo "---------------------------------------------------------------"
echo "## Create chaincode"
echo "---------------------------------------------------------------"
echo "- Removing previous chaincode"
echo "---------------------------------------------------------------"
cd "$FABRIC_HOME"
rm -rf $CHAINCODE_NAME
echo "---------------------------------------------------------------"
echo "- Compiling the chaincode"
echo "---------------------------------------------------------------"
cd "$CHAINCODE_FOLDER"/$CHAINCODE_NAME
./gradlew installDist
echo "---------------------------------------------------------------"
echo "- Copy the folders and files from the library lib"
echo "---------------------------------------------------------------"
cd "$FABRIC_HOME"
cp -R "$CHAINCODE_FOLDER"/$CHAINCODE_NAME .
cd $CHAINCODE_NAME
cp -R lib/* .
ls build/install/
mv build/install/lib build/install/$CHAINCODE_NAME
echo "---------------------------------------------------------------"
echo "- Rename lib.tar.gz file"
mv build/install/$CHAINCODE_NAME/lib-1.0.jar build/install/$CHAINCODE_NAME/$CHAINCODE_NAME-1.0.jar
ls build/install/$CHAINCODE_NAME/
echo "=================================================================================================="

## Package chaincode
echo "## Package chaincode"
echo "---------------------------------------------------------------"
echo "- Navigate to the test-network folder"
cd $HOME/fabric-samples/test-network
echo "---------------------------------------------------------------"
echo "- Stop the previously running test network"
echo "---------------------------------------------------------------"
sudo ./network.sh down
echo "---------------------------------------------------------------"
echo "- Remove the unused docker images"
echo "---------------------------------------------------------------"
sudo docker system prune -f
echo "---------------------------------------------------------------"
echo "- Start the test network"
echo "---------------------------------------------------------------"
sudo ./network.sh up -ca -s couchdb
echo "---------------------------------------------------------------"
echo "- Create a communication channel for the peers in the test network"
echo "---------------------------------------------------------------"
sudo ./network.sh createChannel -c $CHANNEL_NAME
sudo chmod 666 /var/run/docker.sock
echo "---------------------------------------------------------------"
echo "- Check the list of the channels for the test network"
echo "---------------------------------------------------------------"
docker exec peer0.org1.example.com peer channel list
echo "---------------------------------------------------------------"
echo "- Set up all required environment variables for Org1"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
ls
echo "---------------------------------------------------------------"
echo "- Packaging chaincode"
echo "---------------------------------------------------------------"
peer lifecycle chaincode package $CHAINCODE_NAME.tar.gz --path ../chaincode/$CHAINCODE_NAME/build/install/$CHAINCODE_NAME --lang java --label $CHAINCODE_NAME-1
ls
echo "=================================================================================================="

## Install chaincode
echo "## Install chaincode"
echo "---------------------------------------------------------------"
#1. Installing chaincode on Org1
echo "#1. Installing chaincode on Org1"
echo "---------------------------------------------------------------"
sudo chmod -R 777 .
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode install $CHAINCODE_NAME.tar.gz --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE 
echo "---------------------------------------------------------------"
#2. Installing chaincode on Org2
echo "#2. Installing chaincode on Org2"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org2.sh
peer lifecycle chaincode install $CHAINCODE_NAME.tar.gz --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE 
echo "---------------------------------------------------------------"
#3. Querying the installed chaincode on Org1 and Org2
echo "#3. Querying the installed chaincode on Org1 and Org2"
echo "---------------------------------------------------------------"
#Org1
echo "#Org1"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode queryinstalled --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
export org1_pkgid=$(echo `peer lifecycle chaincode queryinstalled --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE| tail -1 | awk -F' ' '{print $3}' | sed -e s/,//`)
echo $org1_pkgid
echo "---------------------------------------------------------------"
#Org2
echo "#Org2"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org2.sh
peer lifecycle chaincode queryinstalled --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
export org2_pkgid=$(echo `peer lifecycle chaincode queryinstalled --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE| tail -1 | awk -F' ' '{print $3}' | sed -e s/,//`)
echo $org2_pkgid
echo "---------------------------------------------------------------"
#4. Downloading the installed chaincode from the Org1
echo "#4. Downloading the installed chaincode from the Org1"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode getinstalledpackage --package-id "$org1_pkgid" --output-directory . --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
echo "=================================================================================================="

## Approve chaincode
echo "## Approve chaincode"
echo "---------------------------------------------------------------"
#1. Approving chaincode for Org1
echo "#1. Approving chaincode for Org1"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode queryinstalled --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME --name $CHAINCODE_NAME --version 1.0 --init-required --package-id $org1_pkgid --sequence 1
echo "---------------------------------------------------------------"
#2. Approving chaincode for Org2
echo "#2. Approving chaincode for Org2"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org2.sh
peer lifecycle chaincode queryinstalled --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME --name $CHAINCODE_NAME --version 1.0 --init-required --package-id $org2_pkgid --sequence 1
echo "=================================================================================================="

## Commit chaincode
echo "## Commit chaincode"
echo "---------------------------------------------------------------"
#1. Checking commit readiness for Org1 and Org2
echo "#1. Checking commit readiness for Org1 and Org2"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode checkcommitreadiness -C $CHANNEL_NAME --name $CHAINCODE_NAME --version 1.0 --sequence 1 --output json --init-required
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org2.sh
peer lifecycle chaincode checkcommitreadiness -C $CHANNEL_NAME --name $CHAINCODE_NAME --version 1.0 --sequence 1 --output json --init-required
echo "---------------------------------------------------------------"
#2. Committing the chaincode definition to the channel
echo "#2. Committing the chaincode definition to the channel"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_Channel_commit.sh
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME --name $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 --version 1.0 --sequence 1 --init-required
echo "---------------------------------------------------------------"
#3. Querying the committed chaincode from the channel
echo "#3. Querying the committed chaincode from the channel"
echo "---------------------------------------------------------------"
source ./lifecycle_setup_org1.sh
peer lifecycle chaincode querycommitted -C $CHANNEL_NAME --name $CHAINCODE_NAME
echo "=================================================================================================="

## Access chaincode
echo "## Access chaincode"
echo "---------------------------------------------------------------"
#source ./lifecycle_setup_Channel_commit.sh
## Chaincode executions
echo "## Chaincode executions"
echo "## Initializing the ledger"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 --isInit -c '{"Args":[]}'
echo "---------------------------------------------------------------"
echo "Sleeping for 10 seconds to initialize ledger"
echo "---------------------------------------------------------------"
sleep 10
## Add a new asset
echo "## Add a new asset"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["addNewAsset", "pr1", "Mango Product 1","Producer1", "Chennai","10/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 5
## Add a new asset with an existing product id
echo "## Add a new asset with an existing product id"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["addNewAsset", "pr1", "Mango Product 2","Producer2", "Chennai","10/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Add a new asset with an invalid date format
echo "## Add a new asset with an invalid date format"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["addNewAsset", "pr2", "Mango Product 2","Producer2", "Chennai","10-01-2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Distributor to Retailer when distributor date is not available
echo "## Transfer Asset from Distributor to Retailer with valid product ID"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetDistToRetailer", "pr1", "Retailer1","Royapettah","06/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Producer to Distributor with valid product ID
echo "## Transfer Asset from Producer to Distributor with valid product ID"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetProdToDist", "pr1", "Distributor1", "Adyar", "15/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Producer to Distributor with invalid product ID
echo "## Transfer Asset from Producer to Distributor with invalid product ID"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetProdToDist", "pr2", "Distributor2", "Adyar", "05/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Producer to Distributor with date older than harvest date
echo "## Transfer Asset from Producer to Distributor with date older than harvest date"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetProdToDist", "pr1", "Distributor1", "Adyar", "05/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Distributor to Retailer with valid product ID
echo "## Transfer Asset from Distributor to Retailer with valid product ID"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetDistToRetailer", "pr1", "Retailer1","Royapettah","16/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Distributor to Retailer with invalid product ID
echo "## Transfer Asset from Distributor to Retailer with invalid product ID"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetDistToRetailer", "pr2", "Retailer2","Royapettah","06/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## Transfer Asset from Distributor to Retailer with date older than producer date
echo "## Transfer Asset from Distributor to Retailer with date older than producer date"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["transferAssetDistToRetailer", "pr1", "Retailer1","Royapettah","02/01/2022"]}'
echo "---------------------------------------------------------------"
sleep 2
## View Asset details with valid product id
echo "## View Asset details with valid product id"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["viewAssetDetails", "pr1"]}'
echo "---------------------------------------------------------------"
sleep 2
## View Asset details with invalid product id
echo "## View Asset details with invalid product id"
echo "---------------------------------------------------------------"
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses localhost:7051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG1 --peerAddresses localhost:9051 --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE_ORG2 -c '{"Args":["viewAssetDetails", "pr2"]}'
echo "---------------------------------------------------------------"
echo "End of chaincode program executions"
echo "=================================================================================================="
