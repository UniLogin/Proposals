# Proposal refund
The following document is a proposal how to structure refund for ERC #1077 message execution.

## Refund goals
The aim of refund is for the #1077 smart contract to get the return of the cost of transaction execution to the relayer.

In particular, we want to:
1. The amount return in gas to be equal to the amount of gas of actual transaction.
If it is impossible then at least we want to be as close as possible.
2. Guarantee refund will always happen.
If it is impossible, we would like to minimize the cost of the reverted transaction and also reduce the risk of revert.

## Gas price and gas token
The refund should be simply executed as a transfer of funds is given `gas token` (ether if token address equals `0x`). Cost of execution is calculated from `gas used` and `gas price`:
`execution cost = gas price * gas used`

## Signed message to a transaction
Relayer simply translates gas price and gas token according to his own pricing strategy to a transaction with gas price in ethereum.

### Considerations
How to prevent the user from accidentally put too high of a gas price is an open matter.


## Components of execution cost

We can split Gas used into the following components:

* _Transaction gas cost_ - which is basic transaction gas cost plus the cost of transaction data.
Basic transaction cost is 21000 gas and transaction data is charged 4 gas for every zero byte of data and 68 for every non-zero byte of data.

* _Execution gas cost_ - which is the cost of execution of the smart contract.
Execution gas cost can be split into two subparts:
    * _Measurable execution cost_ - the part that we can measure by simply substrating `gas left` at the beginning of execution and `gas left` at the end of execution
    * _Non-measurable execution cost_ - all that remains in execution cost, that includes the calculation itself and refund

## Possible revert reasons
Possible reasons for revert are:
* _revert in the external execution_ (internal transaction) - this is not a problem, as the semantics of `call` guarantees that the call will return regardless of revert
* _revert in internal execution_ - unintentional reverts can be achieved by writing a bugless smart contract. Intentionally we want to revert as soon as possible to reduce the cost of execution
* out of gas exception - this can be  achieved by a combination of the two:
    * checking the amount of gas at the beginning and
    * limiting the amount of gas passed to the call
Together it should make sure there is enough gas to finish execution
* not enough funds - can be prevented by calculating max gas and the start of smart contract execution

TODO: Note on nonce and modules

## Proposed refund schema
We propose to split refund into two costs:
* `fixedGas` - decided by the user upfront, calculated by following formula:
  ```js
  fixedGas = transactionGasCost + nonMeasurableExecutionCost
  ```
  _transactionGasCost_ is calculated by sdk and checked by relayer.
  _nonMeasurableExecutionCost_ is a constant, more consideration on it you can find below in _Non Measurable Execution Cost_ section
  In Gnosis Safe this parameter is called `dataGas`.
* `executionGasLimit` - dynamic gas cost, calculated from execution
In Gnosis Safe this parameter is called `safeGas`

TODO: Finish

TODO: Max gas calculation

TODO: Add picture

### Relayer checks
* check if `dataGas` is ok
* run estimation and check if there is enough funds
TODO: Finish

### Smart contracts checks
* Check for minimal amount of tokens
* Check the amount of token on the smart contract to do minimal execution
* Limit amout of gas passed to external call
    * Calculate call.gas() gasleft

TODO: Finish

### Non Measurable Execution Cost
Non Measurable Execution Cost must include basic transaction cost and refund cost. Refund cost can be calculated assuming we are using standard ERC-20 token with reasonable implementation.

TODO: Copy-paste our findings

TODO: Fix grammar and typos

## Known security vulnerabilities
TODO: Front running with modules vulnerabilities.

## Summary
Here is a short summary based on our research in context of our goals:
1. It seems to us it is impossible to return exact gas amount equal to the amount of gas of actual transaction, but we can do it with fair precisions of couple of thousands gas which we propose to settle in favor of relayer.
2. It seems to us that we can guarantee that refund will always happen, as long as there in no vulnerability in one of approved Modules.

## Acknowledgements
Special thanks to Gnosis Team, whom code we used to look for hints when we were running out of ideas :)