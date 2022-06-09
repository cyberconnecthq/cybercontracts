pragma solidity 0.8.14;

import "../src/ProfileNFT.sol";
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/libraries/Constants.sol";


contract ProfileNFTTest is Test {
    ProfileNFT internal token;
    address constant alice = address(0xA11CE);

    function setUp() public {
        token = new ProfileNFT("TestProfile", "TP", address(this));
        token.setRoleCapability(Constants.MINTER_ROLE, address(token), Constants.CREATE_PROFILE_ID, true);
    }

    function testBasic() public {
        assertEq(token.name(), "TestProfile");
        assertEq(token.symbol(), "TP");
    }

    function testAuth() public {
        assertEq(address(token.authority()), address(token));
        token.createProfile();
    }

    function testMintAsNonMinter() public {
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0));
        token.createProfile();
    }

    function testMintAsMinter() public {
        token.setMinterRole(alice, true);
        vm.prank(alice);
        token.createProfile();
        
    }
}