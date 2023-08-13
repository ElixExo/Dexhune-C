// SPDX-License-Identifier: BSD-3-Clause
/// @title Dexhune Owner and Management Logic
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity >=0.4.22 <0.9.0;
import "./DexhuneBase.sol";

contract DexhuneConfig {
    //  30 seconds or 15 blocks, but in the testnet version we'll do 5 minutes
    uint256 internal constant MAXIMUM_VOTES_PER_PROPOSAL = 1000;
    uint256 internal constant BLOCKS_PER_SECOND = 2;
    /// @dev Total proposal duration in seconds
    uint256 internal constant PROPOSAL_DURATION = 300; // 15 blocks per 30 seconds
    uint256 internal constant PROPOSAL_BLOCKS = BLOCKS_PER_SECOND * PROPOSAL_DURATION;

    bool public transferCooldown = true;
    uint public cooldownTimeout = BLOCKS_PER_SECOND * 60;
}

abstract contract DexhuneRoot is DexhuneConfig {
    address public owner;
    uint256 collectionCount;
    mapping(uint256 => NFTCollection) public collections;

    struct NFTCollection {
        address contractAddr;
        address[] nfts;
    }

    constructor() {
        owner = msg.sender;
    }
    
    function ensureOwnership() private view {
        require(msg.sender == owner, "This method can only be called by the owner of this smart contract");
    }

    function transferOwnership(address _address) public {
        ensureOwnership();

        address oldAddress = owner;
        owner = _address;
        emit transferredOwnership(oldAddress, owner);
    }

    function addNFTCollection(address _contractAddress, address[] memory nfts) public {
        ensureOwnership();
        require(_contractAddress != address(0), "An NFT collection cannot have an empty address");

        NFTCollection memory col = collections[collectionCount];
        col.contractAddr = _contractAddress;
        col.nfts = nfts;

        emit addedNFTCollection(collectionCount);
        collectionCount++;
    }

    function removeNFTCollection(uint256 _id) public {
        ensureOwnership();

        NFTCollection memory col = collections[_id];
        require(col.contractAddr == address(0), "The provided NFT collection does not exist");
        
        delete collections[_id];
        emit removedNFTCollection(_id);
    }

    function setTransferTimeout(bool _enabled) public {
        ensureOwnership();
        transferCooldown = _enabled;
    }

    function setCooldownTimeout(uint _timeout) public {
        ensureOwnership();

        cooldownTimeout = _timeout;
    }


    /// @notice Ownership of Dexhune has been transferred
    /// @dev Transfers ownership of the contract to another address
    /// @param from Address of the previous owner
    /// @param to Address of the new owner
    event transferredOwnership(address from, address to);

    /// @notice An NFT collection has been added
    /// @dev Adds an NFT collection
    /// @param id Id of the collection
    event addedNFTCollection(uint256 id);

    /// @notice An NFT collection has been removed
    /// @dev Removes an NFT collection
    /// @param id Id of the collection
    event removedNFTCollection(uint256 id);
}