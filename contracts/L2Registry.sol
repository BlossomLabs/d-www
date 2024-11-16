// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Structure for text record updates
/// @dev Used to prevent stack too deep errors in multicall functions
struct Text {
    string key;
    string value;
}

/// @notice Structure for address record updates
/// @dev Used to prevent stack too deep errors in multicall functions
struct Addr {
    uint256 coinType;
    bytes value;
}

contract L2Registry is Ownable {

    /// @notice Thrown when a label is already registered
    error LabelAlreadyRegistered();

    /// @notice Emitted when a new name is registered
    event Registered(string label, address owner);
    /// @notice Emitted when a text record is changed
    event TextChanged(bytes32 indexed labelhash, string key, string value);
    /// @notice Emitted when an address record is changed
    event AddrChanged(bytes32 indexed labelhash, uint256 coinType, bytes value);
    /// @notice Emitted when a content hash is changed
    event ContenthashChanged(bytes32 indexed labelhash, bytes value);

    /*
     * Constants
     */
    /// @notice Ethereum coin type as per SLIP-0044
    uint256 constant COIN_TYPE_ETH = 60;

    /*
     * Properties
     */
    /// @notice Mapping of text records for each name
    mapping(bytes32 labelhash => mapping(string key => string)) _texts;
    /// @notice Mapping of address records for each name
    mapping(bytes32 labelhash => mapping(uint256 coinType => bytes)) _addrs;
    /// @notice Mapping of content hashes for each name
    mapping(bytes32 labelhash => bytes) _chashes;
    /// @notice Mapping of labels (names) for each labelhash
    mapping(bytes32 labelhash => string) _labels;

    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new name
    /// @param label The name to register
    /// @param owner The address that will own the name
    /// @dev Only callable by addresses with registrar role
    function register(
        string calldata label,
        address owner
    ) external onlyOwner {
        bytes32 labelhash = keccak256(abi.encodePacked(label));
        if (bytes(_labels[labelhash]).length != 0) {
            revert LabelAlreadyRegistered();
        }
        _labels[labelhash] = label;
        emit Registered(label, owner);
    }

    /*
     * Resolution Functions
     */
    /// @notice Gets the Ethereum address for a name
    /// @param labelhash The hash of the name to resolve
    /// @return address The Ethereum address
    function addr(bytes32 labelhash) public view returns (address) {
        return address(uint160(bytes20(addr(labelhash, COIN_TYPE_ETH))));
    }

    /// @notice Gets the address for a specific coin type
    /// @param labelhash The hash of the name to resolve
    /// @param cointype The coin type to fetch the address for
    /// @return bytes The address for the specified coin
    function addr(
        bytes32 labelhash,
        uint256 cointype
    ) public view returns (bytes memory) {
        return _addrs[labelhash][cointype];
    }

    /// @notice Gets a text record
    /// @param labelhash The hash of the name
    /// @param key The key of the text record
    /// @return string The value of the text record
    function text(
        bytes32 labelhash,
        string calldata key
    ) external view returns (string memory) {
        return _texts[labelhash][key];
    }

    /// @notice Gets the content hash
    /// @param labelhash The hash of the name
    /// @return bytes The content hash
    function contenthash(
        bytes32 labelhash
    ) external view returns (bytes memory) {
        return _chashes[labelhash];
    }

    /// @notice Gets the label (name) for a labelhash
    /// @param labelhash The hash to lookup
    /// @return string The original label
    function labelFor(bytes32 labelhash) external view returns (string memory) {
        return _labels[labelhash];
    }

    /*
     * Record Management Functions
     */

    /// @notice Internal function to set address records
    /// @param labelhash The name's hash
    /// @param coinType The coin type to set address for
    /// @param value The address value
    function _setAddr(
        bytes32 labelhash,
        uint256 coinType,
        bytes memory value
    ) internal {
        _addrs[labelhash][coinType] = value;
        emit AddrChanged(labelhash, coinType, value);
    }

    /// @notice Internal function to set text records
    /// @param labelhash The name's hash
    /// @param key The record key
    /// @param value The record value
    function _setText(
        bytes32 labelhash,
        string memory key,
        string memory value
    ) internal {
        _texts[labelhash][key] = value;
        emit TextChanged(labelhash, key, value);
    }

    /// @notice Internal function to set content hash
    /// @param labelhash The name's hash
    /// @param value The content hash value
    function _setContenthash(bytes32 labelhash, bytes memory value) internal {
        _chashes[labelhash] = value;
        emit ContenthashChanged(labelhash, value);
    }

    /// @notice Public function to set address records with access control
    /// @param labelhash The name's hash
    /// @param coinType The coin type to set address for
    /// @param value The address value
    function setAddr(
        bytes32 labelhash,
        uint256 coinType,
        bytes memory value
    ) public onlyOwner {
        _setAddr(labelhash, coinType, value);
    }

    /// @notice Public function to set text records with access control
    /// @param labelhash The name's hash
    /// @param key The record key
    /// @param value The record value
    function setText(
        bytes32 labelhash,
        string memory key,
        string memory value
    ) public onlyOwner {
        _setText(labelhash, key, value);
    }

    /// @notice Public function to set content hash with access control
    /// @param labelhash The name's hash
    /// @param value The content hash value
    function setContenthash(
        bytes32 labelhash,
        bytes memory value
    ) public onlyOwner {
        _setContenthash(labelhash, value);
    }

    /// @notice Batch sets multiple records in one transaction
    /// @param labelhash The name's hash
    /// @param texts Array of text records to set
    /// @param addrs Array of address records to set
    /// @param chash Content hash to set (optional)
    function setRecords(
        bytes32 labelhash,
        Text[] calldata texts,
        Addr[] calldata addrs,
        bytes calldata chash
    ) external onlyOwner {
        uint256 i;

        for (i = 0; i < texts.length; i++) {
            _setText(labelhash, texts[i].key, texts[i].value);
        }

        for (i = 0; i < addrs.length; i++) {
            _setAddr(labelhash, addrs[i].coinType, addrs[i].value);
        }

        if (chash.length > 0) {
            _setContenthash(labelhash, chash);
        }
    }
}
