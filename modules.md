# Proposal for modules

## IERC1077 interface
```
contract IERC1077 {
    enum OperationType {CALL, DELEGATECALL, CREATE}

    event ExecutedSigned(bytes32 indexed messageHash, uint indexed nonce, bool indexed success);

    function lastNonce() public view returns (uint nonce);

    function canExecute(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes signatures) public view returns (bool);

    function executeSigned(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes signatures) public returns (bytes32);

    function addModule(address moduleAddress, bytes data) internal;

    function removeModule(address moduleAddress) internal;
}
```

## Module interface

## Example module: Universal Login

ERC1078 Universal Login Key Holder schema
```
contract IERC1078 {
    enum KeyType {
        MANAGEMENT, ACTION
    }

    function addKey(address key, KeyType keyType) public;

    function removeKey(address key, KeyType keyType) public;

    function canExecute(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        IERC1077.OperationType operationType,
        bytes signatures) public view returns (bool);
}
```

## Example module: RelayerNetwork

## Example module: RecurringPayment