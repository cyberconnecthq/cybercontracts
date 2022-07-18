// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";

import { ITreasury } from "../../../../src/interfaces/ITreasury.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { PermissionedFeeCreationMw } from "../../../../src/middlewares/profile/PermissionedFeeCreationMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

contract PermissionedFeeCreationMwTest is TestIntegrationBase {
    uint256 bobProfileId;
    uint256 validDeadline;

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
        validDeadline = block.timestamp + 60 * 60;
        _setUp();
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        _createProfile(
            "alice&bob",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        _createProfile(
            "",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        _createProfile(
            "Test",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        _createProfile(
            " ",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        _createProfile(
            "aliceandbobisareallylongname",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_FEE_TIER0,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_FEE_TIER1,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_FEE_TIER3,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_FEE_TIER4,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_TIER5,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_FEE_TIER6,
            link3SignerPk,
            validDeadline,
            ""
        );
    }

    function testCannotCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_FEE_TIER0 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_FEE_TIER1 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_FEE_TIER2 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_FEE_TIER3 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_FEE_TIER4 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_TIER5 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_FEE_TIER6 - 1,
            link3SignerPk,
            validDeadline,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileInvalidSigner() public {
        uint256 invalidPk = 123;
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_TIER0,
            invalidPk,
            validDeadline,
            "INVALID_SIGNATURE"
        );
    }

    function testCannotCreateProfileInvalidDeadline() public {
        uint256 invalidDeadline = 0;
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_FEE_TIER0,
            link3SignerPk,
            invalidDeadline,
            "DEADLINE_EXCEEDED"
        );
    }

    function testCannotSetMwDataAsNonEngine() public {
        vm.expectRevert("NON_ENGINE_ADDRESS");
        profileMw.setProfileMwData(address(link3Profile), new bytes(0));
    }

    function testCreateProfileTreasury() public {
        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 startingLink3 = link3Treasury.balance;
        uint256 registerFee = LibDeploy._INITIAL_FEE_TIER0;
        uint256 startingEngine = engineTreasury.balance;

        _createProfile("a", registerFee, link3SignerPk, validDeadline, "");
        uint256 cut = (registerFee * treasuryFee) / Constants._MAX_BPS;
        assertEq(link3Treasury.balance, startingLink3 + registerFee - cut);
        assertEq(engineTreasury.balance, startingEngine + cut);
    }

    function testCannotSetMwDataInvalidSigner() public {
        vm.prank(addrs.engineProxyAddress);
        vm.expectRevert("INVALID_SIGNER_OR_RECIPIENT");
        profileMw.setProfileMwData(
            address(link3Profile),
            abi.encode(
                address(0),
                address(0x111),
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

    function testCannotSetMwDataInvalidRecipent() public {
        vm.prank(addrs.engineProxyAddress);
        vm.expectRevert("INVALID_SIGNER_OR_RECIPIENT");
        profileMw.setProfileMwData(
            address(link3Profile),
            abi.encode(
                address(0x111),
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
        address newSigner = address(0x555);
        address newTreasury = address(0x444);

        assertEq(profileMw.getSigner(address(link3Profile)), link3Signer);
        assertEq(profileMw.getRecipient(address(link3Profile)), link3Treasury);
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier0
            ),
            LibDeploy._INITIAL_FEE_TIER0
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier1
            ),
            LibDeploy._INITIAL_FEE_TIER1
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier2
            ),
            LibDeploy._INITIAL_FEE_TIER2
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier3
            ),
            LibDeploy._INITIAL_FEE_TIER3
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier4
            ),
            LibDeploy._INITIAL_FEE_TIER4
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier5
            ),
            LibDeploy._INITIAL_FEE_TIER5
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier6
            ),
            LibDeploy._INITIAL_FEE_TIER6
        );

        vm.prank(addrs.engineProxyAddress);
        profileMw.setProfileMwData(
            address(link3Profile),
            abi.encode(
                newSigner,
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

        assertEq(profileMw.getSigner(address(link3Profile)), newSigner);
        assertEq(profileMw.getRecipient(address(link3Profile)), newTreasury);
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier0
            ),
            tier0Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier1
            ),
            tier1Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier2
            ),
            tier2Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier3
            ),
            tier3Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier4
            ),
            tier4Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier5
            ),
            tier5Fee
        );
        assertEq(
            profileMw.getFeeByTier(
                address(link3Profile),
                PermissionedFeeCreationMw.Tier.Tier6
            ),
            tier6Fee
        );
    }

    function _createProfile(
        string memory handle,
        uint256 fee,
        uint256 signer,
        uint256 deadline,
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
        (v, r, s) = _generateValidSig(
            params,
            address(link3Profile),
            signer,
            deadline
        );

        bytes memory byteReason = bytes(reason);
        if (byteReason.length > 0) {
            vm.expectRevert(byteReason);
        }
        link3Profile.createProfile{ value: fee }(
            params,
            abi.encode(v, r, s, deadline),
            new bytes(0)
        );
    }

    function _generateValidSig(
        DataTypes.CreateProfileParams memory params,
        address namespace,
        uint256 signer,
        uint256 deadline
    )
        internal
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        uint256 nonce = profileMw.getNonce(address(namespace), params.to);
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(profileMw),
            keccak256(
                abi.encode(
                    Constants._CREATE_PROFILE_TYPEHASH,
                    params.to,
                    keccak256(bytes(params.handle)),
                    keccak256(bytes(params.avatar)),
                    keccak256(bytes(params.metadata)),
                    nonce,
                    deadline
                )
            ),
            "PermissionedFeeCreationMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, digest);
        return (v, r, s);
    }
}
