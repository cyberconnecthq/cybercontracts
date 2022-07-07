// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import "./utils/MockPausable.sol";
import "forge-std/Test.sol";

contract PausableTest is Test {
    event Paused(address account);
    event Unpaused(address account);

    MockPausable internal pausableContract;

    function setUp() public {
        pausableContract = new MockPausable();
    }

    //unpaused
    function testcanPerformNormalProcessInNonPause() public {
        assertEq(pausableContract.count(), 0);
        pausableContract.normalProcess();
        assertEq(pausableContract.count(), 1);
    }

    function testCannotTakeDrasticMeasureInNonPause() public {
        vm.expectRevert("Pausable: not paused");
        pausableContract.drasticMeasure();
    }

    //paused
    function testEmitPauseEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Paused(address(this));
        pausableContract.pause();
    }

    function testCannotPerformNormalProcessInPause() public {
        pausableContract.pause();
        vm.expectRevert("Pausable: paused");
        pausableContract.normalProcess();
    }

    function testCanTakeADrasticMeasureInAPause() public {
        pausableContract.pause();
        pausableContract.drasticMeasure();
        assertEq(pausableContract.drasticMeasureTaken(), true);
    }

    function testCannotRepause() public {
        pausableContract.pause();
        vm.expectRevert("Pausable: paused");
        pausableContract.pause();
    }

    //unpausing
    function testIsUnpausableByThePauser() public {
        pausableContract.pause();
        pausableContract.unpause();
        assertEq(pausableContract.paused(), false);
    }

    function testUnPausedEvent() public {
        pausableContract.pause();
        vm.expectEmit(true, false, false, true);
        emit Unpaused(address(this));
        pausableContract.unpause();
    }

    function shouldResumeAllowingNormalProcess() public {
        pausableContract.pause();
        pausableContract.unpause();
        assertEq(pausableContract.count(), 0);
        pausableContract.normalProcess();
        assertEq(pausableContract.count(), 1);
    }

    function testShouldPreventDrasticMeasure() public {
        pausableContract.pause();
        pausableContract.unpause();
        vm.expectRevert("Pausable: not paused");
        pausableContract.drasticMeasure();
    }

    function testCannotReUnpause() public {
        pausableContract.pause();
        pausableContract.unpause();
        vm.expectRevert("Pausable: not paused");
        pausableContract.unpause();
    }
}
