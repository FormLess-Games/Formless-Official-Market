
const InitializableERC721 = artifacts.require('InitializableERC721')
const InitializableERC1155 = artifacts.require('InitializableERC1155')
const BlindBox = artifacts.require('BlindBox')
const BlindBoxV2 = artifacts.require('BlindBoxV2')
const CloneFactory = artifacts.require('CloneFactory')

const { setConfig } = require('./config.js')

module.exports = async function (deployer, network) {
    if (network !== 'mainnet') {
        await deployer.deploy(InitializableERC721)
        let initializableERC721 = await InitializableERC721.deployed()
        setConfig('deployed.' + network + '.InitializableERC721', initializableERC721.address)

        await deployer.deploy(InitializableERC1155)
        let initializableERC1155 = await InitializableERC1155.deployed()
        setConfig('deployed.' + network + '.InitializableERC1155', initializableERC1155.address)

        await deployer.deploy(BlindBox)
        let blindBox = await BlindBox.deployed()
        setConfig('deployed.' + network + '.BlindBox', blindBox.address)

        await deployer.deploy(BlindBoxV2)
        let blindBoxV2 = await BlindBoxV2.deployed()
        setConfig('deployed.' + network + '.BlindBoxV2', blindBoxV2.address)

        await deployer.deploy(CloneFactory)
        let cloneFactory = await CloneFactory.deployed()
        setConfig('deployed.' + network + '.CloneFactory', cloneFactory.address)

    }
}