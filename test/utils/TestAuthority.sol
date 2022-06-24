// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { Authority } from "../../src/dependencies/solmate/Auth.sol";
import { Constants } from "../../src/libraries/Constants.sol";

contract TestAuthority is RolesAuthority {
    constructor(address owner) RolesAuthority(owner, Authority(address(0))) {
        // TODO: set default capability and user role here maybe
    }
}
