#!/bin/sh
export PATH=${PWD}/bin:$PATH
export FABRIC_CONFIG_PATH=${PWD}
ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")
FABRIC_VERSION=1.2.1
FABRIC_BINARY_PATH=${FABRIC_CONFNIG_PATH}/bin
FABRIC_BINARY_REPO="https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric"
FABRIC_BINARY_FILE=hyperledger-fabric-${ARCH}-${FABRIC_VERSION}.tar.gz
FABRIC_BINARY_PKG=hyperledger-fabric.tar.gz
NETWORK_CHANNEL=researchchannel
SYSTEM_CHANNEL=systemchannel

# Criação de estrutura de diretório para os artefatos e remoção de artefatos antigos
mkdir -p bin config crypto-config
rm -rf bin/* config/* crypto-config/*

# Download dos binários do fabric
curl -o /tmp/${FABRIC_BINARY_PKG} ${FABRIC_BINARY_REPO}/${ARCH}-${FABRIC_VERSION}/${FABRIC_BINARY_FILE}
tar -xzvf /tmp/${FABRIC_BINARY_PKG} -C ${PWD} bin

# Geração do material criptográfico
cryptogen generate --config=./crypto-config.yaml

if [ "$?" -ne 0 ]; then
  echo "Falha na geração dos certificados..."
  exit 1
fi

# Geração do arquivo docker-compose.yml - definição dos contêineres da rede
CA_TLS_KEYFILE=$(ls crypto-config/peerOrganizations/ppgeti.ufc.br/ca | grep _sk)
sed s/CA_TLS_KEY/${CA_TLS_KEYFILE}/g template/docker-compose.template.yml > docker-compose.yml

# Geração do genesis block
configtxgen -channelID ${SYSTEM_CHANNEL} -profile UfcOrdererGenesis -outputBlock ./config/genesis.block

if [ "$?" -ne 0 ]; then
  echo "Falha na geração do genesis block..."
  exit 1
fi

# Geração do arquivo de transação do canal
configtxgen -profile UfcChannel -outputCreateChannelTx ./config/researchchannel.tx -channelID ${NETWORK_CHANNEL}

if [ "$?" -ne 0 ]; then
  echo "Falha na geração do arquivo de transação do canal..."
  exit 1
fi

# Geração do(s) arquivo(s) de transação para o(s) anchor peer(s)
configtxgen -profile UfcChannel -outputAnchorPeersUpdate ./config/PpgetiMSPanchors.tx -channelID ${NETWORK_CHANNEL} -asOrg PpgetiMSP

if [ "$?" -ne 0 ]; then
  echo "Falha na geração do(s) arquivo(s) de transação para o(s) anchor peer(s)..."
  exit 1
fi
