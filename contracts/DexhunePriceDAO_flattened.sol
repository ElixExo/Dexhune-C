// SPDX-License-Identifier: BSD-3-Clause
// File: contracts/DexhuneBase.sol


/// @title Dexhune Events and Interfaces
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

contract DexhuneBase {    
     struct PriceProposal {
        uint256 id;
        string description;
        bool finalized;
        uint256 votesUp;
        uint256 votesDown;
        string value;
        uint256 deadline;   
    }
}
// File: contracts/DexhuneRoot.sol


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
// File: contracts/ERC721.sol


/// @title ERC721 Proxy
/// Source: OpenZeppelin Contracts v4.4.1
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/DexhunePriceDAO.sol


/// @title Dexhune Price DAO Logic
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




error NotEligibleToVote();
error AlreadyVoted();
error ProposalDoesNotExist();
error VotingDeactivated();
error ProposalIsStillActive();

contract DexhunePriceDAO is DexhuneBase, DexhuneRoot {    
    string price;
    mapping(uint256 => mapping(address => int8)) votes;
    mapping(address => uint256) tickets;

    function getPrice() public view returns(string memory) {
        return price;
    }

    function proposePrice(string memory _desc, string memory _price) external {
        uint256 id = PriceProposals.length;
        PriceProposal memory p = PriceProposal(id, _desc, false, 0, 0, 
            _price, block.number + PROPOSAL_BLOCKS);

        PriceProposals.push(p);
        
        emit ProposalCreated(id, _desc, msg.sender);
    }

    function voteUp(uint256 _id) external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }
        
        PriceProposal storage p = ensureProposal(_id);

        if (block.number > p.deadline) {
            revert VotingDeactivated();
        }

        int8 value = votes[_id][msg.sender];

        if (value == 1 || value == -1) {
            revert AlreadyVoted();
        }

        p.votesUp++;
        votes[_id][msg.sender] = 1;
        emit VotedUp(msg.sender, _id);
    }

    function voteDown(uint256 _id) external {
        if (!ensureEligible()) {
            revert NotEligibleToVote();
        }
        
        PriceProposal storage p = ensureProposal(_id);

        if (block.number > p.deadline) {
            revert VotingDeactivated();
        }
        
        int8 value = votes[_id][msg.sender];

        if (value == 1 || value == -1) {
            revert AlreadyVoted();
        }

        p.votesDown++;
        votes[_id][msg.sender] = -1;
        emit VotedDown(msg.sender, _id);
    }

    function finalizePriceProposal(uint256 _id) external {
        PriceProposal storage p = ensureProposal(_id);

        if (block.number < p.deadline) {
            revert ProposalIsStillActive();
        }

        if (p.finalized) {
            return;
        }

        if (p.votesUp > p.votesDown) {
            emit PriceUpdated(price, p.value);
            price = p.value;

            emit ProposalFinalized(_id, true);
            
        } else {
            emit ProposalFinalized(_id, false);
        }

        p.finalized = true;
    }

    function ensureEligible() private view returns(bool) {
        for (uint i = 0; i < NFTCollections.length; i++) {
            address addr = NFTCollections[i];
            IERC721 collection = IERC721(addr);

            if (collection.balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        
        return false;
    }

    function ensureProposal(uint256 _id) private view returns(PriceProposal storage) {
        if (_id >= PriceProposals.length) {
            revert ProposalDoesNotExist();
        }

        return PriceProposals[_id];
    }

    /// @notice A new proposal was created
    /// @dev Notifies that a new proposal was created
    /// @param id Id of the proposal
    /// @param description Description of the proposal
    /// @param proposer Address of the proposer
    event ProposalCreated(uint256 id, string description, address proposer);

    /// @notice A proposal has been voted up
    /// @dev Notifies that a proposal has been voted up
    /// @param voter Address of the voter
    /// @param proposalId Id of the proposal
    event VotedUp(address voter, uint256 proposalId);

    /// @notice A proposal has been voted down
    /// @dev Notifies that a proposal has been voted down
    /// @param voter Address of the voter
    /// @param proposalId Id of the proposal
    event VotedDown(address voter, uint256 proposalId);

    /// @notice Voting result of the Proposal
    /// @dev Notifies that a proposal has been finalized
    /// @param id Id of the proposal
    /// @param passed Result of the voting on proposal, passed defines that the proposal is accepted by the voters
    event ProposalFinalized(uint256 id, bool passed);

    /// @notice The price has been updated
    /// @dev Notifies that the price has been updated
    /// @param oldPrice The previous price that was replaced
    /// @param newPrice The new price replacing the previous price
    event PriceUpdated(string oldPrice, string newPrice);
}

