"use strict";

// >truffle.cmd test ./test/test.js --network net42

const promise = require("bluebird");

// Promisify web3
if (typeof web3.eth.getBlockPromise !== "function") {
    promise.promisifyAll(web3.eth, { suffix: "Promise" });
}
if (typeof web3.version.getNodePromise !== "function") {
    promise.promisifyAll(web3.version, { suffix: "Promise" });
}

web3.eth.txCost                     = require("../utils/txCost");
web3.eth.expectedExceptionPromise   = require("../utils/expectedExceptionPromise.js");
web3.eth.getPastTimestamp           = require("../utils/getPastTimestamp.js");
web3.eth.getTransactionReceiptMined = require("../utils/getTransactionReceiptMined.js");

const Remittance = artifacts.require("Remittance");

// Test
contract("Remittance", function(accounts) {
    const MAX_GAS = 4700000;
    const _1day = 60 * 60 * 24;

    let owner, alice, carol;
    before("check accounts", async function() {
        assert.isAtLeast(accounts.length, 3, "not enough accounts");
        [owner, alice, carol] = accounts;
    });

    let instance;
    beforeEach("create a new Remittance instance", async function() {
        //let instance = await Remittance.deployed();     // prefer to create a fresh instance before each test
        instance = await Remittance.new({ from: owner, gas: MAX_GAS });
    });

    describe("#usual use case", async function() {

        it("should open and close dossier correctly", async function() {
            let receiverSecret = "Hello Bob!";
            let remitterSecret = "Hello Carol!";
            let amount = web3.toBigNumber(web3.toWei(0.1, "ether"));

            let currentBlockNumber = await web3.eth.getBlockNumberPromise();
            let currentBlock = await web3.eth.getBlock(currentBlockNumber);
            let now = currentBlock.timestamp;
            let deadline = now + _1day * 10;

            let dossierId = await instance.computeDossierId(alice, receiverSecret, carol, remitterSecret);
            await instance.open(dossierId, deadline, { value: amount, from: alice, gas: MAX_GAS });

            let carolInitialBalance = await web3.eth.getBalancePromise(carol);

            let tx = await instance.close(alice, receiverSecret, remitterSecret, { from: carol, gas: MAX_GAS });

            const closeCost = await web3.eth.txCost(tx.receipt);

            const carolFinalBalance_estimated = carolInitialBalance.add(amount).sub(closeCost);

            let carolFinalBalance = await web3.eth.getBalancePromise(carol);

            assert.equal(carolFinalBalance.toString(10), carolFinalBalance_estimated.toString(10), "carol end balance doesn't match");

        });

    });

    describe("#dossier opening", async function() {

        it("should ... correctly", async function() {
            // todo: write test
        });

        // todo: write more tests
    });

    describe("#dossier closing", async function() {

        beforeEach("open dossier", async function() {
            // todo: open a dossier
        });

        it("should ... correctly", async function() {
            // todo: write test
        });

        // todo: write more tests
    });


    describe("#dossier aborting", async function() {

        let dossierId, receiverSecret, remitterSecret, amount, deadline;
        let aliceBalanceAfterOpening;

        beforeEach("open dossier", async function() {
            receiverSecret = "Hello Bob!";
            remitterSecret = "Hello Carol!";
            amount = web3.toBigNumber(web3.toWei(0.1, "ether"));

            let currentBlockNumber = await web3.eth.getBlockNumberPromise();
            let currentBlock = await web3.eth.getBlock(currentBlockNumber);
            let now = currentBlock.timestamp;
            deadline = now + _1day * 3;

            dossierId = await instance.computeDossierId(alice, receiverSecret, carol, remitterSecret);
            await instance.open(dossierId, deadline, { value: amount, from: alice, gas: MAX_GAS });

            aliceBalanceAfterOpening = await web3.eth.getBalancePromise(alice);
        });

        it("should abort and return funds correctly", async function() {
            await web3.eth.getPastTimestamp(deadline);

            let tx = await instance.abort(carol, receiverSecret, remitterSecret, { from: alice, gas: MAX_GAS });

            const abortCost = await web3.eth.txCost(tx.receipt);

            const aliceFinalBalance_estimated = aliceBalanceAfterOpening.add(amount).sub(abortCost);

            let aliceFinalBalance = await web3.eth.getBalancePromise(alice);

            assert.equal(aliceFinalBalance.toString(10), aliceFinalBalance_estimated.toString(10), "alice end balance doesn't match");
        });

        it("should reject aborting before deadline", async function() {
            // here we do not wait deadline

            let currentBlockNumber = await web3.eth.getBlockNumberPromise();
            let currentBlock = await web3.eth.getBlock(currentBlockNumber);
            let now = currentBlock.timestamp;

            await web3.eth.expectedExceptionPromise( () => {
                return instance.abort(carol, receiverSecret, remitterSecret, { from: alice, gas: MAX_GAS });
            }, MAX_GAS);

        });
    });
});