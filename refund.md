# Proposal refund
The following document is a proposal how to structure refund for ERC #1077 message execution.

## Refund goals
The aim of refund is for the #1077 smart contract to get the return of the cost of transaction execution to the relayer.

In particular, we want to:
1. The amount return in gas to be as close as possible to the actual gas used.
2. Guarantee refund will always happen.

## Gas price and gas token
The refund should be simply executed as a transfer of funds is given `gas token` (ether if token address equals `0x`). Cost of execution is calculated from `gas used` and `gas price`:
`execution cost = gas price * gas used`

## Converting signed message to a transaction
Relayer simply translates `gas price` and `gas token` according to his own pricing strategy to a transaction with `gas price` in Ethereum.

### Consideration: too high of a gas price
How to prevent the user from accidentally put too high of a gas price is an open problem.

## Components of execution cost
We can split Gas used into the following components:

* _Transaction gas cost_ - which is sum of basic transaction gas cost plus the cost of transaction data.
    * Basic transaction cost is 21000 gas
    * Transaction data is charged:
        * 4 gas for every zero byte of data
        * 68 for every non-zero byte of data.

* _Execution gas cost_ - which is the cost of execution of the smart contract.
Execution gas cost can be split into two subparts:
    * _Measurable execution cost_ - the part that we can measure by simply substrating `gas left` at the beginning of execution and `gas left` at the end of execution
    * _Non-measurable execution cost_ - all that remains in execution cost, that includes the calculation itself and refund

    ![_Execution gas cost](/images/execute.png)

## Possible revert reasons
As we want to guarantee a refund will always happen, let's iterate over possible reasons for revert that might prevent it:
* **external execution** - this is revert happening in external to our smart contract execution - when doing an external call (that will be stored as an internal transaction in the blockchain history). The semantics of `call` guarantees that the call will return regardless of revert, so this case is covered.
* **internal execution** - this revert happens when executing ERC1077 code. Preventing unintentional reverts can be achieved by writing a bugless smart contract.
If the smart contract wants to revert intentionally (due to one of the rules broken) we want to at least revert as soon as possible to reduce the cost of execution.


* **out of gas exception** - preventing this can be  achieved by a combination of the two:
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
  _nonMeasurableExecutionCost_ is a constant, more consideration on it you can find below in _Non Measurable Execution Cost_ section.
  In Gnosis Safe `fixedGas` parameter is called `dataGas`.
* `executionGasLimit` - dynamic gas cost, calculated from execution
In Gnosis Safe this parameter is called `safeTxGas`

TODO: Finish

Max gas calculation
```
maxGasFrom = token.balanceOf(this)/gasPrice;
maxGas = min(executionGasLimit, maxGas);
```

TODO: Add picture

### Relayer checks
* check if `dataGas` is ok
* check if `executionGas` is ok (enough to verify signatures and do refund)
* check if signatures are ok
* token is whitelisted
* run estimation 
    * check if execution is succesful
    * and check if there is enough funds 
TODO: Finish

### Smart contracts checks
* Check signatures
* Check for minimal amount of tokens
* Check the amount of token on the smart contract to do minimal execution
* Limit amout of gas passed to external call
    * Calculate call.gas() gasleft

TODO: Finish

### Non Measurable Execution Cost
Non Measurable Execution Cost must include basic transaction cost and refund cost. Refund cost can be calculated assuming we are using standard ERC-20 token with reasonable implementation.

TODO: Copy-paste our findings

		

### Gas used by refund function

#### Refund in token

Refund cost depends on balance of sender and receiver. The most expensive option is, when sender sends all funds (ends with zero) to receiver, whos balance is zero. 

|	| To non-zero | To zero |
| :---: | :---: | :---: |
| From non-zero |	38911 |	53911 |
| From zero | 24103 | 39103 |
		
#### Refund in ether	
Cases, when we clean out account, are highly unlinkely.

|	| To non-zero | To zero |
| --- | :---: | :---: |
| From non-zero |	29950 |	- |
| From zero | - | - |
		

TODO: Fix grammar and typos

## Known security vulnerabilities
A malicious actor can create a two transactions with the same nonce and propagte them into the network. Only one transaction will be successful while the other one will revert. Cost f
Furthermore attacker might elevalte cost of transaction by passing a lot of data. That can be prevented in case of centralized relayer, but is hard to implement in distributed environment.

## Summary
Here is a short summary based on our research in context of our goals:
1. It seems to us it is impossible to return exact gas amount equal to the amount of gas of actual transaction, but we can do it with fair precisions of couple of thousands gas which we propose to settle in favor of relayer.
2. It seems to us that we can guarantee that refund will always happen, as long as there in no vulnerability in one of approved Modules.

## Acknowledgements
Special thanks to Gnosis Team, whom code we used to look for hints when we were running out of ideas :)