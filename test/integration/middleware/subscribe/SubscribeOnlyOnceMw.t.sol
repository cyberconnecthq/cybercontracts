// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../../../script/libraries/LibDeploy.sol";
import { TestLibFixture } from "../../../utils/TestLibFixture.sol";
import { CyberEngine } from "../../../../src/core/CyberEngine.sol";
import { RolesAuthority } from "../../../../src/dependencies/solmate/RolesAuthority.sol";
import { SubscribeOnlyOnceMw } from "../../../../src/middlewares/subscribe/SubscribeOnlyOnceMw.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ICyberEngineEvents } from "../../../../src/interfaces/ICyberEngineEvents.sol";

contract SubscribeOnlyOnceMwTest is Test, ICyberEngineEvents {
    CyberEngine engine;
    SubscribeOnlyOnceMw mw;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    address alice = address(0xA11CE);
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk); // matches LibFixture
    uint256 bobProfileId;

    function setUp() public {
        mw = new SubscribeOnlyOnceMw();
        vm.label(address(mw), "SubscribeMiddleware");
        uint256 nonce = vm.getNonce(address(this));
        ERC1967Proxy proxy;
        (proxy, authority, boxAddress, profileAddress) = LibDeploy.deploy(
            address(this),
            nonce,
            // address(0),
            ""
        );
        engine = CyberEngine(address(proxy));

        TestLibFixture.auth(authority);
        vm.prank(TestLibFixture._GOV);
        engine.allowSubscribeMw(address(mw), true);
        bobProfileId = TestLibFixture.registerBobProfile(engine);
        // set module
        vm.prank(bob);
        engine.setSubscribeMw(bobProfileId, address(mw));
    }

    function testSubscribeOnlyOnce() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = bobProfileId;
        bytes[] memory data = new bytes[](1);

        vm.expectEmit(true, true, false, true);
        emit DeploySubscribeNFT(
            bobProfileId,
            address(0xF5ACE15da8E86BC4366CA0cD34e23230fbee44c2)
        );

        vm.expectEmit(true, false, false, true);
        emit Subscribe(alice, ids, data);

        vm.prank(alice);
        engine.subscribe(ids, data);

        // Second subscribe will fail
        vm.expectRevert("Already subscribed");
        vm.prank(alice);
        engine.subscribe(ids, data);
    }
}
