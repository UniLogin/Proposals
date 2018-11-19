# Proposal for modules

## IERC1077 interface
```
contract IERC1077 {
    enum OperationType {CALL, DELEGATECALL, CREATE}

    event ExecutedSigned(bytes32 indexed messageHash, uint indexed nonce, bool indexed success);

    function lastNonce() public view returns (uint nonce);

    function execute(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes signatures) public returns (bytes32);

    function moduleExecute(
        address to,
        uint256 value,
        bytes data) onlyModule returns (bytes32);

    function addModule(Module module, bytes data) internal;

    function removeModule(Module module) internal;
}
```

## Module interface
Proposed module semantics is the following:
`canExecute` can return true, false or throw.
At least one module need to return true for the transaction to pass. Therefore false means the current module is not interested. If reverts than it the whole transaction will revert.

We present two alternative solutions at the bottom of the document.
```
contract Module {
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

## Examples

We would like to test our ideas against as many example modules as possible. Some ideas that we noticed so far are:

- Universal login
- Relayer network
- Recurring payments
- Gifts
- Daily limits
- Batch execution

## Example module: Universal Login

ERC1078 Universal Login Key Holder schema
```
contract IERC1078 {
    enum KeyType {
        MANAGEMENT, ACTION
    }

    struct Key {
        KeyType keyType;
        address key;
    }

    mapping (address => Key) keys;

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
        bytes signatures) public view returns (bool) {
            const address key = ...;
            if (this.keys[key] == key) {
                return true;
            }
            revert('Unauthorised key');
    }
}
```

### Example module: RelayerNetwork
```
contract RelayerNetwork {

    function currentRelyerAddress() view returns (address) {
        ...
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
            if (this.currentRelyerAddress() == msg.origin) {
                return true;
            }
        revert('Unauthorised relayer');
    }
}
```

### Example module: RecurringPayment

```
contract RecurringPayment {
    IERC1077 owner;

    constructor(IERC1077 owner) {
        this.owner = owner;
    }

    function withdrawl() {
        if (this.isSubscribed(msg.sender)) {
            this.owner.moduleExecute(...);
        }
    }

    function subscribe(uint amount, uint period, address beneficient) onlyOwner {
        ...
    }

    function cancel(address beneficient) onlyOwner {
        ...
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
            //Ignore
            return false;
        }
    }
}
```

### Example module: Batch transactions
```
contract BatchTransactions {
    constructor(IERC1077 owner) {
        this.owner = owner;
    }

    function executeBatch(address [] to,
        uint256 [] value,
        bytes [] data,
        uint [] nonce,
        uint [] gasPrice,
        address [] gasToken,
        uint [] gasLimit,
        IERC1077.OperationType [] operationType,
        bytes signatures) {
            for (uint  i = 0; i < value.length; i++) {
                owner.executeModule(...);
            }
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
            //Ignore
            return false;
        }
    }
}
```

## Security note
Modules are extremely vulnerable from a security perspective and therefore should be used with caution. We would expect that user rarely adds/remove modules and that only well audited/formally verified modules are available to use on mainnet.

## Three possible semantics

### True-false-revert
This is the current proposal. It assumes that each module can return true or false or it can revert. Above examples are written using following semantics.
![True-false-revert](/out/modules/proposal-chain.png)

### True-false and composite
This is an alternate proposal. It assumes that each module can return true or false, but modules can be combined using the composite design pattern. Our current view is that this solution is unnecessarily complicated.
![True-false-revert](/out/modules/proposal-composite.png)


### Filters and modules
This is an alternate proposal. It assumes that each module can return true or false. It has two types of modules: filters and standard modules. The filter can only reject a transaction. While the standard module can only approve the transaction.
![True-false-revert](/out/modules/proposal-two-types.png)

