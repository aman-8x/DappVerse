// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title DappVerse
 * @notice A decentralized platform for creating, linking, and rating dApps.
 */
contract DappVerse {

    address public admin;
    uint256 public dappCount;

    struct Dapp {
        uint256 id;
        address creator;
        string dappHash;        // IPFS hash or unique identifier
        string metadataURI;     // Optional metadata URI
        uint256 timestamp;
        bool approved;
        bool rejected;
        uint256[] linkedDapps;
        uint256 upvotes;
        uint256 downvotes;
    }

    mapping(uint256 => Dapp) public dapps;
    mapping(address => uint256[]) public userDapps;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event DappCreated(uint256 indexed id, address indexed creator, string dappHash, string metadataURI);
    event DappLinked(uint256 indexed fromId, uint256 indexed toId);
    event DappApproved(uint256 indexed id);
    event DappRejected(uint256 indexed id, string reason);
    event VoteCast(uint256 indexed dappId, address indexed voter, bool upvote);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "DappVerse: NOT_ADMIN");
        _;
    }

    modifier dappExists(uint256 id) {
        require(id > 0 && id <= dappCount, "DappVerse: DAPP_NOT_FOUND");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createDapp(string calldata dappHash, string calldata metadataURI) external returns (uint256) {
        require(bytes(dappHash).length > 0, "DappVerse: EMPTY_HASH");

        dappCount++;
        dapps[dappCount] = Dapp({
            id: dappCount,
            creator: msg.sender,
            dappHash: dappHash,
            metadataURI: metadataURI,
            timestamp: block.timestamp,
            approved: false,
            rejected: false,
            linkedDapps: new uint256,
            upvotes: 0,
            downvotes: 0
        });

        userDapps[msg.sender].push(dappCount);

        emit DappCreated(dappCount, msg.sender, dappHash, metadataURI);
        return dappCount;
    }

    function linkDapps(uint256 fromId, uint256 toId) external dappExists(fromId) dappExists(toId) {
        require(fromId != toId, "DappVerse: SELF_LINK");
        require(dapps[fromId].creator == msg.sender || msg.sender == admin, "DappVerse: UNAUTHORIZED");

        dapps[fromId].linkedDapps.push(toId);
        dapps[toId].linkedDapps.push(fromId);

        emit DappLinked(fromId, toId);
        emit DappLinked(toId, fromId);
    }

    function approveDapp(uint256 id) external onlyAdmin dappExists(id) {
        Dapp storage d = dapps[id];
        require(!d.approved && !d.rejected, "DappVerse: FINALIZED");
        d.approved = true;
        emit DappApproved(id);
    }

    function rejectDapp(uint256 id, string calldata reason) external onlyAdmin dappExists(id) {
        Dapp storage d = dapps[id];
        require(!d.approved && !d.rejected, "DappVerse: FINALIZED");
        d.rejected = true;
        emit DappRejected(id, reason);
    }

    function vote(uint256 dappId, bool upvote) external dappExists(dappId) {
        require(!hasVoted[dappId][msg.sender], "DappVerse: ALREADY_VOTED");

        Dapp storage d = dapps[dappId];

        if (upvote) {
            d.upvotes++;
        } else {
            d.downvotes++;
        }

        hasVoted[dappId][msg.sender] = true;
        emit VoteCast(dappId, msg.sender, upvote);
    }

    function getDapp(uint256 id) external view dappExists(id) returns (Dapp memory) {
        return dapps[id];
    }

    function getUserDapps(address user) external view returns (uint256[] memory) {
        return userDapps[user];
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "DappVerse: ZERO_ADMIN");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }
}
