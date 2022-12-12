const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');
const truffleAssert = require("truffle-assertions");

describe('BBB', function () {

    //　テスト用の変数
    const BBBToken = "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4";
    const REWARD_RATE = 50;

    /**
     * deploy function
     * @returns
     */
    async function deployContract() {
          const [owner, otherAccount] = await ethers.getSigners();
          // コントララクトをデプロイする。
          const BBB = await ethers.getContractFactory('BBB');
          const bbb = await BBB.deploy();
          
          return {
                bbb,
                owner,
                otherAccount,
          };
    };

    /**
     * test
     */
    describe("test", function () {
        it("【error pattern】add token", async function () {
            // コントラクトをデプロイする。
            const { bbb } = await loadFixture(deployContract);
            // add token
            await truffleAssert.reverts(
                bbb.addWhitelist(BBBToken)
            );
        });

        it("【error pattern2】add token", async function () {
            // コントラクトをデプロイする。
            const { bbb , otherAccount } = await loadFixture(deployContract);
            // add token
            await truffleAssert.reverts(
                bbb.connect(otherAccount).addWhitelist(BBBToken)
            );
        });

        it("【error pattern】get reward", async function () {
            // コントラクトをデプロイする。
            const { bbb } = await loadFixture(deployContract);
            // add token
            await truffleAssert.reverts(
                bbb.getReward(BBBToken)
            );
        });
    });
});