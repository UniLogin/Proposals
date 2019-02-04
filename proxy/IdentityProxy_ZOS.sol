pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zos-lib/contracts/Initializable.sol";
import "./ENSRegistered.sol";
import "./ERC1077.sol";
import "./ERC725KeyHolder.sol";
import "./ENS/ENS.sol";
import "./ENS/FIFSRegistrar.sol";
import "./ENS/PublicResolver.sol";
import "./ENS/ReverseRegistrar.sol";
import "./KeyHolder.sol";
import "./IERC1077.sol";


contract InitializableENSRegistered is Initializable {
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
    
    function initialize(bytes32 _hashLabel, string memory _name, bytes32 _node, ENS ens, FIFSRegistrar registrar, PublicResolver resolver) public initializer {
        registrar.register(_hashLabel, address(this));
        ens.setResolver(_node, address(resolver));
        resolver.setAddr(_node, address(this));
        ReverseRegistrar reverseRegistrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
        reverseRegistrar.setName(_name);
    }
}

contract InitializableKeyHolder is ERC725KeyHolder, Initializable {
    mapping (bytes32 => Key) public keys;
    mapping (uint256 => bytes32[]) keysByPurpose;

    function initialize(bytes32 _key) public initializer {
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

    function initialize(bytes32 _key) public initializer {
        InitializableKeyHolder(this).initialize(_key);
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

contract InitializableIdentity is Initializable, InitializableENSRegistered, InitializableERC1077 {
    function initialize(bytes32 _key, bytes32 _hashLabel, string memory _name, bytes32 _node, ENS ens, FIFSRegistrar registrar, PublicResolver resolver) 
    public payable initializer {
        InitializableENSRegistered(this).initialize(_hashLabel, _name, _node, ens, registrar, resolver);
        InitializableERC1077(this).initialize(_key);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Zeppelin OS
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "zos-lib/contracts/upgradeability/AdminUpgradeabilityProxy.sol";

// We could use AdminUpgradeabilityProxy directly without inheritance but... is customized administration required?
contract IdentityUpgradeabilityProxy is AdminUpgradeabilityProxy {

    constructor(address _implementation, bytes memory _data) AdminUpgradeabilityProxy(_implementation, _data)
    public payable {
    }
}
