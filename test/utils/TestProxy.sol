// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

import { ISubscribeNFT } from "../../src/interfaces/ISubscribeNFT.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { Constants } from "../../src/libraries/Constants.sol";

import { LibDeploy } from "../../script/libraries/LibDeploy.sol";

contract TestProxy {
    function getDeployedProxyAddress(
        address subscribeBeacon,
        uint256 profileId,
        address profile,
        string memory handle
    ) internal pure returns (address) {
        string memory name = string(
            abi.encodePacked(handle, Constants._SUBSCRIBE_NFT_NAME_SUFFIX)
        );
        string memory symbol = string(
            abi.encodePacked(
                LibString.toUpper(handle),
                Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
            )
        );
        return
            LibDeploy._computeAddress(
                abi.encodePacked(
                    type(BeaconProxy).creationCode,
                    abi.encode(
                        subscribeBeacon,
                        abi.encodeWithSelector(
                            ISubscribeNFT.initialize.selector,
                            profileId,
                            name,
                            symbol
                        )
                    )
                ),
                bytes32(profileId),
                profile
            );
    }
}
