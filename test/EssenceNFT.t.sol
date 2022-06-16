// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { ICyberEngine } from "../src/interfaces/ICyberEngine.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";
import { UpgradeableBeacon } from "../src/upgradeability/UpgradeableBeacon.sol";
import { EssenceNFT } from "../src/EssenceNFT.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { LibString } from "../src/libraries/LibString.sol";
import { Constants } from "../src/libraries/Constants.sol";
import { RolesAuthority } from "../src/base/RolesAuthority.sol";
import { Auth, Authority } from "../src/base/Auth.sol";

contract EssenceNFTTest is Test {
    UpgradeableBeacon internal beacon;
    EssenceNFT internal impl;
    BeaconProxy internal proxy;
    address internal engine = address(0xC0DE);
    address internal profile = address(0xDEAD);

    RolesAuthority internal rolesAuthority;
    EssenceNFT internal c;

    uint256 internal profileId = 1;
    uint256 internal essenceId = 101;
    address constant alice = address(0xA11CE);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );

        impl = new EssenceNFT(address(engine), profile);
        // engine.setEssenceNFTImpl(address(impl));
        beacon = new UpgradeableBeacon(
            address(impl),
            address(0),
            rolesAuthority
        );
        bytes memory functionData = abi.encodeWithSelector(
            EssenceNFT.initialize.selector,
            profileId,
            essenceId
        );
        proxy = new BeaconProxy(address(beacon), functionData);

        rolesAuthority.setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(beacon),
            Constants._UPGRADE_TO,
            true
        );

        c = EssenceNFT(address(proxy));
    }

    function testBasic() public {
        vm.prank(engine);
        c.mint(alice);
        assertEq(c.balanceOf(alice), 1);

        vm.mockCall(
            engine,
            abi.encodeWithSelector(
                ICyberEngine.essenceNFTTokenURI.selector,
                profileId,
                essenceId
            ),
            abi.encode("ipfs://test")
        );
        assertEq(c.tokenURI(1), "ipfs://test");
    }

    function testCannotReinitialize() public {
        vm.expectRevert("Contract already initialized");
        c.initialize(2, 102);
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
        assertEq(c.name(), "alice_essence_101");
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
        assertEq(c.symbol(), "ALICE_ESS_101");
    }
}
