const AuctionOffering = artifacts.require("AuctionOffering");

contract('Namebazaar contract tests', (accounts) => {
  it('works', async () => {
    const auctionOffering = await AuctionOffering.deployed()

    const before = await auctionOffering.auctionOffering()
    assert.equal(before.endTime.toNumber(), 0)

    await auctionOffering.addEndTime(123)

    const after = await auctionOffering.auctionOffering()
    assert.equal(after.endTime.toNumber(), 123)
  });

  it('can debug', async () => {
    const auctionOffering = await AuctionOffering.deployed()

    // https://www.trufflesuite.com/docs/truffle/getting-started/debugging-your-contracts
    // The magic `debug` function doesn't work for me
    // await debug(auctionOffering.addEndTime(123))

    await auctionOffering.addEndTime(123)
    const after = await auctionOffering.auctionOffering()
    assert.equal(after.endTime.toNumber(), 789)
  });
});
