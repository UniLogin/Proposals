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
* **internal execution** - this revert happens when executing ERC1077 code. This is the most tricky part, as contract might want to do a number of preliminary checks that need to be updated
* **out of gas exception** - preventing this can be achieved by preminary checks of gas at the beginning of transaction. Another way to protect relayer, from out of gas exception, is to reduce gas for call by amount needed to refund: 
    ```
    function execute(...) {
        uint maxgas = min(gaslimit, gasToken.balanceOf(this)/gasPrice);
        to.call.gas(maxgas - 50000)(data);
        // Does not work for modules
        refund();
    }
    ``` 

* **not enough funds** - this happens when operation used more gas then the contract can pay for. This can be prevented by calculating max gas and the start of smart contract execution.

## Big Data attack
Big data attack happens when an attacker creates a message with a data field of significant size. The transaction is propagated by relayer but fails on preliminary checks (e.g. not enough gas to process transaction further) Relayer needs to pay for the whole transaction, but a refund will not happen. An attacker can drain relayer wallet that way. This can not be prevented in the general case.

Our proposal: 
```
 function execute(...) {
    require(msg.sender == allowedRelayer); 
 }
```
Only selected relayer is allowed to depute execution.


## Relayer network and refund guarantee
In general case, a refund cannot be guaranteed due to the front-running. At any point of time state of the contract (and blockchain can be changed) and therefore transaction that supposed to succeed will fail by the time it is being mined.
But if we limit allowed relayers to one (which could be the case for relayer network). Then as a first preliminary check, we can rule out the wrong relayer. Now relayer can run a simulated transaction and see if it succeeds and only then propagate it to the network.

## Proposed refund schema
We propose to split refund into two costs:
* `fixedGas` - decided by the user upfront, calculated by following formula:
  ```js
  fixedGas = transactionGasCost + nonMeasurableExecutionCost
  ```
  _transactionGasCost_ is calculated by sdk and checked by relayer.
  _nonMeasurableExecutionCost_ is a constant, more consideration on it you can find below in _Non Measurable Execution Cost_ section.
  In Gnosis Safe `fixedGas` parameter is called `dataGas`. Learn more about it in _Calculations of fixed gas_ section.
* `executionGasLimit` - dynamic gas cost, calculated from execution
In Gnosis Safe this parameter is called `safeTxGas`


## Not enough funds prevention
Max gas calculation allow to prevent 'Not enough funds' problem.
```
maxGasFrom = token.balanceOf(this)/gasPrice;
maxGas = min(executionGasLimit, maxGas);
```


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

## Calculations of fixed gas

### Transaction Gas Cost
* `transactionCost` - constant transaction cost
* `dataGas` - cost of transaction data. We can estimate it by fill `executeSigned` function with parameters (with fixedGas as 0) and then get data. Then we calculate 4 gas for every zero byte and 68 for every non-zero byte of data. After all we add 192 ( 64 * 3 - fixed gas can't be higher than 8 MLN (3 bytes)).


### Non Measurable Execution Cost
Non Measurable Execution Cost must include basic transaction cost and refund cost. Refund cost can be calculated assuming we are using standard ERC-20 token with reasonable implementation.
Below is a Gas used by refund function in different scenarios.

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


## Summary
Here is a short summary based on our research in context of our goals:
1. It seems to us it is impossible to return exact gas amount equal to the amount of gas of actual transaction, but we can do it with fair precisions of couple of thousands gas which we propose to settle in favor of relayer.
2. It seems to us that we can guarantee that refund will always happen, as long as there in no vulnerability in one of approved Modules.

## Acknowledgements
Special thanks to Gnosis Team, whom code we used to look for hints when we were running out of ideas :)


