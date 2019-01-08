# Authorisation
Multisig authorisation contract that is a module to a wallet contract.

Interface:
```js
contract IAuthorisation is Module {
  enum KeyType {CONFIRMATION, APPLICATION};

  uint selfConfirmations = 0;
  uint externalConfirmations = 0;

  struct Key {
    KeyType keyType;
    address key;
  }

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

  setSelfConfirmations() {

  }

  setExternalConfirmations() {

  }

  addKeys(address key, KeyType keyType) {

  }

  removeKey(address key) {

  }
}
```

Notes:
* Confirmations - add/remove modules, add/remove keys:
```
(to == walletContract || to == authorisationContract)
```
* Application and Confirmation - do external transaction (any other values of `to`)

