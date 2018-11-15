data = subscriptionModule.createSubscription(...).encode();

identity.executeSigned(
    subscriptionModule.address,
    0,
    data,
    nonce,
    gasPrice,
    gasToken,
    gasLimit,
    DELEGATE_CALL,
    extraData,
    signatures);

data = subscriptionModule.createSubscription(...).encode();
sdk.execute({
    module: subscriptionModule.address,
    data
}, privateKey);

sdk.modules.subscriptions.createSubscription();
