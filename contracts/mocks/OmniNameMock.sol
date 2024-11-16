// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OmniName } from "../OmniName.sol";

// @dev WARNING: This is for testing purposes only
contract OmniNameMock is OmniName {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OmniName(_name, _symbol, _lzEndpoint, _delegate) {}

    function mint(address _to, uint256 _amount) override public {
        _mint(_to, _amount);
    }
}
