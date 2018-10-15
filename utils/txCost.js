

/**
 * Returns tx cost from tx receipt
 */

module.exports = async function txCost(txReceipt) {
    let txDetails = await web3.eth.getTransaction(txReceipt.transactionHash);
    //console.log(txDetails);

    let txCost = txDetails.gasPrice.mul(txReceipt.gasUsed);
    //console.log(txCost);

    return txCost;
};
