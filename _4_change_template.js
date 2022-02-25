const BlindBox = artifacts.require('BlindBox')
const { setConfig } = require('./migrations/config.js')

module.exports = async function (deployer, network) {
    if (network !== 'mainnet') {
        await deployer.deploy(BlindBox)
        let blindBox = await BlindBox.deployed()
        setConfig('deployed.' + network + '.BlindBox', blindBox.address)
    }
}
