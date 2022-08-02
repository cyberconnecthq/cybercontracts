// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { DataTypes } from "../../../../src/libraries/DataTypes.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

import { IProfileNFTEvents } from "../../../../src/interfaces/IProfileNFTEvents.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";
import { PaidCollectMw } from "../../../../src/middlewares/essence/PaidCollectMw.sol";
import { TestIntegrationBase } from "../../../utils/TestIntegrationBase.sol";
import { EssenceNFT } from "../../../../src/core/EssenceNFT.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { TestLib712 } from "../../../utils/TestLib712.sol";
import { MockERC20 } from "../../../utils/MockERC20.sol";

contract PaidCollectEssenceMwTest is
    TestIntegrationBase,
    ICyberEngineEvents,
    IProfileNFTEvents
{
    address lila = 0xD68d2bD6f4a013A948881AC067282401b8f62FBb;
    address bobby = 0xE5D263Dd0D466EbF0Fc2647Dd4942a7525b0EAD1;
    address dave = 0xBDed9597195fb3C36b1A213cA45446906d7caeda;

    address bobbyEssNFT;
    string lilaHandle = "lila";
    string bobbyHandle = "bobby";
    string constant BOBBY_ESSENCE_NAME = "Gaia";
    string constant BOBBY_ESSENCE_LABEL = "GA";
    string constant BOBBY_URL = "url";
    uint256 bobbyProfileId;
    uint256 lilaProfileId;
    PaidCollectMw paidCollectMw;

    uint256 amountRequired;
    bool subscribeRequired;

    ERC20 token;

    function setUp() public {
        _setUp();

        token = new MockERC20("Shit Coin", "SHIT");

        // link3 Treasury is the address of the treasury
        paidCollectMw = new PaidCollectMw(addrs.cyberTreasury);
        vm.label(address(paidCollectMw), "PaidCollectMw");

        // note: we first call the MockERC20 contract and
        token.transfer(lila, 10000);

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

    function testCollectwithSufficientAmountAndNoSubscribe() public {
        // parameters for this test
        amountRequired = 10;
        subscribeRequired = false;

        // registers for essence, passes in the merkle hash root to set middleware data
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
                amountRequired,
                addrs.cyberTreasury,
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
                false
            ),
            abi.encode(
                amountRequired,
                addrs.cyberTreasury,
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
            1,
            bobbyProfileId,
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

        // check the balance xyz
        assertEq(bobbyEssNFT, paidCollectEssenceProxy);
        assertEq(EssenceNFT(bobbyEssNFT).balanceOf(lila), 1);
        assertEq(EssenceNFT(bobbyEssNFT).ownerOf(paidCollectTokenId), lila);

        // assertEq(link3Treasury.balance, startingLink3 + registerFee - cut);
        // assertEq(engineTreasury.balance, startingEngine + cut);
    }
    // test for not ask to subscribe, with sufficient amount

    // test for insufficient amount

    // test for ask for yes subscribe
}
