// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openZeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 *  MultiSigWallet Contract
 */
contract MultiSigWallet {

    using ECDSA for bytes32;

    address[2] public owners;

    constructor(address[2] memory _owners) payable {
        owners = _owners;
    }

    function deposit() external payable {}

    function transfer(
        address _to,
        uint _amount,
        bytes[2] memory _sigs
    ) external {
        bytes32 txHash = getTxHash(_to, _amount);
        require(_checkSigs(_sigs, txHash), "invalid sig");

        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * get txHash function
     * keccak256 + abiencodPacked
     */
    function getTxHash(address _to, uint _amount) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount));
    }

    /**
     * check sig
     */
    function _checkSigs(bytes[2] memory _sigs, bytes32 _txHash)
        private
        view
        returns (bool)
    {
        bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();

        for (uint i = 0; i < _sigs.length; i++) {
            address signer = ethSignedHash.recover(_sigs[i]);
            bool valid = signer == owners[i];

            if (!valid) {
                return false;
            }
        }

        return true;
    }
}
