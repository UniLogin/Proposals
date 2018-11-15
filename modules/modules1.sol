contract IERC1077 {
    enum OperationType {CALL, DELEGATECALL, CREATE}

    event ExecutedSigned(bytes32 executionId, address from, uint nonce, bool success);

    function lastNonce() public view returns (uint nonce);

    address [] modules;

    function canExecute(
        address to,
        uint256 value,
        bytes data,
        uint nonce,
        uint gasPrice,
        address gasToken,
        uint gasLimit,
        OperationType operationType,
        bytes extraData,
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
        bytes extraData,
        bytes signatures) public returns (bytes32);

    function addModule(address anAddress, bytes data) internal {
        modules.push(anAddress);
    }

    function removeModule(address anAddress) internal {
        modules.push(anAddress);
    }
}

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
        bytes extraData,
        bytes signatures) public view returns (bool);
}

contract RelayerNetwork {
    address [] relayers;

    function isCurrentRelayerOk(address) public view returns (bool) {

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
    bytes extraData,
    bytes signatures) public view returns (bool) {
        return isCurrentRelayerOk(msg.sender);
    }
}

contract RecurringPayment {

    Subscription [] subscriptions;

    struct Subscription {
        uint amount;
        address to;
    }

    constructor() {
        throw;
    }

    function startSubscription(uint amount, uint timePeriod, address to, address token) internal  {

    }

    function withdrawl(uint subsriptionId, address forwardTo) {
        require(msg.sender == subscriptions[subsriptionId].to);
        forwardTo.transfer(subscriptions[subsriptionId].amount);
    }

    function stopSubsription(bytes32 subsriptionId) internal {

    }
}