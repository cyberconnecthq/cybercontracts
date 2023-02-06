// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { AggregatorV3Interface } from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DeploySetting } from "../../../../script/libraries/DeploySetting.sol";

import { ITreasury } from "../../../../src/interfaces/ITreasury.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { StableFeeCreationMw } from "../../../../src/middlewares/profile/StableFeeCreationMw.sol";

import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";

import "forge-std/console.sol"; // todo detlete

contract StableFeeCreationMwTest is TestIntegrationBase {
    uint256 validDeadline;
    uint256 startedAt;
    uint256 updatedAt;

    string constant avatar = "avatar";
    string constant metadata = "metadata";
    uint80 constant mockRoundId = 9;
    int256 constant mockUsdPrice = 99;
    uint80 constant answeredInRound = 0;

    uint256 constant tier0Fee = 100;
    uint256 constant tier1Fee = 200;
    uint256 constant tier2Fee = 300;
    uint256 constant tier3Fee = 400;
    uint256 constant tier4Fee = 500;
    uint256 constant tier5Fee = 600;
    uint256 constant tier6Fee = 700;
    uint256 constant tier7Fee = 800;

    function setUp() public {
        validDeadline = block.timestamp + 60 * 60;
        startedAt = validDeadline;
        updatedAt = validDeadline;
        _setUp();
        // set stable fee middleware
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
        LibDeploy.setStableFeeMw(
            vm,
            LibDeploy.DeployParams(false, false, setting),
            addrs.engineProxyAddress,
            addrs.link3Profile,
            addrs.stableFeeMw
        );
    }

    function testCannotCreateProfileWithAnInvalidCharacter() public {
        _createProfile(
            "alice&bob",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileWith0LenthHandle() public {
        _createProfile(
            "",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCannotCreateProfileWithACapitalLetter() public {
        _createProfile(
            "Test",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileWithBlankSpace() public {
        _createProfile(
            " ",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "HANDLE_INVALID_CHARACTER"
        );
    }

    function testCannotCreateProfileLongerThanMaxHandleLength() public {
        _createProfile(
            "aliceandbobisareallylongname",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "HANDLE_INVALID_LENGTH"
        );
    }

    function testCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_USD_FEE_TIER0,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_USD_FEE_TIER1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_USD_FEE_TIER2,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_USD_FEE_TIER3,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_USD_FEE_TIER4,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_USD_FEE_TIER5,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_USD_FEE_TIER6,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCreateProfileFeeTier7() public {
        _createProfile(
            "abcdefgefghi",
            LibDeploy._INITIAL_USD_FEE_TIER7,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            ""
        );
    }

    function testCannotCreateProfileFeeTier0() public {
        _createProfile(
            "a",
            LibDeploy._INITIAL_USD_FEE_TIER0 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier1() public {
        _createProfile(
            "ab",
            LibDeploy._INITIAL_USD_FEE_TIER1 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier2() public {
        _createProfile(
            "abc",
            LibDeploy._INITIAL_USD_FEE_TIER2 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier3() public {
        _createProfile(
            "abcd",
            LibDeploy._INITIAL_USD_FEE_TIER3 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier4() public {
        _createProfile(
            "abcde",
            LibDeploy._INITIAL_USD_FEE_TIER4 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier5() public {
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_USD_FEE_TIER5 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier6() public {
        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_USD_FEE_TIER6 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileFeeTier7() public {
        _createProfile(
            "abcdefgefghi",
            LibDeploy._INITIAL_USD_FEE_TIER7 - 1,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "INSUFFICIENT_FEE"
        );
    }

    function testCannotCreateProfileInvalidSigner() public {
        uint256 invalidPk = 123;
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_USD_FEE_TIER0,
            invalidPk,
            validDeadline,
            mockRoundId,
            "INVALID_SIGNATURE"
        );
    }

    function testCannotCreateProfileInvalidDeadline() public {
        uint256 invalidDeadline = 0;
        _createProfile(
            "abcdef",
            LibDeploy._INITIAL_USD_FEE_TIER0,
            link3SignerPk,
            invalidDeadline,
            mockRoundId,
            "DEADLINE_EXCEEDED"
        );
    }

    function testCannotCreateProfileIfMwDisallowed() public {
        engine.allowProfileMw(address(stableFeeProfileMw), false);

        _createProfile(
            "abcdefg",
            LibDeploy._INITIAL_USD_FEE_TIER6,
            link3SignerPk,
            validDeadline,
            mockRoundId,
            "PROFILE_MW_NOT_ALLOWED"
        );
    }

    function testCannotSetMwDataAsNonEngine() public {
        vm.expectRevert("NON_ENGINE_ADDRESS");
        stableFeeProfileMw.setProfileMwData(
            address(link3Profile),
            new bytes(0)
        );
    }

    function testCannotSetMwDataInvalidSigner() public {
        vm.prank(addrs.engineProxyAddress);
        vm.expectRevert("INVALID_SIGNER_OR_RECIPIENT");
        stableFeeProfileMw.setProfileMwData(
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
                tier6Fee,
                tier7Fee
            )
        );
    }

    function testSetMwDataAsEngine() public {
        address newSigner = address(0x555);
        address newTreasury = address(0x444);

        assertEq(
            stableFeeProfileMw.getSigner(address(link3Profile)),
            link3Signer
        );
        assertEq(
            stableFeeProfileMw.getRecipient(address(link3Profile)),
            link3Treasury
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier0
            ),
            LibDeploy._INITIAL_USD_FEE_TIER0
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier1
            ),
            LibDeploy._INITIAL_USD_FEE_TIER1
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier2
            ),
            LibDeploy._INITIAL_USD_FEE_TIER2
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier3
            ),
            LibDeploy._INITIAL_USD_FEE_TIER3
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier4
            ),
            LibDeploy._INITIAL_USD_FEE_TIER4
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier5
            ),
            LibDeploy._INITIAL_USD_FEE_TIER5
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier6
            ),
            LibDeploy._INITIAL_USD_FEE_TIER6
        );

        vm.prank(addrs.engineProxyAddress);
        stableFeeProfileMw.setProfileMwData(
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
                tier6Fee,
                tier7Fee
            )
        );

        assertEq(
            stableFeeProfileMw.getSigner(address(link3Profile)),
            newSigner
        );
        assertEq(
            stableFeeProfileMw.getRecipient(address(link3Profile)),
            newTreasury
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier0
            ),
            tier0Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier1
            ),
            tier1Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier2
            ),
            tier2Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier3
            ),
            tier3Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier4
            ),
            tier4Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier5
            ),
            tier5Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier6
            ),
            tier6Fee
        );
        assertEq(
            stableFeeProfileMw.getFeeByTier(
                address(link3Profile),
                StableFeeCreationMw.Tier.Tier7
            ),
            tier7Fee
        );
    }

    function _createProfile(
        string memory handle,
        uint256 fee,
        uint256 signer,
        uint256 deadline,
        uint80 roundId,
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
            deadline,
            roundId
        );

        bytes memory byteReason = bytes(reason);
        if (byteReason.length > 0) {
            vm.expectRevert(byteReason);
        }

        // mock AggregatorV3Interface.getRoundData
        vm.mockCall(
            address(usdOracle),
            abi.encodeWithSelector(
                AggregatorV3Interface.getRoundData.selector,
                roundId
            ),
            abi.encode(
                roundId,
                mockUsdPrice,
                startedAt,
                updatedAt,
                answeredInRound
            )
        );

        // mock AggregatorV3Interface.latestRoundData
        vm.mockCall(
            address(usdOracle),
            abi.encodeWithSelector(
                AggregatorV3Interface.latestRoundData.selector
            ),
            abi.encode(
                roundId,
                mockUsdPrice,
                startedAt,
                updatedAt,
                answeredInRound
            )
        );

        link3Profile.createProfile{ value: _attoUSDToWei(fee) }(
            params,
            abi.encode(v, r, s, deadline, roundId),
            new bytes(0)
        );
    }

    function _generateValidSig(
        DataTypes.CreateProfileParams memory params,
        address namespace,
        uint256 signer,
        uint256 deadline,
        uint80 roundId
    )
        internal
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        uint256 nonce = stableFeeProfileMw.getNonce(
            address(namespace),
            params.to
        );
        // "createProfileOracle(address to,string handle,string avatar,string metadata,address operator,uint256 nonce,uint256 deadline,uint80 roundId)"
        bytes32 digest = TestLib712.hashTypedDataV4(
            address(stableFeeProfileMw),
            keccak256(
                bytes.concat(
                    abi.encode(
                        Constants._CREATE_PROFILE_ORACLE_TYPEHASH,
                        params.to,
                        keccak256(bytes(params.handle)),
                        keccak256(bytes(params.avatar)),
                        keccak256(bytes(params.metadata))
                    ),
                    abi.encode(params.operator, nonce, deadline, roundId)
                )
            ),
            "StableFeeCreationMw",
            "1"
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer, digest);
        return (v, r, s);
    }

    function _attoUSDToWei(uint256 amount) internal pure returns (uint256) {
        return (amount * 1e8 * 1e18) / uint256(mockUsdPrice);
    }
}
