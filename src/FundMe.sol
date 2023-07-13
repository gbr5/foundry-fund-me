// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Custom error to be thrown if someone other than the contract owner tries to call a function.
error FundMe__NotOwner();

/**
 * @title A sample Funding Contract
 * @author Guy Robbe
 * @notice This contract is for creating a sample crowd funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Using the PriceConverter library for uint256 type
    using PriceConverter for uint256;

    // A public constant to represent the minimum USD amount needed for funding
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;

    // Private variables are more gas efficient, so best practices is to make variables private and have a function to retrieve them when needed
    // Also as best practices is that storage variables have s_ in front of them

    // Private state variable to hold the owner's address
    address private immutable s_owner;

    // An array to hold the addresses of all funders
    address[] private s_funders;

    // A mapping to keep track of the amount of funding an address has provided
    mapping(address => uint256) private s_addressToAmountFunded;

    // Instance of the AggregatorV3Interface to interact with the price feed
    AggregatorV3Interface private s_priceFeed;

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert FundMe__NotOwner();
        _;
    }

    /**
     * @dev The constructor sets the price feed address and the contract owner
     * @param _priceFeed The address of the price feed contract
     */
    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        s_owner = msg.sender;
    }

    /**
     * @notice The receive function is a fallback that is called when the contract is sent Ether (without data).
     * @dev It simply calls the fund() function.
     */
    receive() external payable {
        fund();
    }

    /**
     * @notice The fallback function is called when the contract is called without a function signature
     * (i.e., someone just sent Ether) or for function calls that do not match an existing function.
     * @dev It simply calls the fund() function.
     */
    fallback() external payable {
        fund();
    }

    /**
     * @notice Funds the contract and checks if the funding amount is sufficient based on ETH/USD price
     */
    function fund() public payable {
        uint256 minimumUSD = msg.value.getConversionRate(s_priceFeed);
        require(minimumUSD >= MINIMUM_USD, "You need to spend more ETH!");

        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    /**
     * @notice Allows the contract owner to withdraw all funds.
     * @dev Resets all funder's balances to zero.
     */
    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[s_funders[funderIndex]] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = s_owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @notice A cheaper variant of the 'withdraw' function.
     * @dev It uses a local memory array for iterating, thus it consumes less gas.
     */
    function cheaperWithdraw() public onlyOwner {
        address[] memory _funders = s_funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < _funders.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[_funders[funderIndex]] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = s_owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    // Getter functions, they are functions that returns our variables, they should be view or pure
    /**
     * @notice Returns the amount of funds a specific address has provided
     * @param funder The address of the funder
     * @return The amount funded by the address
     */
    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    /**
     * @notice Returns the version of the price feed contract
     * @return The version of the price feed contract
     */
    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * @notice Returns the funder address at a specific index
     * @param index The index of the funder
     * @return The address of the funder
     */
    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    /**
     * @notice Returns the address of the contract owner
     * @return The address of the contract owner
     */
    function getOwner() public view returns (address) {
        return s_owner;
    }

    /**
     * @notice Returns the price feed contract
     * @return The price feed contract
     */
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
