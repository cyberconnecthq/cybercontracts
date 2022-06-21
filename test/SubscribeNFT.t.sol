// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { ICyberEngine } from "../src/interfaces/ICyberEngine.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { SubscribeNFT } from "../src/SubscribeNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { LibString } from "../src/libraries/LibString.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Auth, Authority } from "../src/base/Auth.sol";

contract MockEngine is ICyberEngine {
    address public subscribeNFTImpl;

    function setSubscribeNFTImpl(address _subscribeNFTImpl) public {
        subscribeNFTImpl = _subscribeNFTImpl;
    }

    function subscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory)
    {
        return LibString.toString(profileId);
    }
}

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
        engine.setSubscribeNFTImpl(address(impl));
        beacon = new UpgradeableBeacon(
            address(impl),
            address(0),
            rolesAuthority
        );
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
        c.mint(alice);
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
}
