// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Price Converter Library
 * @author Guy Robbe
 * @notice This library is used to convert the ETH amount to its equivalent USD amount.
 * @dev The library uses the Chainlink price feed Aggregator interface to get the latest ETH price and calculate the conversion.
 */
library PriceConverter {
    /**
     * @notice Gets the latest ETH price from a price feed
     * @dev The function makes use of the latestRoundData function of the AggregatorV3Interface.
     * @param _priceFeed The price feed to get data from
     * @return The latest ETH price (in USD, with an additional 10 decimal places)
     */
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    /**
     * @notice Gets the conversion rate for a specific ETH amount to its USD equivalent
     * @dev The function uses the getPrice function to get the latest ETH price and then calculates the equivalent USD amount for the provided ETH amount.
     * @param _ethAmount The amount of ETH to convert
     * @param _priceFeed The price feed to get data from
     * @return The equivalent USD amount for the given ETH amount
     */
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}
