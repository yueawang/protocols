pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

// import "../../lib/BurnableERC20.sol";
// import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ERC20.sol";

import "../../iface/IAuctionData.sol";

/// @title AuctionBidAsk.
/// @author Daniel Wang  - <daniel@loopring.org>
library AuctionBidAsk
{
    using MathUint for uint;
    using MathUint for uint32;

    function getAuctionInfo(
            IAuctionData.State storage s
        )
        internal
        view
        returns (IAuctionData.Info memory i)
    {
        i.askAmount = s.askAmount;
        i.bidAmount = s.bidAmount;
        i.queuedAskAmount = s.queueIsBid ? 0 : s.queueAmount;
        i.queuedBidAmount = s.queueIsBid ?  s.queueAmount: 0;

        if (s.askAmount > 0) {
            i.actualPrice  = s.bidAmount.mul(s.S) / s.askAmount;
            i.bounded = i.actualPrice >= s.P / s.M && i.actualPrice <= s.P.mul(s.M);
        }

        require(i.bounded || (s.askShift == 0 && s.bidShift == 0), "unbound shift");

        uint span;

        // calculating asks
        span = block.timestamp.sub(s.startTime).sub(s.askShift);
        i.askPrice = s.curve.getCurveValue(s.P, s.S, s.M, s.T, span);
        i.newAskShift = s.askShift;
        i.additionalBidAmountAllowed = ~uint256(0); // = uint.MAX

        if (i.bounded) {
            if (i.actualPrice > i.askPrice) {
                i.newAskShift = span
                    .add(s.askShift)
                    .sub(s.curve.getCurveTime(
                        s.P, s.S, s.M, s.T,
                        i.actualPrice
                    ));
                i.askPrice = i.actualPrice;
                i.additionalBidAmountAllowed = 0;
            } else {
                i.additionalBidAmountAllowed = (
                    s.askAmount.add(i.queuedAskAmount).mul(i.askPrice ) / s.S
                ).sub(s.bidAmount);
            }
        }

        // calculating bids
        span = block.timestamp.sub(s.startTime).sub(s.bidShift);
        i.bidPrice = s.P.mul(s.P) / s.S / s.curve.getCurveValue(s.P, s.S, s.M, s.T, span);
        i.newBidShift = s.bidShift;
        i.additionalBidAmountAllowed = ~uint256(0); // = uint.MAX

        if (i.bounded) {
            if (i.actualPrice < i.bidPrice) {
                i.newAskShift = span
                    .add(s.bidShift)
                    .sub(s.curve.getCurveTime(
                        s.P, s.S, s.M, s.T,
                        s.askAmount.mul(s.P).mul(s.P) / s.bidAmount
                    ));
                i.bidPrice = i.actualPrice;
                i.additionalAskAmountAllowed = 0;
            } else {
                i.additionalAskAmountAllowed = (
                    s.askAmount.add(i.queuedBidAmount).mul(i.bidPrice) / s.S
                ).sub(s.bidAmount);
            }
        }

        if (s.queueAmount > 0) {
            require(s.queueIsBid || i.additionalAskAmountAllowed == 0);
            require(!s.queueIsBid || i.additionalBidAmountAllowed == 0);
        }
    }

    function depositToken(
        IAuctionData.State storage s,
        address token,
        uint    amount
        )
        internal
        returns (uint _amount)
    {
        assert(token != address(0x0));

        ERC20 erc20 = ERC20(token);
        _amount = amount
            .min(erc20.balanceOf(msg.sender))
            .min(erc20.allowance(msg.sender, address(s.oedax)));

        require(_amount > 0, "zero amount");

        require(
            s.oedax.transferToken(token, msg.sender, _amount),
            "token transfer failed"
        );
    }
}