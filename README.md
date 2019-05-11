# Rede Blockchain Básica - Hyperledger Fabric

Rede fabric básica, elaborada para fins de estudo e composta por um ordenador, uma única organização com um peer, uma CA e um cliente para tarefas auxiliares.

## Requisitos

- Git
- Docker
- Hyperledger Fabric na versão `1.2.1`
- CouchDB na versão `0.4.10`
- Binários `configtxgen` e `cryptogen` na versão `1.2.1` ([download](https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/))

> Todos os testes foram realizados em ambientes Linux (Ubuntu-16.04) e MacOS (OSX 10.14.4 - Mojave) com Docker 18.09.1 e 18.09.2 respectivamente.

## Geração da Rede Fabric

Sequência de passos para a geração da rede Fabric.

### Clonando o repositório

```shell
git clone https://github.com/santosavs/fabric-ufc
```

### Gerando artefatos da rede

Para a geração dos artefatos, basta executar o script `generate_network_artifacts.sh`.

```shell
chmod +x generate_network_artifacts.sh

./generate_network_artifacts.sh
```

> O script já se encarrega de fazer o download dos binários do Fabric, de acordo com a arquitetura utilizada.

No final da execução, serão gerados os diretórios:

- `bin`: binários do Fabric
- `config`: arquivos transacionais de configuração do ordenador, canais e organizações
- `cryptoconfig`: certificados das entidades

### Iniciando a rede

O script de criação de artefatos contempla, também, a geração do `docker-compose.yml`para inicialização da rede. Basta executar o seguinte comando:

```shell
docker-compose up
```

Caso deseje executar em modo daemon:

```shell
docker-compose up -d
```

Para destruir a rede:

```shell
# -v - apaga todos os volumes ao destruir os contêineres
docker-compose down -v
```

> É importante saber que o script não trata das imagens geradas para os chaincodes nas instalações e atualizações de versão dos mesmos. Ainda não há um mecanismo automático implementado para tal.

## Teste da Rede

Sequência de passos para validar a funcionalidade da rede com o chaincode de teste.

### Acessando o contêiner do CLI

Todos os passos devem ser executado do contêiner `cli.ppgeti`

```shell
docker exec -it cli.ppgeti bash
```

### Criação do canal

```shell
peer channel create -o orderer.ufc.br:7050 --tls --cafile $ORDERER_TLS_CAFILE -c researchchannel -f /etc/hyperledger/configtx/researchchannel.tx
```

### Inserindo o peer no canal

```shell
peer channel join -b researchchannel.block
```

### Instalando o chaincode de teste no peer

```shell
peer chaincode install -o orderer.ufc.br:7050 -n mycc -v 1.0 -l node -p /opt/gopath/src/github.com/chaincode/chaincode_example02/node/
```

### Instanciando o chaincode instalado

```shell
peer chaincode instantiate -o orderer.ufc.br:7050 --tls --cafile $ORDERER_TLS_CAFILE -C researchchannel -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}'
```

> Esse passo leva mais tempo que os demais, devido à compilação do código do chaincode e criação de uma imagem e um contêiner para execução do mesmo.

### Consultando um registro pelo chaincode

```shell
peer chaincode query -C researchchannel -n mycc -c '{"Args":["query","a"]}'
```

Resultado esperado: `100`

### Alterando um registro no chaincode

```shell
peer chaincode invoke -o orderer.ufc.br:7050 --tls --cafile $ORDERER_TLS_CAFILE -C researchchannel -n mycc -c '{"Args":["invoke","a","b","50"]}'
```

Resultado esperado:

```shell
[chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Chaincode invoke successful. result: status:200
```

### Nova consulta ao ledger

```shell
peer chaincode query -C researchchannel -n mycc -c '{"Args":["query","a"]}'
```

Resultado esperado: `50`
