// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DeploySetting } from "../../../../script/libraries/DeploySetting.sol";

import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { CyberEngine } from "../../../../src/core/CyberEngine.sol";
import { FeeCreationMw } from "../../../../src/middlewares/profile/FeeCreationMw.sol";

import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract FeeCreationMwTest is TestIntegrationBase {
    string constant avatar = "avatar";
    string constant metadata = "metadata";
    uint256 constant tier0Fee = 100 ether;
    uint256 constant tier1Fee = 200 ether;
    uint256 constant tier2Fee = 300 ether;
    uint256 constant tier3Fee = 400 ether;
    uint256 constant tier4Fee = 500 ether;
    uint256 constant tier5Fee = 600 ether;
    uint256 constant tier6Fee = 700 ether;

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

    function testCannotCreateProfileWith0LenthHandle() public {
        _createProfile(
            "",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        _createProfile(
            "Test",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        _createProfile(
            " ",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        _createProfile(
            "aliceandbobisareallylongname",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_FEE_BNB_TIER0,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_FEE_BNB_TIER1,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_FEE_BNB_TIER2,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_FEE_BNB_TIER3,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_FEE_BNB_TIER4,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_BNB_TIER5,
            link3SignerPk,
            ""
        );
    }

    function testCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_FEE_BNB_TIER6,
            link3SignerPk,
            ""
        );
    }

    function testCannotCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_FEE_BNB_TIER0 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_FEE_BNB_TIER1 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_FEE_BNB_TIER2 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_FEE_BNB_TIER3 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_FEE_BNB_TIER4 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_BNB_TIER5 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_FEE_BNB_TIER6 - 1,
            link3SignerPk,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileIfMwDisallowed() public {
        engine.allowProfileMw(address(feeCreationMw), false);

        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_FEE_BNB_TIER6,
            link3SignerPk,
            "PROFILE_MW_NOT_ALLOWED"
        );
    }

    function testCannotSetMwDataAsNonEngine() public {
        vm.expectRevert("NON_ENGINE_ADDRESS");
        feeCreationMw.setProfileMwData(address(link3Profile), new bytes(0));
    }

    function testCannotSetMwDataInvalidRecipent() public {
        vm.prank(addrs.engineProxyAddress);
        vm.expectRevert("INVALID_RECIPIENT");
        feeCreationMw.setProfileMwData(
            address(link3Profile),
            abi.encode(
                address(0),
                tier0Fee,
                tier1Fee,
                tier2Fee,
                tier3Fee,
                tier4Fee,
                tier5Fee,
                tier6Fee
            )
        );
    }

    function testSetMwDataAsEngine() public {
        address newTreasury = address(0x444);

        assertEq(
            feeCreationMw.getRecipient(address(link3Profile)),
            link3Treasury
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier0
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER0
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier1
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER1
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier2
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER2
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier3
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER3
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier4
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER4
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier5
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER5
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier6
            ),
            LibDeploy._INITIAL_FEE_BNB_TIER6
        );

        vm.prank(addrs.engineProxyAddress);
        feeCreationMw.setProfileMwData(
            address(link3Profile),
            abi.encode(
                newTreasury,
                tier0Fee,
                tier1Fee,
                tier2Fee,
                tier3Fee,
                tier4Fee,
                tier5Fee,
                tier6Fee
            )
        );

        assertEq(
            feeCreationMw.getRecipient(address(link3Profile)),
            newTreasury
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier0
            ),
            tier0Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier1
            ),
            tier1Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier2
            ),
            tier2Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier3
            ),
            tier3Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier4
            ),
            tier4Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier5
            ),
            tier5Fee
        );
        assertEq(
            feeCreationMw.getFeeByTier(
                address(link3Profile),
                FeeCreationMw.Tier.Tier6
            ),
            tier6Fee
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
