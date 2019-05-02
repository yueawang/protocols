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

import "../iface/ICurveRegistry.sol";

import "../lib/NoDefaultFunc.sol";

/// @title An Implementation of ICurveRegistry.
/// @author Daniel Wang  - <daniel@loopring.org>
contract CurveRegistry is ICurveRegistry, NoDefaultFunc
{
    function registerCurve(address curve)
        external
        onlyOwner
    {
        require(curveMap[curve] == 0, "already registered");
        curves.push(curve);
        curveMap[curve] = curves.length;

        emit CurveRegistered(curves.length, curve);
    }

    function getCurve(uint id)
        external
        view
        returns (address)
    {
        require(id > 0 && id <= curves.length, "invalid id");
        return curves[id - 1];
    }
}
