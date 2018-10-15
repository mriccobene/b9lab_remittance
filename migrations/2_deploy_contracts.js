const Remittance = artifacts.require("Remittance.sol");

module.exports = function(deployer, network, accounts) {
    const MAX_GAS = 4700000;

    let owner = accounts[0];
    if (network == "ropsten") {
        owner = "0x";
    }

    // CLEAR deploy pattern
    deployer.then(async () => {

        let instance = await deployer.deploy(Remittance, { from: owner, gas: MAX_GAS });
        let receipt = web3.eth.getTransactionReceipt(instance.transactionHash);
        console.log('  Remittance deployment gasUsed: ' + receipt.gasUsed);
    });

};