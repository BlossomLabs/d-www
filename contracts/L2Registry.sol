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
    mapping(bytes32 labelhash => mapping(string key => string)) internal texts;
    /// @notice Mapping of address records for each name
    mapping(bytes32 labelhash => mapping(uint256 coinType => bytes)) internal addrs;
    /// @notice Mapping of content hashes for each name
    mapping(bytes32 labelhash => bytes) internal chashes;
    /// @notice Mapping of labels (names) for each labelhash
    mapping(bytes32 labelhash => string) internal labels;

    constructor() Ownable(msg.sender) {}

    /// @notice Registers a new name
    /// @param label The name to register
    /// @param owner The address that will own the name
    /// @dev Only callable by addresses with registrar role
    function register(
        string calldata label,
        address owner
    ) external onlyOwner {
        bytes32 _labelhash = labelHash(label);
        if (isRegistered(_labelhash)) {
            revert LabelAlreadyRegistered();
        }
        labels[_labelhash] = label;
        emit Registered(label, owner);
    }

    function isRegistered(bytes32 _labelhash) public view returns (bool) {
        return bytes(labels[_labelhash]).length != 0;
    }

    function labelHash(string memory label) public pure returns (bytes32 _labelhash) {
        _labelhash = keccak256(abi.encodePacked(label));
    }

    /*
     * Resolution Functions
     */
    /// @notice Gets the Ethereum address for a name
    /// @param _labelhash The hash of the name to resolve
    /// @return address The Ethereum address
    function addr(bytes32 _labelhash) public view returns (address) {
        return address(uint160(bytes20(addr(_labelhash, COIN_TYPE_ETH))));
    }

    /// @notice Gets the address for a specific coin type
    /// @param _labelhash The hash of the name to resolve
    /// @param _cointype The coin type to fetch the address for
    /// @return bytes The address for the specified coin
    function addr(
        bytes32 _labelhash,
        uint256 _cointype
    ) public view returns (bytes memory) {
        return addrs[_labelhash][_cointype];
    }

    /// @notice Gets a text record
    /// @param _labelhash The hash of the name
    /// @param _key The key of the text record
    /// @return string The value of the text record
    function text(
        bytes32 _labelhash,
        string calldata _key
    ) external view returns (string memory) {
        return texts[_labelhash][_key];
    }

    /// @notice Gets the content hash
    /// @param _labelhash The hash of the name
    /// @return bytes The content hash
    function contenthash(
        bytes32 _labelhash
    ) external view returns (bytes memory) {
        return chashes[_labelhash];
    }

    /// @notice Gets the label (name) for a labelhash
    /// @param _labelhash The hash to lookup
    /// @return string The original label
    function labelFor(bytes32 _labelhash) external view returns (string memory) {
        return labels[_labelhash];
    }

    /*
     * Record Management Functions
     */

    /// @notice Internal function to set address records
    /// @param _labelhash The name's hash
    /// @param _coinType The coin type to set address for
    /// @param _value The address value
    function _setAddr(
        bytes32 _labelhash,
        uint256 _coinType,
        bytes memory _value
    ) internal {
        addrs[_labelhash][_coinType] = _value;
        emit AddrChanged(_labelhash, _coinType, _value);
    }

    /// @notice Internal function to set text records
    /// @param _labelhash The name's hash
    /// @param _key The record key
    /// @param _value The record value
    function _setText(
        bytes32 _labelhash,
        string memory _key,
        string memory _value
    ) internal {
        texts[_labelhash][_key] = _value;
        emit TextChanged(_labelhash, _key, _value);
    }

    /// @notice Internal function to set content hash
    /// @param _labelhash The name's hash
    /// @param _value The content hash value
    function _setContenthash(bytes32 _labelhash, bytes memory _value) internal {
        chashes[_labelhash] = _value;
        emit ContenthashChanged(_labelhash, _value);
    }

    /// @notice Public function to set address records with access control
    /// @param _labelhash The name's hash
    /// @param _coinType The coin type to set address for
    /// @param _value The address value
    function setAddr(
        bytes32 _labelhash,
        uint256 _coinType,
        bytes memory _value
    ) public onlyOwner {
        _setAddr(_labelhash, _coinType, _value);
    }

    /// @notice Public function to set text records with access control
    /// @param _labelhash The name's hash
    /// @param _key The record key
    /// @param _value The record value
    function setText(
        bytes32 _labelhash,
        string memory _key,
        string memory _value
    ) public onlyOwner {
        _setText(_labelhash, _key, _value);
    }

    /// @notice Public function to set content hash with access control
    /// @param _labelhash The name's hash
    /// @param _value The content hash value
    function setContenthash(
        bytes32 _labelhash,
        bytes memory _value
    ) public onlyOwner {
        _setContenthash(_labelhash, _value);
    }

    /// @notice Batch sets multiple records in one transaction
    /// @param _labelhash The name's hash
    /// @param _texts Array of text records to set
    /// @param _addrs Array of address records to set
    /// @param _chash Content hash to set (optional)
    function setRecords(
        bytes32 _labelhash,
        Text[] calldata _texts,
        Addr[] calldata _addrs,
        bytes calldata _chash
    ) external onlyOwner {
        uint256 i;

        for (i = 0; i < _texts.length; i++) {
            _setText(_labelhash, _texts[i].key, _texts[i].value);
        }

        for (i = 0; i < _addrs.length; i++) {
            _setAddr(_labelhash, _addrs[i].coinType, _addrs[i].value);
        }

        if (_chash.length > 0) {
            _setContenthash(_labelhash, _chash);
        }
    }
}
