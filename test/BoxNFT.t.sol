pragma solidity 0.8.14;

import "../src/BoxNFT.sol";
import "forge-std/Test.sol";
import "solmate/auth/authorities/RolesAuthority.sol";
import "../src/libraries/Constants.sol";

contract BoxNFTTest is Test {
    BoxNFT internal token;
    RolesAuthority internal rolesAuthority;
    address constant alice = address(0xA11CE);

    function setUp() public {
        rolesAuthority = new RolesAuthority(
            address(this),
            Authority(address(0))
        );
        token = new BoxNFT("TestBox", "TB", address(this), rolesAuthority);
        rolesAuthority.setRoleCapability(
            Constants.NFT_MINTER_ROLE,
            address(token),
            Constants.BOX_MINT,
            true
        );
    }

    function testBasic() public {
        assertEq(token.name(), "TestBox");
        assertEq(token.symbol(), "TB");
    }

    function testAuth() public {
        assertEq(address(token.authority()), address(rolesAuthority));
    }

    function testMintAsOwner() public {
        token.mint(alice);
        assertEq(token.balanceOf(alice), 1);
    }

    function testBalanceIncremented() public {
        address bob = address(0xB0B);
        token.mint(alice);
        token.mint(bob);
        assertEq(token.totalSupply(), 2);
    }

    function testCannotMintAsNonMinter() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        token.mint(address(0));
    }

    function testMintAsMinter() public {
        rolesAuthority.setUserRole(alice, Constants.NFT_MINTER_ROLE, true);
        vm.prank(alice);
        token.mint(alice);
        assertEq(token.balanceOf(alice), 1);
    }
}
