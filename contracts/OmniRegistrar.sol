// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OmniName } from "./OmniName.sol";
import { Text, Addr } from "./L2Registrar.sol";

/**
 * @title OmniRegistrar contract for registering omninames to an L2Registrar of another blockchain.
 * @notice THIS IS AN EXPERIMENTAL CONTRACT. DO NOT USE THIS CODE IN PRODUCTION.
 * @dev This contract showcases a PingPong style call (A -> B -> A) using LayerZero's OApp Standard.
 * This contract acts as A, being B the L2Registrar.
 */
contract OmniRegistrar is OApp, OAppOptionsType3 {

    /// @notice Omnichian NFT that signals subname ownership.
    OmniName public immutable omniname;

    /// @notice Blockchain where the L2Registrar is
    uint32 public immutable dstEid;

    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3.
    uint16 public constant SEND = 1;
    uint16 public constant SEND_ABA = 2;

    event RegisterRequestSent(string label, address owner, uint32 dstEid);
    event UpdateRequestSent(string label, address owner, uint32 dstEid);

    /// @dev Revert with this error when the sender is not the owner of the NFT.
    error NotOwner();

    /**
     * @dev Constructs a new L2Registrar contract instance.
     * @param _omniname The OmniName contract instance.
     * @param _dstEid Blockchain where the L2Registry is.
     */
    constructor(OmniName _omniname, uint32 _dstEid) OApp(address(_omniname.endpoint()), _omniname.owner()) Ownable(_omniname.owner()) {
        omniname = _omniname;
        dstEid = _dstEid;
    }

    function encodeRegisterMessage(string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public pure returns (bytes memory, uint16) {
        return (abi.encode(SEND_ABA, label, owner, texts, addrs, chash), SEND_ABA);
    }

    function encodeUpdateRecordsMessage(string memory label, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public pure returns (bytes memory, uint16) {
        return (abi.encode(SEND, label, address(0), texts, addrs, chash), SEND_ABA);
    }

    /**
     * @notice Returns the estimated messaging fee for a given message.
     * @param _msgType The type of message being sent.
     * @param _payload The message encoded with `encodeRegisterMessage` or 
     * @param _payInLzToken Boolean flag indicating whether to pay in LZ token.
     * @return fee The estimated messaging fee.
     */
    function quote(
        uint16 _msgType,
        bytes memory _payload,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory options = combineOptions(dstEid, _msgType, msg.data[0:0]);
        fee = _quote(dstEid, _payload, options, _payInLzToken);
    }

    function register(string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public payable {
        (bytes memory payload, uint16 msgType) = encodeRegisterMessage(label, owner, texts, addrs, chash); 
        bytes memory options = combineOptions(dstEid, msgType, msg.data[0:0]);

        _lzSend(
            dstEid,
            payload,
            options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender)
        );

        emit RegisterRequestSent(label, owner, dstEid);
    }

    function updateRecords(string memory label, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public payable {
        if (omniname.ownerOf(uint256(labelHash(label))) != msg.sender) {
            revert NotOwner();
        }

        (bytes memory payload, uint16 msgType) = encodeUpdateRecordsMessage(label, texts, addrs, chash); 
        bytes memory options = combineOptions(dstEid, msgType, msg.data[0:0]);

        _lzSend(
            dstEid,
            payload,
            options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender)
        );

        emit UpdateRequestSent(label, msg.sender, dstEid);
    }

    function decodeMessage(bytes calldata encodedMessage) public pure returns (string memory label, address owner) {
        return abi.decode(encodedMessage, (string, address));
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
        if (_origin.srcEid == dstEid) {
            (string memory label, address owner) = decodeMessage(message);
            bytes32 labelhash = labelHash(label);
            omniname.mint(owner, uint256(labelhash));
        }
    }

    function labelHash(string memory label) public pure returns (bytes32) {
        return keccak256(abi.encode(label));
    }

    receive() external payable {}

}
