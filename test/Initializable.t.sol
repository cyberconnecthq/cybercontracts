// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./utils/MockInitializable.sol";
import "forge-std/Test.sol";

contract InitializableTest is Test {
    MockInitializable internal initializableContract;

    function setUp() public {
        initializableContract = new MockInitializable();
    }

    //basic tests
    function testBeforeInitialize() public {
        assertEq(initializableContract.initializerRan(), false);
    }

    function testAfterInitialize() public {
        initializableContract.initialize();
        assertEq(initializableContract.initializerRan(), true);
    }

    function testFailInitializeRepeatly() public {
        initializableContract.initialize();
        initializableContract.initialize();
    }

    function testFailNestedUnderAnInitializer() public {
        initializableContract.initializerNested();
    }

    function onlyInitializingModifierSucceeds() public {
        initializableContract.onlyInitializingNested();
        assertEq(initializableContract.onlyInitializingRan(), true);
    }

    function testFailInitializingOutScope() public {
        initializableContract.initializeOnlyInitializing();
    }

    function testFailRunDuringConstruction() public {
        new MockConstructorInitializable();
    }

    //disabling initialization
    function testFailBadSequence() public {
        new DisableBad1();
        new DisableBad2();
    }

    function testGoodSequence() public {
        new DisableOk();
    }
}
