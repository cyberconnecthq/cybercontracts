// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

contract PaymentMw {
    struct PaymentMethod {
        address currency;
        address recipient;
    }

    mapping(address => PaymentMethod) internal _paymentByNamespace;

    function _setPaymentMethod(
        address profileAddr,
        address currency,
        address recipient
    ) internal {
        _paymentByNamespace[profileAddr] = PaymentMethod(currency, recipient);
    }

    function _getPaymentMethod(address profileAddr)
        internal
        view
        returns (PaymentMethod memory)
    {
        return _paymentByNamespace[profileAddr];
    }
}
