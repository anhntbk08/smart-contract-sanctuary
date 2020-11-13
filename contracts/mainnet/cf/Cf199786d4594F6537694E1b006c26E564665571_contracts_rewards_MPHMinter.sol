pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libs/DecMath.sol";
import "./MPHToken.sol";

contract MPHMinter is Ownable {
    using Address for address;
    using DecMath for uint256;
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    /**
        @notice The multiplier applied to the interest generated by a pool when minting MPH
     */
    mapping(address => uint256) public poolMintingMultiplier;
    /**
        @notice The multiplier applied to the interest generated by a pool when letting depositors keep MPH
     */
    mapping(address => uint256) public poolDepositorRewardMultiplier;
    /**
        @notice The multiplier applied to the interest generated by a pool when letting deficit funders keep MPH
     */
    mapping(address => uint256) public poolFunderRewardMultiplier;
    /**
        @notice Multiplier used for calculating dev reward
     */
    uint256 public devRewardMultiplier;

    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event ESetParamUint(
        address indexed sender,
        string indexed paramName,
        uint256 newValue
    );

    /**
        External contracts
     */
    MPHToken public mph;
    address public govTreasury;
    address public devWallet;

    constructor(
        address _mph,
        address _govTreasury,
        address _devWallet,
        uint256 _devRewardMultiplier
    ) public {
        mph = MPHToken(_mph);
        govTreasury = _govTreasury;
        devWallet = _devWallet;
        devRewardMultiplier = _devRewardMultiplier;
    }

    function mintDepositorReward(address to, uint256 interestAmount)
        external
        returns (uint256)
    {
        uint256 multiplier = poolMintingMultiplier[msg.sender];
        uint256 mintAmount = interestAmount.decmul(multiplier);
        if (mintAmount == 0) {
            // sender is not a pool/has been deactivated
            return 0;
        }

        mph.ownerMint(to, mintAmount);
        mph.ownerMint(devWallet, mintAmount.decmul(devRewardMultiplier));
        return mintAmount;
    }

    function mintFunderReward(address to, uint256 interestAmount)
        external
        returns (uint256)
    {
        uint256 multiplier = poolMintingMultiplier[msg.sender].decmul(
            poolFunderRewardMultiplier[msg.sender]
        );
        uint256 mintAmount = interestAmount.decmul(multiplier);
        if (mintAmount == 0) {
            // sender is not a pool/has been deactivated
            return 0;
        }

        mph.ownerMint(to, mintAmount);
        mph.ownerMint(devWallet, mintAmount.decmul(devRewardMultiplier));
        return mintAmount;
    }

    function takeBackDepositorReward(
        address from,
        uint256 mintMPHAmount,
        bool early
    ) external returns (uint256) {
        uint256 takeBackAmount = early
            ? mintMPHAmount
            : mintMPHAmount.decmul(
                PRECISION.sub(poolDepositorRewardMultiplier[msg.sender])
            );
        if (takeBackAmount == 0) {
            // sender is not a pool/has been deactivated
            return 0;
        }

        mph.ownerTransfer(from, govTreasury, takeBackAmount);
        return takeBackAmount;
    }

    /**
        Param setters
     */
    function setGovTreasury(address newValue) external onlyOwner {
        require(newValue != address(0), "MPHMinter: 0 address");
        govTreasury = newValue;
        emit ESetParamAddress(msg.sender, "govTreasury", newValue);
    }

    function setDevWallet(address newValue) external onlyOwner {
        require(newValue != address(0), "MPHMinter: 0 address");
        devWallet = newValue;
        emit ESetParamAddress(msg.sender, "devWallet", newValue);
    }

    function setPoolMintingMultiplier(address pool, uint256 newMultiplier)
        external
        onlyOwner
    {
        require(pool.isContract(), "MPHMinter: pool not contract");
        poolMintingMultiplier[pool] = newMultiplier;
        emit ESetParamUint(msg.sender, "poolMintingMultiplier", newMultiplier);
    }

    function setPoolDepositorRewardMultiplier(
        address pool,
        uint256 newMultiplier
    ) external onlyOwner {
        require(pool.isContract(), "MPHMinter: pool not contract");
        require(newMultiplier <= PRECISION, "MPHMinter: invalid multiplier");
        poolDepositorRewardMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardMultiplier",
            newMultiplier
        );
    }

    function setPoolFunderRewardMultiplier(address pool, uint256 newMultiplier)
        external
        onlyOwner
    {
        require(pool.isContract(), "MPHMinter: pool not contract");
        poolFunderRewardMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolFunderRewardMultiplier",
            newMultiplier
        );
    }
}
