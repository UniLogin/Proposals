pragma solidity ^0.5.0;

import "./Identity.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gnosis Safe
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "gnosis-safe/contracts/common/MasterCopy.sol";
import "gnosis-safe/contracts/proxies/ProxyFactory.sol";

contract ERC1077MasterCopy is MasterCopy, ERC1077 {
}

contract IdentityMasterCopy is MasterCopy, Identity {
}

// Then we could use ProxyFactory to create the Proxy instance and execute a message call to it within one transaction