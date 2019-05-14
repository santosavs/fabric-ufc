#!/bin/sh
# Geração dos cards para o composer
# cryptconfig/peerOrganizations/ppgeti.ufc.br/users/Admin@ppgeti.ufc.br/msp
# signcerts - certificado Admin da organização
# keystore - chave privada
PPGETI_ADMINCERT_PATH=crypto-config/peerOrganizations/ppgeti.ufc.br/users/Admin@ppgeti.ufc.br/msp/signcerts/Admin@ppgeti.ufc.br-cert.pem
PPGETI_PK_PATH=crypto-config/peerOrganizations/ppgeti.ufc.br/users/Admin@ppgeti.ufc.br/msp/keystore
PPGETI_PK=$(ls crypto-config/peerOrganizations/ppgeti.ufc.br/users/Admin@ppgeti.ufc.br/msp/keystore | grep _sk)

composer card create -p connection-ppgeti.json \
-u PeerAdmin -c ${PPGETI_ADMINCERT_PATH} \
-k ${PPGETI_PK_PATH}/${PPGETI_PK} \
-r PeerAdmin -r ChannelAdmin

# Importação do Admin Card
composer card import -f PeerAdmin@ufc-network.card

# Instalando o runtime no peer
composer runtime install -c PeerAdmin@ufc-network.card -n ufc-network

# Requisitando credenciais para o usuário da business network
composer identity request -c PeerAdmin@ufc-network -u admin -s adminpw -d ppgetiuser

# Iniciando a business network
composer network start -c PeerAdmin@ufc-network \
-a ufc-network@0.0.1.bna \
-o endorsementPolicyFile=endorsement-policy.json \
-A ppgetiuser -C ppgetiuser/admin-pub.pem

# Gerando um card para acessar a rede como PPGETI
composer card create -p connection-ppgeti.json \
-u ppgetiuser \
-n ufc-network \
-c ppgetiuser/admin-pub.pem \
-k ppgetiuser/admin-priv.pem

# Importando o card criado anteriormente
composer card import -f ppgetiuser@ufc-network.card

# Testando a conectividade com a rede
composer network ping -c ppgetiuser@ufc-network