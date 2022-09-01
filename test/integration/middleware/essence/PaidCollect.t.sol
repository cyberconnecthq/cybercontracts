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
import { PaidCollectMw } from "../../../../src/middlewares/essence/PaidCollectMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";
import { MockERC20 } from "../../../utils/MockERC20.sol";
import { CyberNFTBase } from "../../../../src/base/CyberNFTBase.sol";

contract PaidCollectEssenceMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents,
    ITreasuryEvents
{
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

    uint256 amountRequired;
    bool subscribeRequired;
    uint256 limit;

    ERC20 token;
    PaidCollectMw paidCollectMw;

    function setUp() public {
        _setUp();

        token = new MockERC20("Shit Coin", "SHIT");

        // Engine Treasury is the address of the treasury, but we put addrs.cyberTreasury here because its the proxy
        paidCollectMw = new PaidCollectMw(addrs.cyberTreasury);
        vm.label(address(paidCollectMw), "PaidCollectMw");
        vm.label(address(lila), "lila");
        vm.label(address(dave), "dave");
        vm.label(address(bobby), "bobby");
        vm.label(address(engineTreasury), "engineTreasury");

        // note: we first call the MockERC20 contract, in the contract, we mint x amount of shit coins to msg.sender
        // which is this test contract, then we transfer 10000 shit coins from this test contract to lila
        // then later lila first tells(approves) the token contract that the middleware can take x amount of shit coins out
        // lastly, the middlware accesses the shit coin contract and asks to extract x amount
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

    function testCannotRegisterEssenceIfCurrencyNotAllowed() public {
        // parameters for this test
        limit = 1;
        amountRequired = 1000;
        subscribeRequired = false;

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectRevert("CURRENCY_NOT_ALLOWED");

        vm.prank(bobby);

        link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );
    }

    function testCollectWhenNoSubscribeRequired() public {
        // parameters for this test
        limit = 1;
        amountRequired = 1000;
        subscribeRequired = false;

        // checks the initial states of the fund
        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 startingLila = IERC20(address(token)).balanceOf(lila);
        uint256 startingBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 startingEngine = IERC20(address(token)).balanceOf(
            engineTreasury
        );
        uint256 cut = (amountRequired * treasuryFee) / Constants._MAX_BPS;

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(paidCollectMw),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        address paidCollectEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        // lila wants to collect bob's essence
        vm.startPrank(lila);
        token.approve(address(paidCollectMw), 5000);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            paidCollectEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            bobbyProfileId,
            1,
            1,
            new bytes(0),
            new bytes(0)
        );

        uint256 paidCollectTokenId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );
        vm.stopPrank();

        // check the ownership of the essence
        assertEq(bobbyEssNFT, paidCollectEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(paidCollectTokenId), lila);

        // check the balance
        assertEq(
            IERC20(address(token)).balanceOf(lila),
            startingLila - amountRequired
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            startingBobby + amountRequired - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            startingEngine + cut
        );
    }

    function testCollectWithSubscribeRequired() public {
        // we say that the user has to subscribe prior to collecting
        limit = 1;
        amountRequired = 1000;
        subscribeRequired = true;

        // checks the initial states of the fund
        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 startingLila = IERC20(address(token)).balanceOf(lila);
        uint256 startingBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 startingEngine = IERC20(address(token)).balanceOf(
            engineTreasury
        );
        uint256 cut = (amountRequired * treasuryFee) / Constants._MAX_BPS;

        // data for the subscription
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(true, true, true, false);
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(paidCollectMw),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        address paidCollectEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        // lila first follows bobby
        vm.startPrank(lila);

        address subscribeProxy = getDeployedSubProxyAddress(
            link3SubBeacon,
            bobbyProfileId,
            address(link3Profile),
            bobbyHandle
        );

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(ids[0], subscribeProxy);
        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(lila, ids, data, data);

        uint256 bobbySubscribeNFTId = link3Profile.subscribe(
            DataTypes.SubscribeParams(ids),
            data,
            data
        )[0];

        // check bob sub nft supply
        address bobSubNFT = link3Profile.getSubscribeNFT(bobbyProfileId);
        assertEq(bobSubNFT, subscribeProxy);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        // check ownership of first sub nft
        assertEq(ERC721(bobSubNFT).ownerOf(bobbySubscribeNFTId), address(lila));

        // lila wants to collect bobby's essence
        token.approve(address(paidCollectMw), 5000);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            paidCollectEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            bobbyProfileId,
            1,
            1,
            new bytes(0),
            new bytes(0)
        );

        uint256 paidCollectTokenId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );
        vm.stopPrank();

        // check the ownership of the essence
        assertEq(bobbyEssNFT, paidCollectEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(paidCollectTokenId), lila);

        // check the balance
        assertEq(
            IERC20(address(token)).balanceOf(lila),
            startingLila - amountRequired
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            startingBobby + amountRequired - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            startingEngine + cut
        );
    }

    function testCannotCollectWithNoSubscribeWhenSubscribeRequired() public {
        // we say that the user has to subscribe before collecting
        limit = 1;
        amountRequired = 1000;
        subscribeRequired = true;

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(true, true, true, false);
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(paidCollectMw),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        // lila wants to collect bob's essence, without subscribing prior
        vm.startPrank(lila);
        token.approve(address(paidCollectMw), 5000);

        vm.expectRevert("NOT_SUBSCRIBED");

        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        vm.stopPrank();
    }

    function testCannotCollectWithInsufficientFund() public {
        // we say that the user has to subscribe prior to collecting
        limit = 1;
        amountRequired = 999999;
        subscribeRequired = false;

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(true, true, true, false);
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(paidCollectMw),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.startPrank(lila);
        // lila wants to collect bobby's essence
        token.approve(address(paidCollectMw), 999999);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        vm.stopPrank();
    }

    function testCollectUnderLimit() public {
        // parameters for this test
        amountRequired = 1000;
        limit = 3;
        subscribeRequired = false;

        // checks the initial states of the fund
        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 balanceLila = IERC20(address(token)).balanceOf(lila);
        uint256 balanceBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 balanceDave = IERC20(address(token)).balanceOf(dave);
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
        emit AllowEssenceMw(address(paidCollectMw), false, true);
        engine.allowEssenceMw(address(paidCollectMw), true);

        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            bobbyProfileId,
            1,
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            BOBBY_URL,
            address(paidCollectMw),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        vm.prank(bobby);
        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(paidCollectMw),
                false,
                false
            ),
            abi.encode(
                limit,
                amountRequired,
                bobby,
                address(token),
                subscribeRequired
            )
        );

        address limitedPaidCollectEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        // lila collects bobby's addictive essence
        vm.startPrank(lila);
        token.approve(address(paidCollectMw), 5000);

        vm.expectEmit(true, true, true, false);
        emit DeployEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId,
            limitedPaidCollectEssenceProxy
        );

        vm.expectEmit(true, true, true, false);
        emit CollectEssence(
            lila,
            bobbyProfileId,
            1,
            1,
            new bytes(0),
            new bytes(0)
        );

        // lila collects the first essence
        uint256 limitedPaidCollectTokenIdOne = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        // verifies the deployed essence address
        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        assertEq(bobbyEssNFT, limitedPaidCollectEssenceProxy);

        // check the ownership of the essence after the first collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(limitedPaidCollectTokenIdOne),
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
        uint256 limitedPaidCollectTokenIdTwo = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        // check the ownership of the essence after the second collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 2);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(limitedPaidCollectTokenIdTwo),
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

        // lila collects the third essence, reaches the collect limit
        uint256 limitedPaidCollectTokenIdThree = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        // check the ownership of the essence after the third collection
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 3);
        assertEq(
            EssenceNFT(bobbyEssNFT).ownerOf(limitedPaidCollectTokenIdThree),
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

        // lila collects the fourth essence which exceeds the limit, it won't be allowed
        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");

        link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
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

        // Dave collects their first essence(essence id 4), because they have not collected any essence before, it will go through
        vm.startPrank(dave);
        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");

        // dave collects the fourth essence
        link3Profile.collect(
            DataTypes.CollectParams(dave, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
    }
}
