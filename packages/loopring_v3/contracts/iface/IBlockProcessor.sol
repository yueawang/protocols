/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity 0.5.10;


/// @title IBlockProcessor
/// @author Daniel Wang - <daniel@loopring.org>
/// @author Kongliang Zhong - <kongliang@loopring.org>

contract IBlockProcessor
{
    address public owner;

    // This method should be called using DELEGATECALL from inside an IExchange contract.
    function processBlock(
        bool   onChainDataAvailability,
        uint16 size,
        uint8  version,
        bytes  calldata data,
        uint32 prevNumDepositRequestsCommitted,
        uint32 prevNumWithdrawalRequestsCommitted
        )
        external
        returns (
            uint32 numDepositRequestsCommitted,
            uint32 numWithdrawalRequestsCommitted,
            bytes  memory withdrawals
        );

    function getVerificationKey(
        uint16 size,
        uint8  version,
        bool   onChainDataAvailability
        )
        external
        view
        returns (uint[18] memory);
}

