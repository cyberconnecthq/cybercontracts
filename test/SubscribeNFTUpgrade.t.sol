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
import { MockSubscribeNFTV2 } from "./utils/MockSubscribeNFTV2.sol";

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

contract SubscribeNFTUpgradeTest is Test {
    UpgradeableBeacon internal beacon;
    SubscribeNFT internal impl;
    BeaconProxy internal proxy;
    BeaconProxy internal proxyB;
    MockEngine internal engine;
    address internal profile = address(0xDEAD);

    uint256 internal profileId = 1;
    address constant alice = address(0xA11CE);

    function setUp() public {
        engine = new MockEngine();
        impl = new SubscribeNFT(address(engine), profile);
        engine.setSubscribeNFTImpl(address(impl));
        beacon = new UpgradeableBeacon(address(impl), address(engine));
        bytes memory functionData = abi.encodeWithSelector(
            SubscribeNFT.initialize.selector,
            profileId
        );
        proxy = new BeaconProxy(address(beacon), functionData);
        proxyB = new BeaconProxy(address(beacon), functionData);
    }

    function testAuth() public {
        assertEq(beacon.ENGINE(), address(engine));
    }

    function testUpgrade() public {
        MockSubscribeNFTV2 implB = new MockSubscribeNFTV2(
            address(engine),
            profile
        );

        assertEq(SubscribeNFT(address(proxy)).version(), 1);
        assertEq(SubscribeNFT(address(proxyB)).version(), 1);

        vm.prank(address(engine));
        beacon.upgradeTo(address(implB));

        MockSubscribeNFTV2 p = MockSubscribeNFTV2(address(proxy));
        MockSubscribeNFTV2 pB = MockSubscribeNFTV2(address(proxyB));

        assertEq(p.version(), 2);
        assertEq(pB.version(), 2);
    }
}
