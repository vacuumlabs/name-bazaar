// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Offering
 * @dev Contains base logic for an offering and is meant to be extended.
 */

import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrar.sol";
import "./OfferingRegistry.sol";

contract Offering {

    struct Offering {
        // Order here is important for gas optimisations. Must be fitting into uint265 slots.
        bytes32 node;                       // ENS node
        // WARNING: The contract DOES NOT perform ENS name normalisation, which is up to responsibility of each offchain UI!
        string name;                        // full ENS name
        bytes32 labelHash;                  // hash of ENS label
        address payable originalOwner;      // owner of ENS name, creator of offering
        address newOwner;                   // Address of a new owner of ENS name, buyer
        uint price;                         // Price of the offering, or the highest bid in auction
        uint128 version;                    // version of offering contract
        uint64 createdOn;                   // Time when offering was created
        uint64 finalizedOn;                 // Time when ENS name was transferred to a new owner
    }

    Offering public offering;

    // Hardcoded ENS address. For development will be replaced after compilation. This way we save gas to users deploying offering contracts.
    ENSRegistry public constant ens = ENSRegistry(0x314159265dD8dbb310642f98f50C066173C1259b);

    // Hardcoded namehash of "eth"
    bytes32 public constant rootNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    // Placeholder to be replaced after compilation. This way we save gas to users deploying offering contracts.
    OfferingRegistry public constant offeringRegistry = OfferingRegistry(0xfEEDFEEDfeEDFEedFEEdFEEDFeEdfEEdFeEdFEEd);

    // Placeholder to be replaced after compilation. This way we save gas to users deploying offering contracts.
    address public constant emergencyMultisig = 0xDeEDdeeDDEeDDEEdDEedDEEdDEeDdEeDDEEDDeed;

    /**
     * @dev Modifier to make a function callable only for offering creator
     */
    modifier onlyOriginalOwner() {
        require(isSenderOriginalOwner());
        _;
    }

    /**
     * @dev Modifier to make a function callable only for Namebazaar's Emergency Multisig wallet
     */
    modifier onlyEmergencyMultisig() {
        require(isSenderEmergencyMultisig());
        _;
    }

    /**
     * @dev Modifier to make a function callable only is called by Namebazaar's Emergency Multisig wallet
     */
    modifier onlyWithoutNewOwner() {
        require(offering.newOwner == address(0x0));
        _;
    }

    /**
     * @dev Modifier to make a function callable only when offering contract has name ownership
     */
    modifier onlyWhenContractIsNodeOwner() {
        require(isContractNodeOwner());
        _;
    }


    /**
     * @dev Modifier to make a function callable only when there's not emergency pause
     */
    modifier onlyWhenNotEmergencyPaused() {
        require(!offeringRegistry.isEmergencyPaused());
        _;
    }

    /**
     * @dev Modifier to make a function callable only when offering contract doesn't have name ownership
     */
    modifier onlyWhenContractIsNotNodeOwner() {
        require(!isContractNodeOwner());
        _;
    }

    /**
     * @dev Constructor of offering
     * Should be callable just once, by factory
     */
    function construct(
        bytes32 _node,
        string memory _name,
        bytes32 _labelHash,
        address payable _originalOwner,
        uint128 _version,
        uint _price
    )
        public
        onlyWhenNotEmergencyPaused
    {
        require(offering.createdOn == 0);               // Prevent constructing multiple times
        offering.node = _node;
        offering.name = _name;
        offering.labelHash = _labelHash;
        offering.originalOwner = _originalOwner;
        offering.version = _version;
        offering.createdOn = uint64(block.timestamp);
        offering.price = _price;
    }

    /**
     * @dev Unregisters offering for not displaying it in UI
     * Cannot be run if contract has ownership or it was already transferred to new owner
     */
    function unregister()
        external
        onlyOriginalOwner
        onlyWithoutNewOwner
        onlyWhenContractIsNotNodeOwner
    {
        // New owner is not really this address, but it's the way to recognize if offering
        // was unregistered without having separate var for it, which is costly
        offering.newOwner = address(0xdeaddead);
        fireOnChanged("unregister");
    }

    /**
    * @dev Transfers ENS name ownership back to original owner
    * Can be run only by original owner or emergency multisig
    * Sets newOwner to special address 0xdead
    */
    function reclaimOwnership()
        virtual
        public
        onlyWithoutNewOwner
    {
        bool isEmergency = isSenderEmergencyMultisig();
        require(isEmergency || isSenderOriginalOwner());

        if (isContractNodeOwner()) {
            doTransferOwnership(offering.originalOwner);
        }
        if (isEmergency) {
            // New owner is not really this address, but it's the way to recognize if
            // was disabled in emergency without having separate var for it, which is costly
            offering.newOwner = address(0xdead);
        }
        fireOnChanged("reclaimOwnership");
    }

    /**
    * @dev Transfers name ownership in context of offering contract
    * Cannot be run if ownership was already transferred to new owner
    * @param _newOwner address New owner of ENS name
    */
    function transferOwnership(address payable _newOwner)
        internal
        onlyWhenNotEmergencyPaused
        onlyWithoutNewOwner
    {
        offering.newOwner = _newOwner;
        offering.finalizedOn = uint64(block.timestamp);
        doTransferOwnership(_newOwner);
        fireOnChanged("finalize");
    }

    /**
    * @dev Function to actually do ENS transfer
    * Top level names should be transferred via registrar, so that registration is transferred too
    * @param _newOwner address New owner of ENS name
    */
    function doTransferOwnership(address payable _newOwner)
        private
    {
        if (isNodeTLDOfRegistrar()) {
            uint256 tokenId = uint256(offering.labelHash);
            BaseRegistrar registrar = BaseRegistrar(ens.owner(rootNode));
            registrar.reclaim(tokenId, _newOwner);
            registrar.transferFrom(registrar.ownerOf(tokenId), _newOwner, tokenId);
        } else {
            ens.setOwner(offering.node, _newOwner);
        }
    }

    function doSetSettings(uint _price)
        internal
    {
        offering.price = _price;
    }

    function fireOnChanged(bytes32 eventType, uint[] memory extraData)
        internal
    {
        offeringRegistry.fireOnOfferingChanged(offering.version, eventType, extraData);
    }

    function fireOnChanged(bytes32 eventType) internal {
        fireOnChanged(eventType, new uint[](0));
    }

    /**
    * @dev Returns whether offering contract is owner of ENS name
    * For top level names, offering contract must be also owner of registration
    * @return bool true if contract is ENS node owner
    */
    function isContractNodeOwner() public view returns(bool) {
        if (isNodeTLDOfRegistrar()) {
            uint256 tokenId = uint256(offering.labelHash);
            address registrationOwner = BaseRegistrar(ens.owner(rootNode)).ownerOf(tokenId);
            return registrationOwner == address(this);
        } else {
            return ens.owner(offering.node) == address(this);
        }
    }

    /**
    * @dev Returns whether offering node is top level name of registrar or subname
    * @return bool true if offering node is top level name of registrar
    */
    function isNodeTLDOfRegistrar() public view returns (bool) {
        return offering.node == keccak256(abi.encodePacked(rootNode, offering.labelHash));
    }

    /**
    * @dev Returns whether msg.sender is original owner of ENS name, offering creator
    * @return bool true if msg.sender is original owner
    */
    function isSenderOriginalOwner() public view returns(bool) {
        return msg.sender == offering.originalOwner;
    }

    /**
    * @dev Returns whether msg.sender is emergency multisig address
    * @return bool true if msg.sender is emergency multisig
    */
    function isSenderEmergencyMultisig() public view returns(bool) {
        return msg.sender == emergencyMultisig;
    }

    /**
    * @dev Returns whether offering was cancelled in emergency, by emergency multisig
    * @return bool true if offering was cancelled in emergency
    */
    function wasEmergencyCancelled() public view returns(bool) {
        return offering.newOwner == address(0xdead);
    }
}
