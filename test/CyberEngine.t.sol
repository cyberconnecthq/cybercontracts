// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "forge-std/Test.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RolesAuthority, Authority } from "../src/dependencies/solmate/RolesAuthority.sol";

import { ICyberEngineEvents } from "../src/interfaces/ICyberEngineEvents.sol";
import { IProfileMiddleware } from "../src/interfaces/IProfileMiddleware.sol";
import { IProfileNFT } from "../src/interfaces/IProfileNFT.sol";

import { Constants } from "../src/libraries/Constants.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";

import { CyberEngine } from "../src/core/CyberEngine.sol";
import { MockEngine } from "./utils/MockEngine.sol";

contract CyberEngineTest is Test, ICyberEngineEvents {
    MockEngine engine;
    RolesAuthority rolesAuthority;
    address constant alice = address(0xA11CE);

    DataTypes.CreateNamespaceParams namespaceParams =
        DataTypes.CreateNamespaceParams(
            "example.com",
            "EXAMPLE",
            address(0),
            DataTypes.ComputedAddresses(
                address(0),
                address(0),
                address(0),
                address(0)
            )
        );

    function setUp() public {
        MockEngine engineImpl = new MockEngine();
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        bytes memory data = abi.encodeWithSelector(
            CyberEngine.initialize.selector,
            address(0),
            rolesAuthority
        );
        vm.expectEmit(true, true, false, true);
        emit Initialize(address(0), address(rolesAuthority));
        ERC1967Proxy engineProxy = new ERC1967Proxy(address(engineImpl), data);

        engine = MockEngine(address(engineProxy));

        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engineProxy),
            CyberEngine.allowProfileMw.selector,
            true
        );
        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engineProxy),
            CyberEngine.allowSubscribeMw.selector,
            true
        );
        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engineProxy),
            CyberEngine.allowEssenceMw.selector,
            true
        );
        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engineProxy),
            CyberEngine.createNamespace.selector,
            true
        );
        RolesAuthority(rolesAuthority).setRoleCapability(
            Constants._ENGINE_GOV_ROLE,
            address(engineProxy),
            CyberEngine.setProfileMw.selector,
            true
        );
    }

    function testAuth() public {
        assertEq(address(engine.authority()), address(rolesAuthority));
    }

    function testCannotAllowSubscribeMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowSubscribeMw(address(0), true);
    }

    function testCannotAllowEssenceMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowEssenceMw(address(0), true);
    }

    function testCannotAllowProfileMwAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.allowProfileMw(address(0), true);
    }

    function testCannotSetProfileMwAsNonOwner() public {
        address namespace = address(0x888);
        address nsOwner = address(0x777);
        engine.setNamespaceInfo("TEST", address(0), namespace);
        vm.mockCall(
            namespace,
            abi.encodeWithSelector(IProfileNFT.getNamespaceOwner.selector),
            abi.encode(nsOwner)
        );
        vm.prank(alice);
        vm.expectRevert("ONLY_NAMESPACE_OWNER");
        engine.setProfileMw(namespace, address(0), new bytes(0));
    }

    function testCannotSetProfileMwInvalidNs() public {
        address namespace = address(0x888);
        address nsOwner = address(0x777);
        vm.mockCall(
            namespace,
            abi.encodeWithSelector(IProfileNFT.getNamespaceOwner.selector),
            abi.encode(nsOwner)
        );
        vm.prank(alice);
        vm.expectRevert("INVALID_NAMESPACE");
        engine.setProfileMw(namespace, address(0), new bytes(0));
    }

    function testCannotCreateNamespaceAsNonGov() public {
        vm.expectRevert("UNAUTHORIZED");
        engine.createNamespace(namespaceParams);
    }

    function testCannotCreateNamespaceInvalidName() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        namespaceParams.name = "AAAAAAAAAAAAAAAAAAAAAAAAAAA";
        vm.expectRevert("NAME_INVALID_LENGTH");
        engine.createNamespace(namespaceParams);
    }

    function testCannotCreateNamespaceInvalidSymbol() public {
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        namespaceParams.symbol = "AAAAAAAAAAAAAAAAAAAAAAAAAAA";
        vm.expectRevert("SYMBOL_INVALID_LENGTH");
        engine.createNamespace(namespaceParams);
    }

    function testAllowSubscribeMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowSubscribeMw(mw, false, true);

        engine.allowSubscribeMw(mw, true);
        assertEq(engine.isSubscribeMwAllowed(mw), true);
    }

    function testAllowEssenceMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowEssenceMw(mw, false, true);

        engine.allowEssenceMw(mw, true);
        assertEq(engine.isEssenceMwAllowed(mw), true);
    }

    function testAllowProfileMwAsGov() public {
        address mw = address(0xCA11);
        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AllowProfileMw(mw, false, true);

        engine.allowProfileMw(mw, true);
        assertEq(engine.isProfileMwAllowed(mw), true);
    }

    function testSetProfileMwAsGov() public {
        address mw = address(0xCA11);
        address namespace = address(0x888);
        address nsOwner = address(0x66666);
        bytes memory data = new bytes(0);
        bytes memory returnData = new bytes(1);

        rolesAuthority.setUserRole(alice, Constants._ENGINE_GOV_ROLE, true);
        vm.prank(alice);

        engine.allowProfileMw(mw, true);

        engine.setNamespaceInfo("TEST", address(0), namespace);
        vm.mockCall(
            namespace,
            abi.encodeWithSelector(IProfileNFT.getNamespaceOwner.selector),
            abi.encode(nsOwner)
        );

        vm.mockCall(
            mw,
            abi.encodeWithSelector(
                IProfileMiddleware.setProfileMwData.selector,
                namespace,
                data
            ),
            abi.encode(returnData)
        );

        vm.prank(nsOwner);
        vm.expectEmit(true, false, false, true);
        emit SetProfileMw(namespace, mw, returnData);
        engine.setProfileMw(namespace, mw, data);
        assertEq(engine.getProfileMwByNamespace(namespace), mw);
    }
}
