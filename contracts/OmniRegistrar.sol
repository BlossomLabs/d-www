// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { OApp, MessagingFee, Origin, MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OmniName } from "./OmniName.sol";
import { Text, Addr } from "./L2Registrar.sol";
import { RegistrarBase } from "./RegistrarBase.sol";
/**
 * @title OmniRegistrar contract for registering omninames to an L2Registrar of another blockchain.
 * @notice THIS IS AN EXPERIMENTAL CONTRACT. DO NOT USE THIS CODE IN PRODUCTION.
 * @dev This contract showcases a PingPong style call (A -> B -> A) using LayerZero's OApp Standard.
 * This contract acts as A, being B the L2Registrar.
 */
contract OmniRegistrar is OApp, OAppOptionsType3, RegistrarBase {

    /// @notice Omnichian NFT that signals subname ownership.
    OmniName public immutable omniname;

    /// @notice Blockchain where the L2Registrar is
    uint32 public immutable dstEid;

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

    function quote(
        uint32 _dstEid,
        MessageParams calldata _message,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message._msgType, _message.label, _message.owner, _message.texts, _message.addrs, _message.chash);
        bytes memory options = combineOptions(_dstEid, SEND_ABA, _options);
        fee = _quote(_dstEid, payload, options, _payInLzToken);
    }

    function send(
        uint32 _dstEid,
        MessageParams memory _message,
        bytes calldata _options
    ) public payable returns (MessagingReceipt memory receipt) {
        bytes memory _payload = abi.encode(_message._msgType, _message.label, _message.owner, _message.texts, _message.addrs, _message.chash);
        bytes memory options = combineOptions(_dstEid, SEND_ABA, _options);
        receipt = _lzSend(_dstEid, _payload, options, MessagingFee(msg.value, 0), payable(msg.sender));
    }

    function register(string memory label, address owner, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public payable {
        send(dstEid, MessageParams(SEND_ABA, label, owner, texts, addrs, chash), msg.data[0:0]);
        emit RegisterRequestSent(label, owner, dstEid);
    }

    function updateRecords(string memory label, Text[] memory texts, Addr[] memory addrs, bytes memory chash) public payable {
        send(dstEid, MessageParams(SEND, label, address(0), texts, addrs, chash), msg.data[0:0]);
        emit UpdateRequestSent(label, msg.sender, dstEid);
    }

    function decodeMessage(bytes calldata encodedMessage) public pure returns (string memory label, address owner) {
        return abi.decode(encodedMessage, (string, address));
    }

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
        return keccak256(abi.encodePacked(label));
    }

    receive() external payable {}

}
