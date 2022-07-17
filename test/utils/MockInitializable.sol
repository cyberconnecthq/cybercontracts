// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import { Initializable } from "../../src/upgradeability/Initializable.sol";

/**
 * @title MockInitializable
 * @dev This contract is a mock to test initializable functionality
 */
contract MockInitializable is Initializable {
    bool public initializerRan;
    bool public onlyInitializingRan;
    uint256 public x;

    function initialize() public initializer {
        initializerRan = true;
    }

    function initializeOnlyInitializing() public onlyInitializing {
        onlyInitializingRan = true;
    }

    function initializerNested() public initializer {
        initialize();
    }

    function onlyInitializingNested() public initializer {
        initializeOnlyInitializing();
    }

    function initializeWithX(uint256 _x) public payable initializer {
        x = _x;
    }

    function nonInitializable(uint256 _x) public payable {
        x = _x;
    }

    function fail() public pure {
        require(false, "InitializableMock forced failure");
    }
}

contract MockConstructorInitializable is Initializable {
    bool public initializerRan;
    bool public onlyInitializingRan;

    constructor() initializer {
        initialize();
        initializeOnlyInitializing();
    }

    function initialize() public initializer {
        initializerRan = true;
    }

    function initializeOnlyInitializing() public onlyInitializing {
        onlyInitializingRan = true;
    }
}

contract MockChildConstructorInitializable is MockConstructorInitializable {
    bool public childInitializerRan;

    constructor() initializer {
        childInitialize();
    }

    function childInitialize() public initializer {
        childInitializerRan = true;
    }
}

contract DisableNew is Initializable {
    constructor() {
        _disableInitializers();
    }
}

contract DisableOld is Initializable {
    constructor() initializer {}
}

contract DisableBad1 is DisableNew, DisableOld {}

contract DisableBad2 is Initializable {
    constructor() initializer {
        _disableInitializers();
    }
}

contract DisableOk is DisableOld, DisableNew {}
