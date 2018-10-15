const DossierLib = artifacts.require("DossierLib");
const Remittance2 = artifacts.require("Remittance2");

module.exports = function(deployer, network, accounts) {
    const MAX_GAS = 4700000;

    let owner = accounts[0];
    if (network == "ropsten") {
        owner = "0x";
    }

    // CLEAR deploy pattern
    deployer.then(async () => {

        let lib = await deployer.deploy(DossierLib, { from: owner, gas: MAX_GAS });
        let libReceipt = web3.eth.getTransactionReceipt(lib.transactionHash);
        console.log('  DossierLib deployment gasUsed: ' + libReceipt.gasUsed);

        let link = await deployer.link(DossierLib, Remittance2);

        let instance = await deployer.deploy(Remittance2, { from: owner, gas: MAX_GAS });
        let receipt = web3.eth.getTransactionReceipt(instance.transactionHash);
        console.log('  Remittance2 deployment gasUsed: ' + receipt.gasUsed);


    });

};