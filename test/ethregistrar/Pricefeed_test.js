const  { expect } = require("chai");
const { ethers } = require("hardhat");
const DummyOracle = artifacts.require('./DummyOracle');
const StablePriceOracle = artifacts.require('./StablePriceOracle');

const toBN = require('web3-utils').toBN;

describe("Pricefeed", function () {
  it("Should return the new price once changed", async function () {

    // Dummy oracle with 1 ETH == 10 USD
    var dummyOracle = await DummyOracle.new(toBN(1000000000));
    // 4 attousd per second for 3 character names, 2 attousd per second for 4 character names,
    // 1 attousd per second for longer names.

    const pricefeed = await StablePriceOracle.new('0x5498BB86BC934c8D34FDA08E81D444153d0D06aD', [1, 4, 3, 2, 3]);

    const getLatestPrice = await pricefeed.avaxToAttoUSD("1");
    expect(getLatestPrice.toNumber()).to.be.greaterThan(0);
  });
});
