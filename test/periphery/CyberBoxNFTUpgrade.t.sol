// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { ICyberBoxEvents } from "../../src/interfaces/ICyberBoxEvents.sol";

import { Constants } from "../../src/libraries/Constants.sol";

import { MockCyberBoxV2 } from "../utils/MockCyberBoxV2.sol";
import { CyberBoxNFT } from "../../src/periphery/CyberBoxNFT.sol";

contract CyberBoxNFTUpgradeTest is Test, ICyberBoxEvents {
    CyberBoxNFT internal cyberBox;
    address constant owner = address(0xe);

    function setUp() public {
        CyberBoxNFT impl = new CyberBoxNFT();
        bytes memory data = abi.encodeWithSelector(
            CyberBoxNFT.initialize.selector,
            owner,
            "TestBox",
            "TB"
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        cyberBox = CyberBoxNFT(address(proxy));
    }

    function testCannotUpgradeToAndCallAsNonOwner() public {
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
        MockCyberBoxV2 implV2 = new MockCyberBoxV2();

        vm.expectRevert("UNAUTHORIZED");
        CyberBoxNFT(address(cyberBox)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockCyberBoxV2.version.selector)
        );
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
    }

    function testCannotUpgradeAsNonOwner() public {
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
        MockCyberBoxV2 implV2 = new MockCyberBoxV2();

        vm.expectRevert("UNAUTHORIZED");
        CyberBoxNFT(address(cyberBox)).upgradeTo(address(implV2));
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
    }

    function testUpgrade() public {
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
        MockCyberBoxV2 implV2 = new MockCyberBoxV2();

        vm.prank(owner);
        CyberBoxNFT(address(cyberBox)).upgradeTo(address(implV2));
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 2);
    }

    function testUpgradeToAndCall() public {
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 1);
        MockCyberBoxV2 implV2 = new MockCyberBoxV2();

        vm.prank(owner);
        CyberBoxNFT(address(cyberBox)).upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(MockCyberBoxV2.version.selector)
        );
        assertEq(CyberBoxNFT(address(cyberBox)).version(), 2);
    }
}
