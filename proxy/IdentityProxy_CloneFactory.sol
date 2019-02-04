pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./ENSRegistered.sol";
import "./ERC1077.sol";
import "./ERC725KeyHolder.sol";
import "./ENS/ENS.sol";
import "./ENS/FIFSRegistrar.sol";
import "./ENS/PublicResolver.sol";
import "./ENS/ReverseRegistrar.sol";
import "./KeyHolder.sol";
import "./IERC1077.sol";


contract InitializableENSRegistered {
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
    
    function init(bytes32 _hashLabel, string memory _name, bytes32 _node, ENS ens, FIFSRegistrar registrar, PublicResolver resolver) public {
        registrar.register(_hashLabel, address(this));
        ens.setResolver(_node, address(resolver));
        resolver.setAddr(_node, address(this));
        ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        reverseRegistrar.setName(_name);
    }
}

contract InitializableKeyHolder is ERC725KeyHolder {
    mapping (bytes32 => Key) public keys;
    mapping (uint256 => bytes32[]) keysByPurpose;

    function init(bytes32 _key) public {
        keys[_key].key = _key;
        keys[_key].purpose = MANAGEMENT_KEY;
        keys[_key].keyType = ECDSA_TYPE;

        keysByPurpose[MANAGEMENT_KEY].push(_key);

        emit KeyAdded(keys[_key].key,  keys[_key].purpose, keys[_key].keyType);
    }

    function() external {

    }

    modifier onlyManagementOrActionKeys(bytes32 sender) {
        bool isActionKey = keyHasPurpose(sender, ACTION_KEY);
        bool isManagementKey = keyHasPurpose(sender, MANAGEMENT_KEY);
        require(isActionKey || isManagementKey, "Invalid key");
        _;
    }

    modifier onlyManagementKeyOrThisContract() {
        bool isManagementKey = keyHasPurpose(bytes32(uint256(msg.sender)), MANAGEMENT_KEY);
        require(isManagementKey || msg.sender == address(this), "Sender not permissioned");
        _;
    }

    function keyExist(bytes32 _key) public view returns(bool) {
        return keys[_key].key != bytes32(0x0);
    }

    function getKey(bytes32 _key) public view returns(uint256 purpose, uint256 keyType, bytes32 key) {
        return (keys[_key].purpose, keys[_key].keyType, keys[_key].key);
    }

    function getKeyPurpose(bytes32 _key) public view returns(uint256 purpose) {
        return keys[_key].purpose;
    }

    function getKeysByPurpose(uint256 _purpose) public view returns(bytes32[] memory) {
        return keysByPurpose[_purpose];
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose) public view returns(bool result) {
        return keys[_key].purpose == _purpose;
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type) public onlyManagementKeyOrThisContract returns(bool success) {
        require(keys[_key].key != _key, "Key already added");

        keys[_key].key = _key;
        keys[_key].purpose = _purpose;
        keys[_key].keyType = _type;

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(keys[_key].key,  keys[_key].purpose, keys[_key].keyType);

        return true;
    }

    function addKeys(bytes32[] memory _keys, uint256[] memory _purposes, uint256[] memory _types) public onlyManagementKeyOrThisContract returns(bool success) {
        require(_keys.length == _purposes.length && _keys.length == _types.length, "Unequal argument set lengths");
        for (uint i = 0; i < _keys.length; i++) {
            addKey(_keys[i], _purposes[i], _types[i]);
        }
        emit MultipleKeysAdded(_keys.length);
        return true;
    }

    function removeKey(bytes32 _key, uint256 _purpose) public  onlyManagementKeyOrThisContract returns(bool success) {
        require(keys[_key].purpose != MANAGEMENT_KEY || keysByPurpose[MANAGEMENT_KEY].length > 1, "Can not remove management key");
        require(keys[_key].purpose == _purpose, "Invalid key");

        emit KeyRemoved(keys[_key].key, keys[_key].purpose, keys[_key].keyType);

        delete keys[_key];

        for (uint i = 0; i < keysByPurpose[_purpose].length; i++) {
            if (keysByPurpose[_purpose][i] == _key) {
                keysByPurpose[_purpose][i] = keysByPurpose[_purpose][keysByPurpose[_purpose].length - 1];
                delete keysByPurpose[_purpose][keysByPurpose[_purpose].length - 1];
                keysByPurpose[_purpose].length--;
            }
        }

        return true;
    }

    event MultipleKeysAdded(uint count);
}


contract InitializableERC1077 is InitializableKeyHolder, IERC1077 {
    using ECDSA for bytes32;
    using SafeMath for uint;

    uint _lastNonce;

    function init(bytes32 _key) public {
        InitializableKeyHolder(this).init(_key);
    }

    function lastNonce() public view returns (uint) {
        return _lastNonce;
    }

    function canExecute(
        address to,
        uint256 value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes memory signatures) public view returns (bool)
    {
        address signer = getSigner(
            address(this),
            to,
            value,
            data,
            nonce,
            gasPrice,
            gasToken,
            gasLimit,
            operationType,
            signatures);
        return keyExist(bytes32(uint256(signer)));
    }

    function calculateMessageHash(
        address from,
        address to,
        uint256 value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType) public pure returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                from,
                to,
                value,
                keccak256(data),
                nonce,
                gasPrice,
                gasToken,
                gasLimit,
                uint(operationType)
        ));
    }

    function getSigner(
        address from,
        address to,
        uint value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes memory signatures ) public pure returns (address)
    {
        return calculateMessageHash(
            from,
            to,
            value,
            data,
            nonce,
            gasPrice,
            gasToken,
            gasLimit,
            operationType).toEthSignedMessageHash().recover(signatures);
    }

    function executeSigned(
        address to,
        uint256 value,
        bytes memory data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes memory signatures) public returns (bytes32)
    {
        require(nonce == _lastNonce, "Invalid nonce");
        require(canExecute(to, value, data, nonce, gasPrice, gasToken, gasLimit, operationType, signatures), "Invalid signature");
        uint256 startingGas = gasleft();
        /* solium-disable-next-line security/no-call-value */
        (bool success, ) = to.call.value(value)(data);
        bytes32 messageHash = calculateMessageHash(address(this), to, value, data, nonce, gasPrice, gasToken, gasLimit, operationType);
        emit ExecutedSigned(messageHash, _lastNonce, success);
        _lastNonce++;
        uint256 gasUsed = startingGas.sub(gasleft());
        refund(gasUsed, gasPrice, gasToken);
        return messageHash;
    }

    function refund(uint256 gasUsed, uint gasPrice, address gasToken) private {
        if (gasToken != address(0)) {
            ERC20 token = ERC20(gasToken);
            token.transfer(msg.sender, gasUsed.mul(gasPrice));
        } else {
            msg.sender.transfer(gasUsed.mul(gasPrice));
        }
    }
}

contract InitializableIdentity is InitializableENSRegistered, InitializableERC1077 {
    function init(bytes32 _key, bytes32 _hashLabel, string memory _name, bytes32 _node, ENS ens, FIFSRegistrar registrar, PublicResolver resolver) 
    public payable {
        InitializableENSRegistered(this).init(_hashLabel, _name, _node, ens, registrar, resolver);
        InitializableERC1077(this).init(_key);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Optionality CloneFactory
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@optionality.io/clone-factory/contracts/CloneFactory.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract IdentityFactory is CloneFactory, Ownable { // Design decision: Ownable? Administrable? decentralization...

    address public libraryAddress;

    event IdentityCreated(address newIdentityAddress);

    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

    function setLibraryAddress(address _libraryAddress) public onlyOwner { // Design decision: Ownable? Administrable? decentralization...
        libraryAddress = _libraryAddress;
    }

    function createIdentity(
        bytes32 _key,
        bytes32 _hashLabel,
        string memory _name,
        bytes32 _node,
        ENS _ens,
        FIFSRegistrar _registrar,
        PublicResolver _resolver
    ) public {
        address clone = createClone(libraryAddress);
        InitializableIdentity(clone).init(_key, _hashLabel, _name, _node, _ens, _registrar, _resolver);
        emit IdentityCreated(clone);
    }
}
