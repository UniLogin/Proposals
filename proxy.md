Evaluation of different Proxy alternatives for Universal Login Identity and Module contracts:

* [Zeppelin OS](https://github.com/zeppelinos/zos)
* [Optionality clone-factory](https://github.com/optionality/clone-factory)
* [Gnosis Safe](https://github.com/gnosis/safe-contracts)

Goals:

* decrease the deployment gas cost to minimum
* allow for upgradeable implementations

## Zeppelin OS (ZOS) Proxy

The following requirements shall be met by the target contract:

* it shall have default empty constructor
* it shall extend ZOS Initializable implementing one initialization function having initializer modifier

Then an instance of ZOS UpgradeabilityProxy/AdminUpgradeabilityProxy for each proxy contract shall be used or
a customized IdentityUpgradeabilityProxy extending the ZOS ones if custom administration logic is expected

* PROS: large community and maintenance guarantees
* CONS: first administrator is Proxy deployer, i.e. Relayer in UL, not feasible as it is for UL

## Clone Factory

The following requirements shall be met by the target contract:

* create a specific contract factory extending CloneFactory containing support for upgradability
* remember to call the specific initialization function

* PROS: vanity addresses for event cheaper clone contracts
* CONS: project without big support, initialization function is NOT enforced by any interface/modifier

## Gnosis Safe

The following requirements shall be met by the target contract:

* it shall extend the MasterCopy contract as first base contract

* PROS: solid community, administrator is Proxy contract itself, fit perfectly with UL
* CONS: -

From the UL perspective the most promising solution is the Proxy implementation of Gnosis Safe.