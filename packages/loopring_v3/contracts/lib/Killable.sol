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

import "../lib/Claimable.sol";


/// @title Killable
/// @dev The Killable contract allows the contract owner to suspend, resume or kill the contract
/// @author Brecht Devos - <brecht@loopring.org>
contract Killable is Claimable
{
    bool public suspended = false;

    modifier notSuspended()
    {
        require(!suspended, "INVALID_MODE");
        _;
    }

    modifier isSuspended()
    {
        require(suspended, "INVALID_MODE");
        _;
    }

    function suspend()
        external
        onlyOwner
        notSuspended
    {
        suspended = true;
    }

    function resume()
        external
        onlyOwner
        isSuspended
    {
        suspended = false;
    }

    /// owner must suspend the delegate first before invoking the kill method.
    function kill()
        external
        onlyOwner
        isSuspended
    {
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }
}
