/*
    Source: https://github.com/b9lab/b9_faucet.../test/throttledFaucet.js
    Author: Xavier Leprêtre
    Modify: added testRPC identificaiont - Mike

    Import:
        web3.eth.getPastTimestamp = require("../utils/getPastTimestamp.js");
*/

const addEvmFunctions = require("../utils/evmFunctions.js");
const addMinerFunctions = require("../utils/minerFunctions.js");

const Promise = require("bluebird");
Promise.retry = require("bluebird-retry");

addEvmFunctions(web3);
addMinerFunctions(web3);

if (typeof web3.eth.getBlockPromise !== "function") {
    Promise.promisifyAll(web3.eth, { suffix: "Promise" });
}
if (typeof web3.evm.increaseTimePromise !== "function") {
    Promise.promisifyAll(web3.evm, { suffix: "Promise" });
}
if (typeof web3.miner.startPromise !== "function") {
    Promise.promisifyAll(web3.miner, { suffix: "Promise" });
}

/**
 * @param {!Number} timestamp, the timestamp that we want the latest block to get past.
 * @returns {!Promise} yields when a block is past the timestamp.
 */
module.exports = function getPastTimestamp(timestamp) {
    let isTestRPC;
    return web3.version.getNodePromise()
        .then(node => {
            isTestRPC = node.indexOf("EthereumJS TestRPC") >= 0;
            return web3.eth.getBlockPromise("latest");
        })
        .then(block => {
            if (isTestRPC) {
                return web3.evm.increaseTimePromise(timestamp - block.timestamp)
                    .then(() => web3.evm.minePromise());
            } else {
                // Wait for Geth to have mined a block after the deadline
                return Promise.delay((timestamp - block.timestamp) * 1000)
                    .then(() => Promise.retry(() => web3.eth.getBlockPromise("latest")
                            .then(block => {
                                if (block.timestamp < timestamp) {
                                    return web3.miner.startPromise(1)
                                        .then(() => { throw new Error("Not ready yet"); });
                                }
                            }),
                        { max_tries: 100, interval: 1000, timeout: 100000 }));
            }
        });
}