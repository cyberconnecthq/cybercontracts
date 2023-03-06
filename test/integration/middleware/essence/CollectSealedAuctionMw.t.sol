// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import "forge-std/console.sol";
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
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";
import { MockERC20 } from "../../../utils/MockERC20.sol";
import { CyberNFTBase } from "../../../../src/base/CyberNFTBase.sol";
import { CollectSealedAuctionMw } from "../../../../src/middlewares/essence/CollectSealedAuctionMw.sol";

contract CollectSealedAuctionMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents,
    ITreasuryEvents
{
    event CollectSealedAuctionMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 totalSupply,
        address recipient,
        address currency,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool profileRequired,
        bool subscribeRequired
    );

    event BidPlaced(
        uint256 id,
        address bidder,
        uint256 amount,
        uint256 profileId,
        uint256 essenceId,
        address namespace
    );

    address lila = address(0x1114);
    string lilaHandle = "lila";
    uint256 lilaProfileId;

    address dave = address(0xDA00);
    string daveHandle = "dave";
    uint256 daveProfileId;

    address bunty = address(0xDA10);
    string buntyHandle = "bunty";
    uint256 buntyProfileId;

    address shane = address(0xDA20);
    string shaneHandle = "shane";
    uint256 shaneProfileId;

    address meera = address(0xDA30);
    string meeraHandle = "meera";
    uint256 meeraProfileId;

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
    CollectSealedAuctionMw collectSealedAuctionMw;

    function setUp() public {
        _setUp();

        token = new MockERC20("Shit Coin", "SHIT");

        // Engine Treasury is the address of the treasury, but we put addrs.cyberTreasury here because its the proxy
        collectSealedAuctionMw = new CollectSealedAuctionMw(
            addrs.cyberTreasury
        );
        vm.label(address(collectSealedAuctionMw), "CollectSealedAuctionMw");
        vm.label(address(lila), "lila");
        vm.label(address(dave), "dave");
        vm.label(address(bobby), "bobby");
        vm.label(address(shane), "shane");
        vm.label(address(meera), "meera");
        vm.label(address(bunty), "bunty");
        vm.label(address(engineTreasury), "engineTreasury");

        // note: we first call the MockERC20 contract, in the contract, we mint x amount of shit coins to msg.sender
        // which is this test contract, then we transfer 10000 shit coins from this test contract to lila
        // then later lila first tells(approves) the token contract that the middleware can take x amount of shit coins out
        // lastly, the middlware accesses the shit coin contract and asks to extract x amount
        // it is successful because it is already extracted

        token.transfer(lila, 100000);
        token.transfer(dave, 50000);
        token.transfer(shane, 50000);
        token.transfer(meera, 50000);
        token.transfer(bunty, 50000);

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

    function testCollectWhenOnlyOneSupply() public {
        limit = 1;
        uint256 bidAmount = 10;
        subscribeRequired = false;

        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 startingLila = IERC20(address(token)).balanceOf(lila);
        uint256 startingBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 startingDave = IERC20(address(token)).balanceOf(dave);
        uint256 startingEngine = IERC20(address(token)).balanceOf(
            engineTreasury
        );
        uint256 cut = (bidAmount * treasuryFee) / Constants._MAX_BPS;

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(collectSealedAuctionMw), false, true);
        engine.allowEssenceMw(address(collectSealedAuctionMw), true);

        vm.prank(bobby);

        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(collectSealedAuctionMw),
                false,
                false
            ),
            abi.encode(
                limit,
                address(token),
                bobby,
                0,
                100000,
                false,
                subscribeRequired
            )
        );
        address collectPaidEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        // lila placing a bid
        vm.startPrank(lila);

        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 10);
        assertEq(token.balanceOf(address(collectSealedAuctionMw)), 10);
        vm.stopPrank();

        // dave placing a bid
        vm.startPrank(dave);

        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 7);
        assertEq(token.balanceOf(address(collectSealedAuctionMw)), 17);
        vm.stopPrank();

        // time wrap
        vm.warp(100001);

        // dave trying to collect
        vm.prank(dave);
        vm.expectRevert("Collector_No_Wins");
        link3Profile.collect(
            DataTypes.CollectParams(dave, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        // lila tries to collect
        vm.prank(lila);
        uint256 lilaCollectId = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        console.log(link3Profile.getEssenceNFT(bobbyProfileId, bobbyEssenceId));

        console.log(bobbyEssNFT, " and ", collectPaidEssenceProxy);

        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(lilaCollectId), lila);

        vm.prank(dave);
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);

        assertEq(IERC20(address(token)).balanceOf(dave), startingDave);

        assertEq(
            IERC20(address(token)).balanceOf(lila),
            startingLila - bidAmount
        );
        assertEq(
            IERC20(address(token)).balanceOf(bobby),
            startingBobby + bidAmount - cut
        );
        assertEq(
            IERC20(address(token)).balanceOf(engineTreasury),
            startingEngine + cut
        );
    }

    function testCollectWhenMoreThanOneSupply() public {
        limit = 5;
        subscribeRequired = false;

        uint256 treasuryFee = ITreasury(addrs.cyberTreasury).getTreasuryFee();
        uint256 startingLila = IERC20(address(token)).balanceOf(lila);
        uint256 startingBobby = IERC20(address(token)).balanceOf(bobby);
        uint256 startingDave = IERC20(address(token)).balanceOf(dave);
        uint256 startingMeera = IERC20(address(token)).balanceOf(meera);
        uint256 startingBunty = IERC20(address(token)).balanceOf(bunty);
        uint256 startingShane = IERC20(address(token)).balanceOf(shane);
        uint256 startingEngine = IERC20(address(token)).balanceOf(
            engineTreasury
        );

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // registers for essence, passes in the paid collect middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(collectSealedAuctionMw), false, true);
        engine.allowEssenceMw(address(collectSealedAuctionMw), true);

        vm.prank(bobby);

        uint256 bobbyEssenceId = link3Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                bobbyProfileId,
                BOBBY_ESSENCE_NAME,
                BOBBY_ESSENCE_LABEL,
                BOBBY_URL,
                address(collectSealedAuctionMw),
                false,
                false
            ),
            abi.encode(
                limit,
                address(token),
                bobby,
                0,
                100000,
                false,
                subscribeRequired
            )
        );
        address collectPaidEssenceProxy = getDeployedEssProxyAddress(
            link3EssBeacon,
            bobbyProfileId,
            bobbyEssenceId,
            address(link3Profile),
            BOBBY_ESSENCE_NAME,
            BOBBY_ESSENCE_LABEL,
            false
        );

        vm.startPrank(lila);
        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 10);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 15);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 20);
        vm.stopPrank();

        vm.startPrank(dave);
        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 5);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 7);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 8);
        vm.stopPrank();

        vm.startPrank(shane);
        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 1);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 7);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 6);
        vm.stopPrank();

        vm.startPrank(meera);
        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 2);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 3);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 4);
        vm.stopPrank();

        vm.startPrank(bunty);
        token.approve(address(collectSealedAuctionMw), 5000);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 8);
        vm.stopPrank();

        vm.warp(100001);

        vm.expectRevert("ENDED");
        vm.prank(lila);
        collectSealedAuctionMw.placeBid(bobbyProfileId, bobbyEssenceId, 22);

        // lila collecting

        vm.startPrank(lila);
        uint256 collectId1 = link3Profile.collect(
            DataTypes.CollectParams(dave, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        uint256 collectId2 = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        uint256 collectId3 = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        // vm.expectRevert("Collector_No_Wins");
        // link3Profile.collect(
        //     DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
        //     new bytes(0),
        //     new bytes(0)
        // );
        vm.stopPrank();

        vm.startPrank(dave);
        uint256 collectId4 = link3Profile.collect(
            DataTypes.CollectParams(lila, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        vm.expectRevert("Collector_No_Wins");
        link3Profile.collect(
            DataTypes.CollectParams(dave, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );

        vm.stopPrank();

        vm.startPrank(bunty);
        uint256 collectId5 = link3Profile.collect(
            DataTypes.CollectParams(bunty, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        vm.expectRevert("COLLECT_LIMIT_EXCEEDED");
        link3Profile.collect(
            DataTypes.CollectParams(bunty, bobbyProfileId, bobbyEssenceId),
            new bytes(0),
            new bytes(0)
        );
        vm.stopPrank();

        bobbyEssNFT = link3Profile.getEssenceNFT(
            bobbyProfileId,
            bobbyEssenceId
        );

        console.log(bobbyEssNFT, " and ", collectPaidEssenceProxy);

        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(collectId1), dave);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(collectId2), lila);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(collectId3), lila);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(collectId4), lila);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(collectId5), bunty);

        // lila tries to withdraw her funds after collecting
        vm.prank(lila);
        vm.expectRevert("CANNOT_WITHDRAW");
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);

        // shane and meera withdrawing
        vm.prank(shane);
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);
        vm.prank(meera);
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);

        // dave withdrawing his other bids
        vm.prank(dave);
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);

        vm.prank(bunty);
        vm.expectRevert("CANNOT_WITHDRAW");
        collectSealedAuctionMw.withdraw(bobbyProfileId, bobbyEssenceId);

        assertEq(IERC20(token).balanceOf(dave), startingDave - 8);
        assertEq(IERC20(token).balanceOf(shane), startingShane);
        assertEq(IERC20(token).balanceOf(meera), startingMeera);
        assertEq(IERC20(token).balanceOf(bunty), startingBunty - 8);
        // assertEq(IERC20(token).balanceOf(lila),startingLila-45);
        assertEq(IERC20(token).balanceOf(bobby), startingBobby + 61);
    }
}
