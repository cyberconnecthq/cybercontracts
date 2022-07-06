// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { ICyberEngine } from "../src/interfaces/ICyberEngine.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/core/SubscribeNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/dependencies/solmate/RolesAuthority.sol";
import { Auth, Authority } from "../src/dependencies/solmate/Auth.sol";
import { MockEngine } from "./utils/MockEngine.sol";

contract SubscribeNFTTest is Test {
    UpgradeableBeacon internal beacon;
    SubscribeNFT internal impl;
    BeaconProxy internal proxy;
    MockEngine internal engine;
    address internal profile = address(0xDEAD);

    RolesAuthority internal rolesAuthority;
    SubscribeNFT internal c;

    uint256 internal profileId = 1;
    address constant alice = address(0xA11CE);
    address constant bob = address(0xB0B);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );

        engine = new MockEngine();
        impl = new SubscribeNFT(address(engine), profile);
        beacon = new UpgradeableBeacon(address(impl), address(engine));
        bytes memory functionData = abi.encodeWithSelector(
            SubscribeNFT.initialize.selector,
            profileId
        );
        proxy = new BeaconProxy(address(beacon), functionData);

        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(beacon),
            Constants._BEACON_UPGRADE_TO,
            true
        );

        c = SubscribeNFT(address(proxy));
    }

    function testBasic() public {
        vm.prank(address(engine));
        assertEq(c.mint(alice), 1);
        assertEq(c.tokenURI(1), "1");
    }

    function testCannotReinitialize() public {
        vm.expectRevert("Contract already initialized");
        c.initialize(2);
    }

    function testName() public {
        vm.mockCall(
            profile,
            abi.encodeWithSelector(
                IProfileNFT.getHandleByProfileId.selector,
                1
            ),
            abi.encode("alice")
        );
        assertEq(c.name(), "alice_subscriber");
    }

    function testSymbol() public {
        vm.mockCall(
            profile,
            abi.encodeWithSelector(
                IProfileNFT.getHandleByProfileId.selector,
                1
            ),
            abi.encode("alice")
        );
        assertEq(c.symbol(), "ALICE_SUB");
    }

    function testCannotMintFromNonEngine() public {
        vm.expectRevert("Only Engine could mint");
        c.mint(alice);
    }

    function testTransferIsNotAllowed() public {
        vm.prank(address(engine));
        c.mint(alice);
        vm.expectRevert("Transfer is not allowed");
        c.transferFrom(alice, bob, 1);
        vm.expectRevert("Transfer is not allowed");
        c.safeTransferFrom(alice, bob, 1);
        vm.expectRevert("Transfer is not allowed");
        c.safeTransferFrom(alice, bob, 1, "");
    }

    function testReturnTokenId() public {
        vm.startPrank(address(engine));
        assertEq(c.mint(alice), 1);
        assertEq(c.mint(alice), 2);
        assertEq(c.mint(alice), 3);
    }
}


