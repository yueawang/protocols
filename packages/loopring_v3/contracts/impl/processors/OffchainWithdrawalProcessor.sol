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
pragma solidity 0.5.7;

import "../../iface/IBlockProcessor.sol";

/// @title IBlockProcessor
/// @author Freeman Zhong - <kongliang@loopring.org>
contract OffchainWithdrawalProcessor is IBlockProcessor
{
    function processBlock(
        uint16 blockSize,
        uint8  blockVersion,
        bytes calldata data
        )
        external
    {
        uint8 blockType = newBlock.blockType;
        uint16 blockSize = newBlock.blockSize;

        bytes memory withdrawals = new bytes(0);
        uint start = 4 + 32 + 32;
        if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL) {
            start += 32 + 32 + 4 + 4;
        }
        uint length = 7 * blockSize;
        assembly {
            withdrawals := add(data, start)
            mstore(withdrawals, length)
        }

        newBlock.withdrawals = withdrawals;
    }

}
