// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "forge-std/Test.sol";
import { LibDeploy } from "../../script/libraries/LibDeploy.sol";
import { CyberEngine } from "../../src/core/CyberEngine.sol";
import { RolesAuthority } from "../../src/dependencies/solmate/RolesAuthority.sol";
import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ICyberEngineEvents } from "../../src/interfaces/ICyberEngineEvents.sol";
import { ProfileNFT } from "../../src/core/ProfileNFT.sol";
import { TestLibFixture } from "../utils/TestLibFixture.sol";
import { Base64 } from "../../src/dependencies/openzeppelin/Base64.sol";
import { LibString } from "../../src/libraries/LibString.sol";
import { StaticNFTSVG } from "../../src/libraries/StaticNFTSVG.sol";

contract BaseTest is Test, ICyberEngineEvents {
    CyberEngine engine;
    ProfileNFT profileNFT;
    RolesAuthority authority;
    address boxAddress;
    address profileAddress;
    uint256 bobPk = 1;
    address bob = vm.addr(bobPk);
    uint256 bobProfileId;

    function setUp() public {
        uint256 nonce = vm.getNonce(address(this));
        ERC1967Proxy proxy;
        (proxy, authority, boxAddress, profileAddress) = LibDeploy.deploy(
            address(this),
            nonce,
            ""
        );
        engine = CyberEngine(address(proxy));
        profileNFT = ProfileNFT(profileAddress);
        engine.setAnimationTemplate("https://animation.example.com");
        TestLibFixture.auth(authority);
    }

    function testRegistration() public {
        // Register bob profile
        bobProfileId = TestLibFixture.registerBobProfile(engine);

        // check bob profile details
        string memory handle = profileNFT.getHandleByProfileId(bobProfileId);
        string memory avatar = profileNFT.getAvatar(bobProfileId);
        string memory metadata = profileNFT.getMetadata(bobProfileId);
        assertEq(handle, "bob");
        assertEq(avatar, "avatar");
        assertEq(metadata, "metadata");

        // check bob balance
        assertEq(profileNFT.balanceOf(bob), 1);

        // check bob profile ownership
        assertEq(profileNFT.ownerOf(bobProfileId), bob);

        // check bob profile token uri
        string memory bobUri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"@',
                        handle,
                        '","description":"CyberConnect profile for @',
                        handle,
                        '","image":"',
                        StaticNFTSVG.draw(handle),
                        '","animation_url":"https://animation.example.com?handle=',
                        handle,
                        '","attributes":[{"trait_type":"id","value":"',
                        LibString.toString(bobProfileId),
                        '"},{"trait_type":"length","value":"',
                        LibString.toString(bytes(handle).length),
                        '"},{"trait_type":"subscribers","value":"0"},{"trait_type":"handle","value":"@',
                        handle,
                        '"}]}'
                    )
                )
            )
        );
        assertEq(profileNFT.tokenURI(bobProfileId), bobUri);
    }
}
