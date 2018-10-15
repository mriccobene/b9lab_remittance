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

const txCost = require("../utils/txCost");

const Remittance2 = artifacts.require("Remittance2");
const DossierLib = artifacts.require("DossierLib");

// Test
contract("Remittance2", function(accounts) {
    const MAX_GAS = 4700000;

    let owner, alice, bob, carol;
    before("check accounts", async function() {
        assert.isAtLeast(accounts.length, 4, "not enough accounts");
        [owner, alice, bob, carol] = accounts;
    });

    let instance, lib;
    beforeEach("create a new Remittance instance", async function() {
        //let instance = await Remittance.deployed();     // prefer to create a fresh instance before each test
        instance = await Remittance2.new({ from: owner, gas: MAX_GAS });
        lib = await DossierLib.new({ from: owner, gas: MAX_GAS });
    });

    describe("#usual user case", async function() {

        it("should open and close dossier correctly", async function() {
            let receiverSecret = "Hello Bob!";
            let remitterSecret = "Hello Carol!";
            let amount = web3.toBigNumber(web3.toWei(0.1, "ether"));

            let receiverSecretHash = await lib.secretHash(receiverSecret);
            let remitterSecretHash = await lib.secretHash(remitterSecret);

            await instance.open(bob, receiverSecretHash, carol, remitterSecretHash, { value: amount, from: alice, gas: MAX_GAS });

            let dossierId = await lib.dossierId(alice, bob, receiverSecretHash, carol, remitterSecretHash);

            let carolInitialBalance = await web3.eth.getBalancePromise(carol);

            let tx = await instance.close(dossierId, receiverSecret, remitterSecret, { from: carol, gas: MAX_GAS });

            const closeCost = await txCost(tx.receipt);

            const carolFinalBalance_estimated = carolInitialBalance.add(amount).sub(closeCost);

            let carolFinalBalance = await web3.eth.getBalancePromise(carol);

            assert(carolFinalBalance.toString() == carolFinalBalance_estimated.toString(),
                `carol end balance doesn't match, expected ${carolFinalBalance_estimated.toString()}, actual ${carolFinalBalance.toString()}`);

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

});