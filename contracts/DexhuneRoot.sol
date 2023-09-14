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

    bool public transferCooldown = true;
    uint public cooldownTimeout = BLOCKS_PER_SECOND * 60;
}

abstract contract DexhuneRoot is DexhuneConfig, DexhuneBase {
    address public owner;
    PriceProposal[] public PriceProposals;
    address[] public NFTCollections;

    constructor() {
        owner = msg.sender;
        // PriceProposals = new PriceProposal[](0);
        NFTCollections = new address[](0);
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

    function addNFTCollection(address _contractAddress) public {
        ensureOwnership();
        require(_contractAddress != address(0), "An NFT collection cannot have an empty address");

        uint index = NFTCollections.length;
        NFTCollections.push(_contractAddress);
        emit addedNFTCollection(index, _contractAddress);
    }

    
    function removeNFTCollection(uint256 _index) public {
        ensureOwnership();
        
        require(_index >= 0 && _index < NFTCollections.length, "The requested NFT collection does not exist");

        address addr = NFTCollections[_index];
        
        // https://ethereum.stackexchange.com/a/59234
        NFTCollections[_index] = NFTCollections[NFTCollections.length - 1];
        NFTCollections.pop();
        
        emit removedNFTCollection(_index, addr);
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
    event addedNFTCollection(uint256 id, address collectionAddress);

    /// @notice An NFT collection has been removed
    /// @dev Removes an NFT collection
    /// @param id Id of the collection
    event removedNFTCollection(uint256 id, address collectionAddress);
}