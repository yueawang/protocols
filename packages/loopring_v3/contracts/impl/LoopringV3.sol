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

import "../iface/ILoopringV3.sol";
import "../iface/IExchange.sol";

import "../lib/AddressUtil.sol";
import "../lib/BurnableERC20.sol";
import "../lib/ERC20SafeTransfer.sol";
import "../lib/MathUint.sol";

import "./ExchangeV3Deployer.sol";


/// @title LoopringV3
/// @dev This contract does NOT support proxy.
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
contract LoopringV3 is ILoopringV3
{
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;

    // -- Constructor --
    constructor(
        address _lrcAddress,
        address _wethAddress,
        address payable _protocolFeeVault,
        address _blockVerifierAddress
        )
        Claimable()
        public
    {
        require(address(0) != _lrcAddress, "ZERO_ADDRESS");
        require(address(0) != _wethAddress, "ZERO_ADDRESS");

        lrcAddress = _lrcAddress;
        wethAddress = _wethAddress;

        updateSettingsInternal(
            _protocolFeeVault,
            _blockVerifierAddress,
            0, 0, 0, 0, 0, 0, 0, 0, 0
        );
    }

    // === ILoopring methods ===
    function deployExchange()
        external
        nonReentrant
        returns (address)
    {
        return ExchangeV3Deployer.deploy();
    }

    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external
        nonReentrant
    {
        require(exchangeAddress != address(0), "ZERO_ADDRESS");
        require(exchangeId != 0, "INVALID_EXCHANGE_ID");
        require(owner != address(0), "ZERO_ADDRESS");
        require(operator != address(0), "ZERO_ADDRESS");
        require(exchanges[exchangeId].exchangeAddress == address(0), "ID_USED_ALREADY");

        // Burn the LRC
        if (exchangeCreationCostLRC > 0) {
            require(
                BurnableERC20(lrcAddress).burnFrom(owner, exchangeCreationCostLRC),
                "BURN_FAILURE"
            );
        }

        IExchange exchange = IExchange(exchangeAddress);

        // If the exchange has already been initlaized, the following function will fail.
        exchange.initialize(
            address(this),
            owner,
            exchangeId,
            operator,
            onchainDataAvailability
        );

        exchanges[exchangeId] = Exchange(exchangeAddress, 0, 0);

        emit ExchangeRegistered(
            exchangeId,
            exchangeAddress,
            owner,
            operator,
            exchangeCreationCostLRC
        );
    }

    // == Public Functions ==
    function updateSettings(
        address payable _protocolFeeVault,
        address _blockVerifierAddress,
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _downtimePriceLRCPerMinute,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external
        onlyOwner
    {
        updateSettingsInternal(
            _protocolFeeVault,
            _blockVerifierAddress,
            _exchangeCreationCostLRC,
            _maxWithdrawalFee,
            _downtimePriceLRCPerMinute,
            _tokenRegistrationFeeLRCBase,
            _tokenRegistrationFeeLRCDelta,
            _minExchangeStakeWithDataAvailability,
            _minExchangeStakeWithoutDataAvailability,
            _revertFineLRC,
            _withdrawalFineLRC
        );
    }

    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external
        onlyOwner
    {
        minProtocolTakerFeeBips = _minProtocolTakerFeeBips;
        maxProtocolTakerFeeBips = _maxProtocolTakerFeeBips;
        minProtocolMakerFeeBips = _minProtocolMakerFeeBips;
        maxProtocolMakerFeeBips = _maxProtocolMakerFeeBips;
        targetProtocolTakerFeeStake = _targetProtocolTakerFeeStake;
        targetProtocolMakerFeeStake = _targetProtocolMakerFeeStake;

        emit SettingsUpdated(now);
    }

    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool)
    {
        uint amountStaked = getExchangeStake(exchangeId);
        if (onchainDataAvailability) {
            return amountStaked >= minExchangeStakeWithDataAvailability;
        } else {
            return amountStaked >= minExchangeStakeWithoutDataAvailability;
        }
    }

    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint exchangeStake)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        exchangeStake = exchange.exchangeStake;
    }

    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        public
        nonReentrant
        returns (uint burnedLRC)
    {
        Exchange storage exchange = exchanges[exchangeId];
        address exchangeAddress = exchange.exchangeAddress;

        require(exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchangeAddress == msg.sender, "UNAUTHORIZED");

        burnedLRC = exchange.exchangeStake;

        if (amount < burnedLRC) {
            burnedLRC = amount;
        }
        if (burnedLRC > 0) {
            require(
                BurnableERC20(lrcAddress).burn(burnedLRC),
                "BURN_FAILURE"
            );

            exchange.exchangeStake = exchange.exchangeStake.sub(burnedLRC);
            totalStake = totalStake.sub(burnedLRC);
        }
        emit ExchangeStakeBurned(exchangeId, burnedLRC);
    }

    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        nonReentrant
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");
        require(
            lrcAddress.safeTransferFrom(msg.sender, address(this), amountLRC),
            "TRANSFER_FAILURE"
        );

        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

        stakedLRC = exchange.exchangeStake.add(amountLRC);
        exchange.exchangeStake = stakedLRC;
        totalStake = totalStake.add(amountLRC);

        emit ExchangeStakeDeposited(exchangeId, amountLRC);
    }

    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        public
        nonReentrant
        returns (uint amountLRC)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchange.exchangeAddress == msg.sender, "UNAUTHORIZED");

        amountLRC = (exchange.exchangeStake > requestedAmount) ?
            requestedAmount : exchange.exchangeStake;

        if (amountLRC > 0) {
            require(
                lrcAddress.safeTransfer(recipient, amountLRC),
                "WITHDRAWAL_FAILURE"
            );
            exchange.exchangeStake = exchange.exchangeStake.sub(amountLRC);
            totalStake = totalStake.sub(amountLRC);
        }

        emit ExchangeStakeWithdrawn(exchangeId, amountLRC);
    }

    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        nonReentrant
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");
        require(
            lrcAddress.safeTransferFrom(msg.sender, address(this), amountLRC),
            "TRANSFER_FAILURE"
        );

        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

        stakedLRC = exchange.protocolFeeStake.add(amountLRC);
        exchange.protocolFeeStake = stakedLRC;
        totalStake = totalStake.add(amountLRC);

        emit ProtocolFeeStakeDeposited(exchangeId, amountLRC);
    }

    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amountLRC
        )
        external
        nonReentrant
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        require(exchange.exchangeAddress == msg.sender, "UNAUTHORIZED");
        require(amountLRC <= exchange.protocolFeeStake, "INSUFFICIENT_STAKE");

        if (amountLRC > 0) {
            require(
                lrcAddress.safeTransfer(recipient, amountLRC),
                "WITHDRAWAL_FAILURE"
            );
            exchange.protocolFeeStake = exchange.protocolFeeStake.sub(amountLRC);
            totalStake = totalStake.sub(amountLRC);
        }
        emit ProtocolFeeStakeWithdrawn(exchangeId, amountLRC);
    }

    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        )
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");

        // Subtract the minimum exchange stake, this amount cannot be used to reduce the protocol fees
        uint stake = 0;
        if (onchainDataAvailability && exchange.exchangeStake > minExchangeStakeWithDataAvailability) {
            stake = exchange.exchangeStake - minExchangeStakeWithDataAvailability;
        } else if (!onchainDataAvailability && exchange.exchangeStake > minExchangeStakeWithoutDataAvailability) {
            stake = exchange.exchangeStake - minExchangeStakeWithoutDataAvailability;
        }

        // The total stake used here is the exchange stake + the protocol fee stake, but
        // the protocol fee stake has a reduced weight of 50%.
        uint protocolFeeStake = stake.add(exchange.protocolFeeStake / 2);

        takerFeeBips = calculateProtocolFee(
            minProtocolTakerFeeBips, maxProtocolTakerFeeBips, protocolFeeStake, targetProtocolTakerFeeStake
        );
        makerFeeBips = calculateProtocolFee(
            minProtocolMakerFeeBips, maxProtocolMakerFeeBips, protocolFeeStake, targetProtocolMakerFeeStake
        );
    }

    function getProtocolFeeStake(
        uint exchangeId
        )
        public
        view
        returns (uint protocolFeeStake)
    {
        Exchange storage exchange = exchanges[exchangeId];
        require(exchange.exchangeAddress != address(0), "INVALID_EXCHANGE_ID");
        return exchange.protocolFeeStake;
    }

    // == Internal Functions ==
    function updateSettingsInternal(
        address payable  _protocolFeeVault,
        address _blockVerifierAddress,
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _downtimePriceLRCPerMinute,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        private
    {
        require(address(0) != _protocolFeeVault, "ZERO_ADDRESS");
        require(address(0) != _blockVerifierAddress, "ZERO_ADDRESS");

        protocolFeeVault = _protocolFeeVault;
        blockVerifierAddress = _blockVerifierAddress;
        exchangeCreationCostLRC = _exchangeCreationCostLRC;
        maxWithdrawalFee = _maxWithdrawalFee;
        downtimePriceLRCPerMinute = _downtimePriceLRCPerMinute;
        tokenRegistrationFeeLRCBase = _tokenRegistrationFeeLRCBase;
        tokenRegistrationFeeLRCDelta = _tokenRegistrationFeeLRCDelta;
        minExchangeStakeWithDataAvailability = _minExchangeStakeWithDataAvailability;
        minExchangeStakeWithoutDataAvailability = _minExchangeStakeWithoutDataAvailability;
        revertFineLRC = _revertFineLRC;
        withdrawalFineLRC = _withdrawalFineLRC;

        emit SettingsUpdated(now);
    }

    function calculateProtocolFee(
        uint minFee,
        uint maxFee,
        uint stake,
        uint targetStake
        )
        internal
        pure
        returns (uint8)
    {
        if (targetStake > 0) {
            // Simple linear interpolation between 2 points
            uint maxReduction = maxFee.sub(minFee);
            uint reduction = maxReduction.mul(stake) / targetStake;
            if (reduction > maxReduction) {
                reduction = maxReduction;
            }
            return uint8(maxFee.sub(reduction));
        } else {
            return uint8(minFee);
        }
    }
}
