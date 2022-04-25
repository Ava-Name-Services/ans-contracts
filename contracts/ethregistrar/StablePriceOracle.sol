pragma solidity >=0.8.4;

import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}


// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    uint[] public rentPrices;

    // Oracle address
       AggregatorV3Interface internal usdOracle;

    event OracleChanged(address oracle);

    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));

        constructor(AggregatorV3Interface _usdOracle, uint[] memory _rentPrices) {
        usdOracle = _usdOracle;
        setPrices(_rentPrices);
    }

    function price(string calldata name, uint expires, uint duration) external view override returns(uint) {
        uint len = name.strlen();
        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);
        
        uint basePrice = rentPrices[len - 1].mul(duration);
        basePrice = basePrice.add(_premium(name, expires, duration));

        return attoUSDToAvax(basePrice);
    }

    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }

    /**
     * @dev Sets the price oracle address
     * @param _usdOracle The address of the price oracle to use.
     */
    function setOracle(AggregatorV3Interface _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint expires, uint duration) external view returns(uint) {
        return attoUSDToAvax(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory name, uint expires, uint duration) virtual internal view returns(uint) {
        return 0;
    }

    function attoUSDToAvax(uint amount) public view returns(uint) {
        (
            /*uint80 roundID*/,
            int avaxPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = usdOracle.latestRoundData();
        return amount.mul(1e8).div(uint256(avaxPrice));
    }

    function avaxToAttoUSD(uint amount) public view returns(uint) {
        (
            /*uint80 roundID*/,
            int avaxPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = usdOracle.latestRoundData();
        return amount.mul(uint256(avaxPrice)).div(1e8);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}