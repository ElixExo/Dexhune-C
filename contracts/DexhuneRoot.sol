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


abstract contract DexhuneRoot is DexhuneBase {
    address public owner;
    uint256 collectionCount;
    mapping(uint256 => NFTCollection) public collections;

    bool public enableTransferTimeout = true;
    uint public cooldownTimeout = BLOCKS_PER_SECOND * 60;

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

        enableTransferTimeout = _enabled;
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