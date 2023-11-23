pragma solidity 0.8.19;
/// @dev 0.8.20 set's the default EVM version to shanghai and uses push0. That's not supported on L2s

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IERC4626} from "../interfaces/vault/IAdapter.sol";

struct Lock {
    uint unlockTime;
    uint rewardIndex;
    uint amount;
    uint rewardShares;
}

contract StakingVault is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    ERC20 public immutable asset;
    ERC20 public immutable rewardToken;
    IERC4626 public immutable strategy;

    uint public immutable MAX_LOCK_TIME;
    address public constant PROTOCOL_FEE_RECIPIENT =
        0x47fd36ABcEeb9954ae9eA1581295Ce9A8308655E;
    uint public constant PROTOCOL_FEE = 10;

    uint protocolFees;

    mapping(address => Lock) public locks;
    mapping(address => uint) public accruedRewards;

    uint public totalRewardSupply;
    uint public currIndex;

    event LockCreated(address indexed user, uint amount, uint lockTime);
    event Withdrawal(address indexed user, uint amount);
    event IncreaseLockTime(address indexed user, uint newLockTime);
    event IncreaseLockAmount(address indexed user, uint amount);
    event Claimed(address indexed user, uint amount);
    event DistributeRewards(address indexed distributor, uint amount);

    constructor(
        address _asset,
        uint _maxLockTime,
        address _rewardToken,
        address _strategy,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, ERC20(_asset).decimals()) {
        asset = ERC20(_asset);
        MAX_LOCK_TIME = _maxLockTime;

        rewardToken = ERC20(_rewardToken);

        strategy = IERC4626(_strategy);
        ERC20(_asset).approve(_strategy, type(uint).max);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function toRewardShares(
        uint amount,
        uint lockTime
    ) public view returns (uint) {
        require(lockTime <= MAX_LOCK_TIME, "LOCK_TIME");
        return amount.mulDivDown(lockTime, MAX_LOCK_TIME);
    }

    function toShares(uint amount) public view returns (uint) {
        return strategy.previewDeposit(amount) / 1e9;
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function deposit(
        address recipient,
        uint amount,
        uint lockTime
    ) external returns (uint shares) {
        require(locks[recipient].unlockTime == 0, "LOCK_EXISTS");

        uint rewardShares;
        (shares, rewardShares) = _getShares(amount, lockTime);

        asset.safeTransferFrom(msg.sender, address(this), amount);

        strategy.deposit(amount, address(this));

        _mint(recipient, shares);

        locks[recipient] = Lock({
            unlockTime: block.timestamp + lockTime,
            rewardIndex: currIndex,
            amount: amount,
            rewardShares: rewardShares
        });

        totalRewardSupply += rewardShares;

        emit LockCreated(recipient, amount, lockTime);
    }

    function withdraw(
        address owner,
        address recipient
    ) external returns (uint amount) {
        uint shares = balanceOf[owner];

        require(shares != 0, "NO_LOCK");
        require(block.timestamp > locks[owner].unlockTime, "LOCKED");

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[owner][msg.sender] = allowed - shares;
        }

        accrueUser(owner);

        amount = shares.mulDivDown(
            strategy.balanceOf(address(this)),
            totalSupply
        );

        _burn(owner, shares);

        totalRewardSupply -= locks[owner].rewardShares;

        delete locks[owner];

        strategy.redeem(amount, recipient, address(this));

        emit Withdrawal(owner, amount);
    }

    function _getShares(
        uint amount,
        uint lockTime
    ) internal returns (uint shares, uint rewardShares) {
        shares = toShares(amount);
        rewardShares = toRewardShares(amount, lockTime);
        require(shares > 0 && rewardShares > 0, "NO_SHARES");
    }

    /*//////////////////////////////////////////////////////////////
                            LOCK MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function increaseLockAmount(address recipient, uint amount) external {
        accrueUser(recipient);

        uint currAmount = locks[recipient].amount;
        require(currAmount != 0, "NO_LOCK");

        (uint shares, uint newRewardShares) = _getShares(
            amount,
            locks[recipient].unlockTime - block.timestamp
        );

        asset.safeTransferFrom(msg.sender, address(this), amount);

        strategy.deposit(amount, address(this));

        _mint(recipient, shares);

        locks[recipient].amount += amount;
        locks[recipient].rewardShares += newRewardShares;

        totalRewardSupply += newRewardShares;

        emit IncreaseLockAmount(recipient, amount);
    }

    function increaseLockTime(uint newLockTime) external {
        accrueUser(msg.sender);

        uint amount = locks[msg.sender].amount;
        require(amount != 0, "NO_LOCK");
        require(
            newLockTime + block.timestamp > locks[msg.sender].unlockTime,
            "INCREASE_LOCK_TIME"
        );

        uint newRewardShares = toRewardShares(
            locks[msg.sender].amount,
            newLockTime
        );

        totalRewardSupply += (newRewardShares - locks[msg.sender].rewardShares);

        locks[msg.sender].unlockTime = block.timestamp + newLockTime;
        locks[msg.sender].rewardShares = newRewardShares;

        emit IncreaseLockTime(msg.sender, newLockTime);
    }

    /*//////////////////////////////////////////////////////////////
                            REWARDS LOGIC
    //////////////////////////////////////////////////////////////*/

    function distributeRewards(uint amount) external {
        uint fee = (amount * PROTOCOL_FEE) / 10_000;
        protocolFees += fee;

        // amount of reward tokens that will be distributed per share
        uint delta = (amount - fee).mulDivDown(
            10 ** decimals,
            totalRewardSupply
        );

        /// @dev if delta == 0, no one will receive any rewards.
        require(delta != 0, "LOW_AMOUNT");

        currIndex += delta;

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        emit DistributeRewards(msg.sender, amount);
    }

    function accrueUser(address user) public {
        uint rewardShares = locks[user].rewardShares;
        if (rewardShares == 0) return;

        uint userIndex = locks[user].rewardIndex;

        uint delta = currIndex - userIndex;

        locks[user].rewardIndex = currIndex;
        accruedRewards[user] += (rewardShares * delta) / (10 ** decimals);
    }

    function claim(address user) external {
        accrueUser(user);

        uint rewards = accruedRewards[user];
        require(rewards != 0, "NO_REWARDS");

        accruedRewards[user] = 0;

        rewardToken.safeTransfer(user, rewards);

        emit Claimed(msg.sender, rewards);
    }

    /*//////////////////////////////////////////////////////////////
                            FEE LOGIC
    //////////////////////////////////////////////////////////////*/

    function claimProtocolFees() external {
        uint amount = protocolFees;

        delete protocolFees;

        rewardToken.safeTransfer(PROTOCOL_FEE_RECIPIENT, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        revert("NO TRANSFER");
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        revert("NO TRANSFER");
    }
}
