// SPDX-License-Identifier: BSD-3-Clause
/// @title Base objects for Dexhune Price Dao
/*
*    ........................................................
*    .%%%%%...%%%%%%..%%..%%..%%..%%..%%..%%..%%..%%..%%%%%%.
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%%.%%..%%.....
*    .%%..%%..%%%%......%%....%%%%%%..%%..%%..%%.%%%..%%%%...
*    .%%..%%..%%.......%%%%...%%..%%..%%..%%..%%..%%..%%.....
*    .%%%%%...%%%%%%..%%..%%..%%..%%...%%%%...%%..%%..%%%%%%.
*    ........................................................
*/

pragma solidity ^0.8.21;

import "./utils/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";

abstract contract DexhunePriceDAOBase is Ownable {
    IERC20 internal _token;
    IERC721 internal _nft;

    address nftAddress;
    address tokenAddress;

    function assignNFTCollection(address addr) external ownerOnly {
        IERC721 nft = IERC721(addr);
        nft.balanceOf(address(this));
        
        _nft = nft;
        nftAddress = addr;

        emit AssignedNFTCollection(addr);
    }

    function assignTokenAddress(address addr) external ownerOnly {
        IERC20 token = IERC20(addr);
        token.balanceOf(address(this));

        _token = token;
        tokenAddress = addr;

        emit AssignedToken(addr);
    }

    function _getHolderBalance() internal view returns (uint256) {
        return _nft.balanceOf(msg.sender);
    }

    function _getHolderBalance(address addr) internal view returns (uint256) {
        return _nft.balanceOf(addr);
    }

    function _abs(int16 x) internal pure returns (uint16) {
        return uint16(x >= 0 ? x : -x);
    }


    struct PriceProposal {
        address proposerAddr;
        string value;
        string description;        
        bool finalized;
    }

    /// @notice A NFT collection has been assigned
    /// @dev Assigns an NFT collection
    /// @param addr The contract address of the NFT collection
    event AssignedNFTCollection(address addr);

    /// @notice An ERC20 token has been assigned
    /// @dev Assigns an ERC20 token for internal transactions
    /// @param addr The contract address of the ERC20 token
    event AssignedToken(address addr);



    /// @notice A new proposal was created
    /// @dev Notifies that a new proposal was created
    /// @param price The proposed price
    /// @param description Description of the proposal
    /// @param proposer Address of the proposer
    event ProposalCreated(string price, string description, address proposer);

    /// @notice A proposal has been voted up
    /// @dev Notifies that a proposal has been voted up
    /// @param voter Address of the voter
    /// @param votes Total amount of votees cast
    event VotedUp(address voter, uint16 votes);

    /// @notice A proposal has been voted down
    /// @dev Notifies that a proposal has been voted down
    /// @param voter Address of the voter
    /// @param votes Total amount of votees cast
    event VotedDown(address voter, uint16 votes);

    // /// @notice Voting result of the Proposal
    // /// @dev Notifies that a proposal has been finalized
    // /// @param id Id of the proposal
    // /// @param passed Result of the voting on proposal, passed defines that the proposal is accepted by the voters
    // event ProposalFinalized(uint256 id, bool passed);

    // /// @notice The price has been updated
    // /// @dev Notifies that the price has been updated
    // /// @param oldPrice The previous price that was replaced
    // /// @param newPrice The new price replacing the previous price
    // event PriceUpdated(string oldPrice, string newPrice);

    /// @notice A proposal has been denied
    /// @param _for Total amount of votes cast in favour
    /// @param _against Total amount of votes cast against
    event ProposalDenied(uint16 _for, uint16 _against);

    /// @notice A proposal has been passed
    /// @param _for Total amount of votes cast in favour
    /// @param _against Total amount of votes cast against
    /// @param newPrice The newly updated price
    event ProposalPassed(uint16 _for, uint16 _against, string newPrice);

    /// @notice Indicates that a proposer has been rewarded
    /// @param addr Address of the proposer
    /// @param amount Amount sent to the proposer
    event RewardedProposer(address addr, uint256 amount);
    


    error NoActiveProposal();
    error NotEligible();
    error AlreadyVoted();
    error ProposalDoesNotExist();
    error VotingDeactivated();
    error ProposalIsStillActive();
    error ProposalHasExpired();
    error ProposalAlreadyFinalized();
}