# Authorisation


Multisig authorisation contract that is a module to a wallet contract.


Interface:

```
contract IAuthorisation is Module {
  function canExecute(
    address to,
    uint256 value,
    bytes data,
    uint nonce,
    uint gasPrice,
    address gasToken,
    uint gasLimit,
    IERC1077.OperationType operationType,
    bytes signatures) public view returns (bool) {
  }

  addKeys(address key) {

  }
}
```