// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { OApp, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OmniName } from "./OmniName.sol";
import { L2Registry, Text, Addr } from "./L2Registry.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Registrar (for Layer 2)
/// @dev This is a simple registrar contract that is mean to be modified.
contract L2Registrar is OApp {
    /// @notice Emitted when a new name is registered
    /// @param label The registered name
    /// @param owner The owner of the newly registered name
    event NameRegistered(string indexed label, address indexed owner);
    /// @notice Emitted when records are set for a labelhash
    /// @param labelhash The labelhash that was updated
    /// @param texts The texts that were set
    /// @param addrs The addrs that were set
    /// @param chash The content hash that was set
    event RecordsSet(bytes32 indexed labelhash, Text[] texts, Addr[] addrs, bytes chash);

    /// @notice Reference to the target registry contract
    /// @dev Immutable to save gas and prevent manipulation
    L2Registry public immutable targetRegistry;
    OmniName public immutable omniname;

    /// @notice Initializes the registrar with a registry contract
    constructor(OmniName _omniname) OApp(address(_omniname.endpoint()), _omniname.owner()) Ownable(_omniname.owner()) {
        omniname = _omniname;
        targetRegistry = new L2Registry();
    }

    /// @notice Checks if a given tokenId is available for registration
    /// @param tokenId The tokenId to check availability for
    /// @return available True if the tokenId can be registered, false if already taken
    function available(uint256 tokenId) public view returns (bool) {
        return bytes(targetRegistry.labelFor(bytes32(tokenId))).length == 0;
    }

    /// @notice Registers a new name
    /// @param label The name to register
    /// @param owner The address that will own the name
    function register(string memory label, address owner) public {
        targetRegistry.register(label, owner);
        // Set the mainnet resolved address
        targetRegistry.setAddr(
            keccak256(bytes(label)), // Convert label to bytes32 hash
            60, // Mainnet coinType
            abi.encodePacked(owner) // Convert address to bytes
        );
        emit NameRegistered(label, owner);
    }

    function setRecords(bytes32 labelhash, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public {
        if (omniname.ownerOf(uint256(labelhash)) != msg.sender) {
            revert("Not owner");
        }
        targetRegistry.setRecords(labelhash, texts, addrs, chash);
        emit RecordsSet(labelhash, texts, addrs, chash);
    }

    function registerAndSetRecords(string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public {
        register(label, owner);
        setRecords(keccak256(bytes(label)), texts, addrs, chash);
    }
    /**
     * @dev Called when data is received from the protocol. It overrides the equivalent function in the parent contract.
     * Protocol messages are defined as packets, comprised of the following parameters.
     * @param _origin A struct containing information about where the packet came from.
     * @param _guid A global unique identifier for tracking the packet.
     * @param payload Encoded message.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address,  // Executor address as specified by the OApp.
        bytes calldata  // Any extra data or options to trigger on receipt.
    ) internal override {
        _origin;
        _guid;
        (string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) = abi.decode(payload, (string, address, Text[], Addr[], bytes));
        if (available(uint256(keccak256(abi.encodePacked(label))))) {
            registerAndSetRecords(label, owner, texts, addrs, chash);
        } else { // FIXME: Should we check if the sender is the owner?
            setRecords(keccak256(bytes(label)), texts, addrs, chash);
        }
    }
}
