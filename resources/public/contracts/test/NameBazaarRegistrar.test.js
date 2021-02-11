const {expect} = require("chai");

const zeroAddress = '0x0000000000000000000000000000000000000000'

describe("Name bazaar registrar", function () {
  let NameBazaarRegistrar, registrar;
  let ENS, ens;
  let owner;
  let addr1;
  const rootNode = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const ethLabel = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('eth'));
  const ethRoot = ethers.utils.namehash('eth');

  beforeEach(async function () {
    ENS = await ethers.getContractFactory("ENSRegistry");
    ens = await ENS.deploy();

    NameBazaarRegistrar = await ethers.getContractFactory("NameBazaarRegistrar");
    registrar = await NameBazaarRegistrar.deploy(ens.address, ethRoot);

    [owner, addr1] = await ethers.getSigners(); // we don't need all signer addresses

    await ens.setSubnodeOwner(rootNode, ethLabel, registrar.address);
  });

  it('successfully deploys', async () => {
    expect(await ens.owner(ethRoot)).to.equal(registrar.address);
  })

  describe('Eth registrar', () => {
    it("can create domain using NameBazaar.register", async function () {
      const hash = ethers.utils.namehash('domain.eth');
      const label = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('domain'));

      expect(await ens.owner(ethRoot)).to.equal(registrar.address);
      expect(await ens.owner(hash)).to.equal(zeroAddress);
      await expect(registrar.register(label))
        .to.emit(ens, 'NewOwner')
        .withArgs(ethRoot, label, owner.address)
      expect(await ens.owner(hash)).to.equal(owner.address);
    });

    it('should allow creating subnodes', async () => {
      const root = ethers.utils.namehash('domain.eth');
      const label = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('domain'));
      await registrar.register(label)
      const subdomainRoot = ethers.utils.namehash('sub.domain.eth');
      const subdomainLabel = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('sub'));

      expect(await ens.owner(subdomainRoot)).to.equal(zeroAddress);
      await expect(ens.setSubnodeOwner(root, subdomainLabel, owner.address))
        .to.emit(ens, 'NewOwner')
        .withArgs(root, subdomainLabel, owner.address);
      expect(await ens.owner(subdomainRoot)).to.equal(owner.address);
    })

    it('should NOT allow creating subnodes for non-owner', async () => {
      const root = ethers.utils.namehash('domain.eth');
      const label = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('domain'));
      await registrar.register(label)
      const subdomainRoot = ethers.utils.namehash('sub.domain.eth');
      const subdomainLabel = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('sub'));

      // change the sender (signer) of the contract
      ens = ens.connect(addr1)

      try {
        await ens.setSubnodeOwner(root, subdomainLabel, addr1.address)
      } catch (e) {
        expect(e.message).to.equal('Transaction reverted without a reason')
      }

      expect(await ens.owner(subdomainRoot)).to.equal(zeroAddress);
      expect(await ens.owner(root)).to.equal(owner.address);
    })

    describe('domain info', () => {
      it('can get info about non existing domain', async () => {
        const label = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('domain'));
        const info = await registrar.domainInfo(label)
        expect(info[0]).to.equal(true)
        expect(info[1].toNumber()).to.equal(0)
        expect(info[2]).to.equal(zeroAddress)
      })

      it('can get info about existing domain', async () => {
        const label = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('domain'));
        await registrar.register(label)

        const info = await registrar.domainInfo(label)
        expect(info[0]).to.equal(false)
        expect(info[1].toNumber()).to.be.gte(0)
        expect(info[2]).to.equal(owner.address)
      })
    })
  })
});