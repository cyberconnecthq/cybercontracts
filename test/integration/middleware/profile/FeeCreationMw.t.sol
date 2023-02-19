// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DeploySetting } from "../../../../script/libraries/DeploySetting.sol";

import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { CyberEngine } from "../../../../src/core/CyberEngine.sol";

import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract FeeCreationMwTest is TestIntegrationBase {
    string constant avatar = "avatar";
    string constant metadata = "metadata";

    function setUp() public {
        _setUp();
        // set fee creation middleware
        DeploySetting.DeployParameters memory setting = DeploySetting
            .DeployParameters(
                address(this),
                link3Signer,
                link3Treasury,
                address(this),
                address(this),
                engineTreasury,
                address(0),
                engineTreasury
            );
        CyberEngine(addrs.engineProxyAddress).setProfileMw(
            addrs.link3Profile,
            addrs.feeCreationMw,
            abi.encode(
                setting.link3Treasury,
                LibDeploy._INITIAL_FEE_BNB_TIER0,
                LibDeploy._INITIAL_FEE_BNB_TIER1,
                LibDeploy._INITIAL_FEE_BNB_TIER2,
                LibDeploy._INITIAL_FEE_BNB_TIER3,
                LibDeploy._INITIAL_FEE_BNB_TIER4,
                LibDeploy._INITIAL_FEE_BNB_TIER5,
                LibDeploy._INITIAL_FEE_BNB_TIER6
            )
        );
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        _createProfile(
            "alice&bob",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function _createProfile(
        string memory handle,
        uint256 fee,
        uint256 signer,
        string memory reason
    )
        internal
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        DataTypes.CreateProfileParams memory params = DataTypes
            .CreateProfileParams(bob, handle, avatar, metadata, address(0));
        (v, r, s) = _generateValidSig(params, signer);

        bytes memory byteReason = bytes(reason);
        if (byteReason.length > 0) {
            vm.expectRevert(byteReason);
        }
        link3Profile.createProfile{ value: fee }(
            params,
            abi.encode(v, r, s),
            new bytes(0)
        );
    }

    function _generateValidSig(
        DataTypes.CreateProfileParams memory params,
        uint256 signer
    )
        internal
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(feeCreationMw),
            keccak256(
                abi.encode(
                    Constants._FEE_CREATE_PROFILE_TYPEHASH,
                    params.to,
                    keccak256(bytes(params.handle)),
                    keccak256(bytes(params.avatar)),
                    keccak256(bytes(params.metadata)),
                    params.operator
                )
            ),
            "FeeCreationMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, digest);
        return (v, r, s);
    }
}
