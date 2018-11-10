

/**
 * Returns tx cost from tx receipt
 *
 * Author: Mike
 *
 * Import:
 *     web3.eth.txCost = require("../utils/txCost.js");
 */

module.exports = async function txCost(txReceipt) {
    let txDetails = await this.getTransaction(txReceipt.transactionHash);
    //console.log(txDetails);

    let txCost = txDetails.gasPrice.mul(txReceipt.gasUsed);
    //console.log(txCost);

    return txCost;
};