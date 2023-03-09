// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { ITreasury } from "../../../../src/interfaces/ITreasury.sol";
import { ITreasuryEvents } from "../../../../src/interfaces/ITreasuryEvents.sol";
import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { SubscribePaidMw } from "../../../../src/middlewares/subscribe/SubscribePaidMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";
import { MockERC20 } from "../../../utils/MockERC20.sol";
import { MockERC721 } from "../../../utils/MockERC721.sol";

import { CyberNFTBase } from "../../../../src/base/CyberNFTBase.sol";

contract SubscribePaidMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents,
    ITreasuryEvents
{
    event SubscribePaidMwSet(
        address indexed namespace,
        uint256 indexed profileId,
        uint256 indexed amount,
        address recipient,
        address currency,
        bool nftRequired,
        address nftAddress
    );

    address lila = address(0x1114);
    string lilaHandle = "lila";
    uint256 lilaProfileId;

    address bobby = address(0xB0B);
    string bobbyHandle = "bobby";
    uint256 bobbyProfileId;

    uint256 amountRequired;
    bool nftRequired;

    ERC20 token;
    ERC721 nft;
    SubscribePaidMw subscribePaidMw;

    function setUp() public {
        _setUp();
        nft = new MockERC721("CyberPunk", "CP");
        // when the contract is initialized, some tokens were minted into the address of this contract
        token = new MockERC20("Shit Coin", "SHIT");

        // Engine Treasury is the address of the treasury, but we put addrs.cyberTreasury here because its the proxy
        subscribePaidMw = new SubscribePaidMw(
            addrs.cyberTreasury,
            addrs.link3Profile
        );
        vm.label(address(subscribePaidMw), "subscribePaidMw");

        // msg.sender is this contract, then the token contract transfers 10000 to lila
        token.transfer(lila, 10000);
        assertEq(IERC20(address(token)).balanceOf(lila), 10000);
        assertEq(
            IERC20(address(token)).balanceOf(address(this)),
            99999999999999990000
        );

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

    function testCannotSetSubscribeDataIfCurrencyNotAllowed() public {
        // parameters for this test
        amountRequired = 1000;
        nftRequired = false;
        address nftAddress = address(0);

        // allows the subscribe middleware, passes in the paid subscribe middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowSubscribeMw(address(subscribePaidMw), false, true);
        engine.allowSubscribeMw(address(subscribePaidMw), true);

        vm.expectRevert("CURRENCY_NOT_ALLOWED");

        vm.prank(bobby);
        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            abi.encode(
                amountRequired,
                bobby,
                address(token),
                nftRequired,
                nftAddress
            )
        );
    }

    function testSubscribeWhenNoNFTRequired() public {
        // parameters for this test
        amountRequired = 1000;
        nftRequired = false;
        address nftAddress = address(0);

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

        // allows the subscribe middleware, passes in the paid subscribe middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowSubscribeMw(address(subscribePaidMw), false, true);
        engine.allowSubscribeMw(address(subscribePaidMw), true);

        // initialize the subscribe middleware data
        vm.prank(bobby);

        vm.expectEmit(true, true, true, true);
        emit SubscribePaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            amountRequired,
            bobby,
            address(token),
            nftRequired,
            nftAddress
        );

        vm.expectEmit(true, false, false, true);
        emit SetSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            new bytes(0)
        );

        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            abi.encode(
                amountRequired,
                bobby,
                address(token),
                nftRequired,
                nftAddress
            )
        );

        address subscribeProxy = getDeployedSubProxyAddress(
            link3SubBeacon,
            bobbyProfileId,
            address(link3Profile),
            bobbyHandle
        );

        // lila wants to follows bobby
        vm.startPrank(lila);

        token.approve(address(subscribePaidMw), 5000);

        // put bobby in the id list
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        vm.expectEmit(true, true, false, true, address(link3Profile));
        emit DeploySubscribeNFT(ids[0], subscribeProxy);
        vm.expectEmit(true, false, false, true, address(link3Profile));
        emit Subscribe(lila, ids, data, data);

        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data)[0];

        // check bob sub nft supply
        address bobSubNFT = link3Profile.getSubscribeNFT(bobbyProfileId);
        assertEq(bobSubNFT, subscribeProxy);
        assertEq(CyberNFTBase(bobSubNFT).totalSupply(), 1);

        vm.stopPrank();

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

    function testCannotSubscribeWithNoNFTWhenNFTRequired() public {
        // we say that the user has to have some nft
        amountRequired = 1000;
        nftRequired = true;

        // data for the subscription
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // allows the subscribe middleware, passes in the paid subscribe middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowSubscribeMw(address(subscribePaidMw), false, true);
        engine.allowSubscribeMw(address(subscribePaidMw), true);

        vm.prank(bobby);

        vm.expectEmit(true, true, true, true);
        emit SubscribePaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            amountRequired,
            bobby,
            address(token),
            nftRequired,
            address(nft)
        );

        vm.expectEmit(true, false, false, true);
        emit SetSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            new bytes(0)
        );

        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            abi.encode(
                amountRequired,
                bobby,
                address(token),
                nftRequired,
                address(nft)
            )
        );

        // lila wants to subscribe to bobby, without the required nft
        vm.startPrank(lila);
        token.approve(address(subscribePaidMw), 5000);

        vm.expectRevert("NO_REQUIRED_NFT");
        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);

        vm.stopPrank();
    }

    function testSubscribeWithNFTRequired() public {
        // we say that the user has to have some NFT to subscribe
        amountRequired = 1000;
        nftRequired = true;

        // msg.sender is this contract, then the nft contract transders tokenId 1 to lila
        nft.transferFrom(address(this), lila, 1);
        assertEq(IERC721(address(nft)).ownerOf(1), lila);

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

        // allows the subscribe middleware, passes in the paid subscribe middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowSubscribeMw(address(subscribePaidMw), false, true);
        engine.allowSubscribeMw(address(subscribePaidMw), true);

        // initialize the subscribe middleware data
        vm.prank(bobby);

        vm.expectEmit(true, true, true, true);
        emit SubscribePaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            amountRequired,
            bobby,
            address(token),
            nftRequired,
            address(nft)
        );

        vm.expectEmit(true, false, false, true);
        emit SetSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            new bytes(0)
        );

        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            abi.encode(
                amountRequired,
                bobby,
                address(token),
                nftRequired,
                address(nft)
            )
        );

        vm.startPrank(lila);

        token.approve(address(subscribePaidMw), amountRequired);

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
        vm.stopPrank();

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

    function testCannotSubscribeWithInsufficientFund() public {
        amountRequired = 999999;
        nftRequired = false;

        // data for the subscription
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobbyProfileId;
        bytes[] memory data = new bytes[](1);

        // approve the currency that will be used in the transaction
        vm.expectEmit(true, true, true, false);
        emit AllowCurrency(address(token), false, true);
        treasury.allowCurrency(address(token), true);

        // allows the subscribe middleware, passes in the paid subscribe middleware address
        vm.expectEmit(false, false, false, true);
        emit AllowSubscribeMw(address(subscribePaidMw), false, true);
        engine.allowSubscribeMw(address(subscribePaidMw), true);

        vm.prank(bobby);

        vm.expectEmit(true, true, true, true);
        emit SubscribePaidMwSet(
            address(link3Profile),
            bobbyProfileId,
            amountRequired,
            bobby,
            address(token),
            nftRequired,
            address(0)
        );

        vm.expectEmit(true, false, false, true);
        emit SetSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            new bytes(0)
        );

        link3Profile.setSubscribeData(
            bobbyProfileId,
            "uri",
            address(subscribePaidMw),
            abi.encode(
                amountRequired,
                bobby,
                address(token),
                nftRequired,
                address(0)
            )
        );

        vm.startPrank(lila);

        token.approve(address(subscribePaidMw), 999999);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        link3Profile.subscribe(DataTypes.SubscribeParams(ids), data, data);

        vm.stopPrank();
    }
}
