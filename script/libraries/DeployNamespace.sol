// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import "forge-std/console.sol";
import "forge-std/Vm.sol";
import "./LibDeploy.sol";

library DeployNamespace {
    struct DeployNamespaceParams {
        address engineProxy;
        address namespaceOwner;
        string name;
        string symbol;
        address profileFac;
        address subFac;
        address essFac;
    }

    function deployNamespace(Vm vm, DeployNamespaceParams memory params)
        internal
        returns (address)
    {
        bytes32 salt = keccak256(bytes(params.name));
        (address profile, , ) = LibDeploy.createNamespace(
            params.engineProxy,
            params.namespaceOwner,
            params.name,
            params.symbol,
            salt,
            params.profileFac,
            params.subFac,
            params.essFac
        );
        LibDeploy._write(
            vm,
            string(abi.encodePacked(params.name, " profile")),
            profile
        );
        return profile;
    }
}
