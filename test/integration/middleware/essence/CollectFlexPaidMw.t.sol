// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC721 } from "../../../../src/dependencies/solmate/ERC721.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { ITreasury } from "../../../../src/interfaces/ITreasury.sol";
import { ITreasuryEvents } from "../../../../src/interfaces/ITreasuryEvents.sol";
import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { CollectFlexPaidMw } from "../../../../src/middlewares/essence/CollectFlexPaidMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";
import { MockERC20 } from "../../../utils/MockERC20.sol";
import { CyberNFTBase } from "../../../../src/base/CyberNFTBase.sol";

contract CollectFlexPaidMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents,
    ITreasuryEvents
{
    event CollectFlexPaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address recipient
    );
    event CollectFlexPaidMwPreprocessed(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed collector,
        address recipient,
        address currency,
        uint256 amount,
        string payId
    );
    address lila = address(0x1114);
    string lilaHandle = "lila";
    uint256 lilaProfileId;

    address dave = address(0xDA00);
    string daveHandle = "dave";
    uint256 daveProfileId;

    address bobby = address(0xB0B);
    string bobbyHandle = "bobby";
    uint256 bobbyProfileId;
    address bobbyEssNFT;
    string constant BOBBY_ESSENCE_NAME = "Gaia";
    string constant BOBBY_ESSENCE_LABEL = "GA";
    string constant BOBBY_URL = "url";
    string constant METADATA_ID =
        "925b3c3ca193ab7e9800787734cf733092f6ee95bcca0795be3c12e6bf5fba53";

    uint256 amountRequired;
    bool subscribeRequired;
    uint256 limit;

    ERC20 token;
    CollectFlexPaidMw collectFlexPaidMw;

    function setUp() public {
        _setUp();

        token = new MockERC20("Good Coin", "GOOD");

        // Engine Treasury is the address of the treasury, but we put addrs.cyberTreasury here because its the proxy
        collectFlexPaidMw = new CollectFlexPaidMw(
            addrs.cyberTreasury,
            addrs.link3Profile
        );
        vm.label(address(collectFlexPaidMw), "collectFlexPaidMw");
        vm.label(address(lila), "lila");
        vm.label(address(dave), "dave");
        vm.label(address(bobby), "bobby");
        vm.label(address(engineTreasury), "engineTreasury");

        // note: we first call the MockERC20 contract, in the contract, we mint x amount of good coins to msg.sender
        // which is this test contract, then we transfer 10000 good coins from this test contract to lila
        // then later lila first tells(approves) the token contract that the middleware can take x amount of good coins out
        // lastly, the middlware accesses the good coin contract and asks to extract x amount
        // it is successful because it is already extracted

        token.transfer(lila, 100000);
        token.transfer(dave, 50000);

        // bob registeres for their profile
        bobbyProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            bobbyHandle,
            bobby,
            link3SignerPk
        );

        // lila registers for their profile
        lilaProfileId = TestLibFixture.registerProfile(
            vm,
            link3Profile,
            profileMw,
            lilaHandle,
            lila,
            link3SignerPk
        );
    }

    function testCannotCollectWithInsufficientFund() public {
        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(true, true, true, false);
        emit AllowEssenceMw(address(collectFlexPaidMw), false, true);
        engine.allowEssenceMw(address(collectFlexPaidMw), true);

        vm.expectEmit(true, true, true, true);
        emit CollectFlexPaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            1,
            bobby
        );

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(collectFlexPaidMw),
            abi.encode(bobby)
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(collectFlexPaidMw),
                false,
                false
            ),
            abi.encode(bobby)
        );

        vm.startPrank(lila, lila);
        // lila wants to collect bobby's essence
        token.approve(address(collectFlexPaidMw), 999999);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(uint256(999999), address(token), METADATA_ID),
            new bytes(0)
        );
        vm.stopPrank();
    }

    function testCollectUnderLimit() public {
        // parameters for this test
        amountRequired = 1000;

        // checks the initial states of the fund
        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 balanceLila = IERC20(address(token)).balanceOf(lila);
        uint256 balanceBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 balanceEngine = IERC20(address(token)).balanceOf(
            engineTreasury
        );
        uint256 cut = (amountRequired * treasuryFee) / Constants._MAX_BPS;

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        // set the limit
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(collectFlexPaidMw), false, true);
        engine.allowEssenceMw(address(collectFlexPaidMw), true);

        vm.expectEmit(true, true, true, true);
        emit CollectFlexPaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            1,
            bobby
        );

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(collectFlexPaidMw),
            abi.encode(bobby)
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(collectFlexPaidMw),
                false,
                false
            ),
            abi.encode(bobby)
        );

        address collectFlexPaidEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        // lila collects bobby's addictive essence
        vm.startPrank(lila, lila);
        token.approve(address(collectFlexPaidMw), 5000);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            collectFlexPaidEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            bobbyProfileId,
            1,
            1,
            abi.encode(amountRequired, address(token), METADATA_ID),
            new bytes(0)
        );
        vm.expectEmit(true, true, true, true);
        emit CollectFlexPaidMwPreprocessed(
            bobbyProfileId,
            1,
            lila,
            bobby,
            address(token),
            amountRequired,
            METADATA_ID
        );

        // lila collects the first essence
        uint256 collectFlexPaidTokenIdOne = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(amountRequired, address(token), METADATA_ID),
            new bytes(0)
        );

        // verifies the deployed essence address
        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        assertEq(bobbyEssNFT, collectFlexPaidEssenceProxy);

        // check the ownership of the essence after the first collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(collectFlexPaidTokenIdOne),
            lila
        );

        // check the balance after the first collection
        assertEq(
            IERC20(address(token)).balanceOf(lila),
            balanceLila = balanceLila - amountRequired
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            balanceBobby = balanceBobby + amountRequired - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine = balanceEngine + cut
        );

        // lila collects the second essence
        uint256 collectFlexPaidTokenIdTwo = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(amountRequired, address(token), METADATA_ID),
            new bytes(0)
        );

        // check the ownership of the essence after the second collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 2);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(collectFlexPaidTokenIdTwo),
            lila
        );

        // check the balance after the second collection
        assertEq(
            IERC20(address(token)).balanceOf(lila),
            balanceLila = balanceLila - amountRequired
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            balanceBobby = balanceBobby + amountRequired - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine = balanceEngine + cut
        );

        // lila collects the third essence
        uint256 collectFlexPaidTokenIdThree = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(amountRequired, address(token), METADATA_ID),
            new bytes(0)
        );

        // check the ownership of the essence after the third collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 3);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(collectFlexPaidTokenIdThree),
            lila
        );

        // check the balance after the third collection
        assertEq(
            IERC20(address(token)).balanceOf(lila),
            balanceLila = balanceLila - amountRequired
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            balanceBobby = balanceBobby + amountRequired - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine = balanceEngine + cut
        );

        // lila collects the fourth essence which not allowed currency, it won't be allowed
        vm.expectRevert("CURRENCY_NOT_ALLOWED");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(amountRequired, address(0x123456), METADATA_ID),
            new bytes(0)
        );

        // balance should stay the same
        assertEq(IERC20(address(token)).balanceOf(lila), balanceLila);
        assertEq(IERC20(address(token)).balanceOf(bobby), balanceBobby);
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine
        );

        vm.expectRevert("INVALID_AMOUNT");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(0, address(token), METADATA_ID),
            new bytes(0)
        );
        // balance should stay the same
        assertEq(IERC20(address(token)).balanceOf(lila), balanceLila);
        assertEq(IERC20(address(token)).balanceOf(bobby), balanceBobby);
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine
        );
        vm.stopPrank();

        vm.startPrank(bobby);
        vm.expectRevert("NOT_FROM_COLLECTOR");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            abi.encode(amountRequired, address(token), METADATA_ID),
            new bytes(0)
        );
        // balance should stay the same
        assertEq(IERC20(address(token)).balanceOf(lila), balanceLila);
        assertEq(IERC20(address(token)).balanceOf(bobby), balanceBobby);
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            balanceEngine
        );
    }
}
