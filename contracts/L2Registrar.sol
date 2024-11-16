// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { L2Registry, Text, Addr } from "./L2Registry.sol";
import { OmniName } from "./OmniName.sol";

/**
 * @title L2Registrar contract for registering omninames from this and other blockchains.
 * @notice THIS IS AN EXPERIMENTAL CONTRACT. DO NOT USE THIS CODE IN PRODUCTION.
 * @dev This contract uses a PingPong style call (A -> B -> A) using LayerZero's OApp Standard.
 * This contract acts as B, being A OmniRegistrar.
 */
contract L2Registrar is OApp, OAppOptionsType3 {

    /// @notice L2Registry instance for storing registry information.
    L2Registry public immutable targetRegistry;

    /// @notice Omnichian NFT that signals subname ownership.
    OmniName public immutable omniname;

    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3.
    uint16 public constant SEND = 1;
    uint16 public constant SEND_ABA = 2;

    /// @notice Emitted when a return message is successfully sent (B -> A).
    event ReturnRegisterRequest(string label, address owner, uint32 dstEid);

    /// @notice Emitted when a message is received from another chain.
    event RegisterRequestReceived(string label, address owner, uint32 senderEid, bytes32 sender);

    /// @dev Revert with this error when the sender is not the owner of the NFT.
    error NotOwner();

    /**
     * @dev Constructs a new L2Registrar contract instance.
     * @param _omniname The OmniName contract instance.
     */
    constructor(OmniName _omniname) OApp(address(_omniname.endpoint()), _omniname.owner()) Ownable(_omniname.owner()) {
        omniname = _omniname;
        targetRegistry = new L2Registry();
    }

    function register(string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public {
        // It will fail if it's already registered
        _register(label, owner);
        // We shouldn't check the owner here
        targetRegistry.setRecords(targetRegistry.labelHash(label), texts, addrs, chash);
    }

    function updateRecords(string memory label, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public {
        if (!_isNameOwner(label, msg.sender)) {
            revert NotOwner();
        }
        targetRegistry.setRecords(targetRegistry.labelHash(label), texts, addrs, chash);
    }

    function available(string memory label) public view returns (bool) {
        return !_isNameRegistered(label);
    }

    function _register(string memory label, address owner) internal {
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        omniname.mint(owner, uint256(labelhash));
        targetRegistry.register(label, owner);
    }

    function _decodeMessage(bytes calldata payload) internal pure returns (uint16 msgType, string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) {
        return abi.decode(payload, (uint16,string,address,Text[],Addr[],bytes));
    }

    /**
     * @notice Internal function to handle receiving messages from another chain.
     * @dev Decodes and processes the received message based on its type.
     * @param _origin Data about the origin of the received message.
     * @param message The received message content.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*guid*/,
        bytes calldata message,
        address,  // Executor address as specified by the OApp.
        bytes calldata  // Any extra data or options to trigger on receipt.
    ) internal override {
        (uint16 _msgType, string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) = _decodeMessage(message);
        
        if (_msgType == SEND_ABA && !_isNameRegistered(label)) {
            register(label, owner, texts, addrs, chash);

            bytes memory _options = combineOptions(_origin.srcEid, SEND, msg.data[0:0]);

            _lzSend(
                _origin.srcEid,
                abi.encode(label, owner),
                // Future additions should make the data types static so that it is easier to find the array locations.
                _options,
                // Fee in native gas and ZRO token.
                MessagingFee(msg.value, 0),
                // Refund address in case of failed send call.
                // @dev Since the Executor makes the return call, this contract is the refund address.
                payable(address(this))
            );

            emit ReturnRegisterRequest(label, owner, _origin.srcEid);
        } else if (_msgType == SEND) {
            // FIXME: Should I check something here?
            bytes32 labelhash = targetRegistry.labelHash(label);
            targetRegistry.setRecords(labelhash, texts, addrs, chash);
        }

        emit RegisterRequestReceived(label, owner, _origin.srcEid, _origin.sender);
    }

    function _isNameOwner(string memory label, address owner) internal view returns (bool) {
        return omniname.ownerOf(uint256(keccak256(abi.encodePacked(label)))) == owner;
    }

    function _isNameRegistered(string memory label) internal view returns (bool) {
        return bytes(targetRegistry.labelFor(keccak256(abi.encodePacked(label)))).length != 0;
    }

    receive() external payable {}
}
