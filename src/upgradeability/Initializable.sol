// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

// Inspired by Openzeppelin's Initializable contract, but simplified for our use case.
// Explicitly removed support for modifier initializer on constructor.
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            isTopLevelCall && _initialized < 1,
            "Contract already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    // For internal base contracts' initialize function
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    // For constructor
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
        }
    }
}
