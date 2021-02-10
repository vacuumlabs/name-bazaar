pragma solidity ^0.5.17;

/**
 * @dev This contract is for testing purposes only. It poses as permanent
 * top level registrar governing the ownership of eth subdomains.
 */

import "@ensdomains/ethregistrar/contracts/BaseRegistrarImplementation.sol";

contract NameBazaarRegistrar is BaseRegistrarImplementation {
    /**
     * @dev Constructs a new Registrar, with the provided address as the owner of the root node.
     *
     * @param ens The address of the ENS
     * @param rootNode The hash of the root node.
     */
    constructor(ENS ens, bytes32 rootNode) BaseRegistrarImplementation(ens, rootNode) public {}

    /**
     * @dev Convenience function added by NameBazaar for instant registration
     *      used for development only
     *
     * @param hash The sha3 hash of the label to register.
     */
    function register(bytes32 hash) public payable {
        controllers[msg.sender] = true;
        emit ControllerAdded(msg.sender);
        _register(uint256(hash), msg.sender, 365 days, true);
    }

    /**
     * @dev Return the owner of a domain or zero address if there
     *      no owner.
     *
     * @param token The sha3 hash of the label to get owner for.
     *
     */
    function ownerOrZeroAddress(uint256 token) internal view returns (address) {
        if (expiries[token] <= now) return address(0);
        else return ownerOf(token);
    }

    /**
     * @dev Return information about a particular domain hash.
     *
     * @param hash The sha3 hash of the label to retrieve
     *              information from.
     */
    function domainInfo(bytes32 hash) external view returns (bool, uint, address) {
        uint256 token = uint256(hash);
        return (available(token), expiries[token], ownerOrZeroAddress(token));
    }
}
