// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import { Text, Addr } from "./L2Registry.sol";

contract RegistrarBase {

    struct MessageParams {
        uint16 _msgType;
        string label;
        address owner;
        Text[] texts;
        Addr[] addrs;
        bytes chash;
    }


    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3.
    uint16 public constant SEND = 1;
    uint16 public constant SEND_ABA = 2;
}
