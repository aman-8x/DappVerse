// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title DappVerse
 * @notice A decentralized registry + permission system for managing DApps 
 *         and tracking user actions across a decentralized ecosystem.
 */

contract DappVerse {
    address public owner;

    struct DApp {
        string name;
        address creator;
        bool active;
    }

    struct Permission {
        bool canExecute;
        bool canManage;
    }

    struct ActivityLog {
        uint256 dappId;
        address user;
        string action;
        uint256 timestamp;
    }

    uint256 public dappCount;
    ActivityLog[] public logs;

    mapping(uint256 => DApp) public dapps;
    mapping(uint256 => mapping(address => Permission)) public dappPermissions;

    event DAppRegistered(uint256 indexed dappId, string name, address indexed creator);
    event DAppStatusUpdated(uint256 indexed dappId, bool active);
    event PermissionAssigned(uint256 indexed dappId, address indexed user, bool execute, bool manage);
    event ActionLogged(uint256 indexed dappId, address indexed user, string action);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyManager(uint256 dappId) {
        require(dappPermissions[dappId][msg.sender].canManage, "No manage permission");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────
    // ⭐ REGISTER A NEW DAPP
    // ─────────────────────────────────────────────
    function registerDApp(string calldata name) external {
        dappCount++;
        dapps[dappCount] = DApp(name, msg.sender, true);

        // Creator gets full permissions
        dappPermissions[dappCount][msg.sender] = Permission(true, true);

        emit DAppRegistered(dappCount, name, msg.sender);
    }

    // ─────────────────────────────────────────────
    // ⭐ UPDATE DAPP STATUS (OWNER ONLY)
    // ─────────────────────────────────────────────
    function updateDAppStatus(uint256 dappId, bool active) external onlyOwner {
        require(bytes(dapps[dappId].name).length > 0, "DApp not found");

        dapps[dappId].active = active;

        emit DAppStatusUpdated(dappId, active);
    }

    // ─────────────────────────────────────────────
    // ⭐ ASSIGN OR UPDATE PERMISSIONS
    // ─────────────────────────────────────────────
    function assignPermission(
        uint256 dappId,
        address user,
        bool canExecute,
        bool canManage
    ) external onlyManager(dappId) {
        dappPermissions[dappId][user] = Permission(canExecute, canManage);

        emit PermissionAssigned(dappId, user, canExecute, canManage);
    }

    // ─────────────────────────────────────────────
    // ⭐ LOG AN ACTION FROM INSIDE A DAPP
    // ─────────────────────────────────────────────
    function logAction(uint256 dappId, string calldata action) external {
        require(dapps[dappId].active, "DApp inactive");
        require(dappPermissions[dappId][msg.sender].canExecute, "No execute permission");

        logs.push(ActivityLog(dappId, msg.sender, action, block.timestamp));

        emit ActionLogged(dappId, msg.sender, action);
    }

    // ─────────────────────────────────────────────
    // ⭐ VIEW FUNCTIONS
    // ─────────────────────────────────────────────
    function getLogsCount() external view returns (uint256) {
        return logs.length;
    }

    function getLog(uint256 index) external view returns (ActivityLog memory) {
        return logs[index];
    }

    function getDApp(uint256 dappId) external view returns (DApp memory) {
        return dapps[dappId];
    }

    function getPermission(uint256 dappId, address user) external view returns (Permission memory) {
        return dappPermissions[dappId][user];
    }
}

