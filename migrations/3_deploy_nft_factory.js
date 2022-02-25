
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades")
const { getConfigByNetwork, setConfig } = require('./config.js')
const NFTFactory = artifacts.require('NFTFactory')
//const NFTFactoryV2 = artifacts.require('NFTFactoryV2')

module.exports = async function (deployer, network, accounts) {
    let cfg = getConfigByNetwork(network)
    let cloneFactory = cfg.CloneFactory
    let erc721Template = cfg.InitializableERC721
    let erc1155Template = cfg.InitializableERC1155
    let blindBoxTemplate = cfg.BlindBox
    let complateBlindBoxTemplate = cfg.BlindBoxV2
    let signer = '0x0063046686E46Dc6F15918b61AE2B121458534a5'

    console.log("cloneFactory ", cloneFactory)
    console.log("erc721Template ", erc721Template)
    console.log("erc1155Template ", erc1155Template)
    console.log("blindBox ", blindBoxTemplate)
    console.log("blindBoxV2 ", complateBlindBoxTemplate)

    return deployer.deploy(NFTFactory, 
        cloneFactory,
        erc721Template,
        erc1155Template,
        blindBoxTemplate,
        complateBlindBoxTemplate,
        accounts[0]
    ).then((res) => {
        setConfig('deployed. ' + network + '.NFTFactory', res.address)
    })

    // const nftFactory = await deployProxy(NFTFactory, {
    //     deployer,
    //     initializer: false,
    //     kind: "uups",
    // })
    // console.log('initialize....')

    // await nftFactory.initialize(
    //     cloneFactory,
    //     erc721Template,
    //     erc1155Template,
    //     blindBoxTemplate,
    //     complateBlindBoxTemplate,
    //     accounts[0]
    // ).then(() => {
    //     setConfig('deployed. ' + network + '.NFTFactory', nftFactory.address)
    // })

    console.log('version before ', await nftFactory.version())
    console.log('owner ', await nftFactory.owner())


    // const nftFactory2 = await upgradeProxy(nftFactory.address, NFTFactoryV2, { deployer })

    // console.log('version after ', await nftFactory2.version_2())


    // console.log()

}