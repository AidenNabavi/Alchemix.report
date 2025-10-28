// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;


import {MYTStrategy} from "./MYTStrategy.sol";
import {IERC4626} from "../lib/IERC4626.sol";
import {IMainRewarder, IAutopilotRouter} from "../lib/ITokemac.sol";
import {TokenUtils} from "../lib/TokenUtils.sol";

interface IERC4626Like is IERC4626 {
    function balanceOfActual(address account) external view returns (uint256);
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface RootOracle {
    function getPriceInEth(address token) external returns (uint256 price);
}

/**
 * @title TokeAutoEthStrategy
 * @notice This strategy is used to allocate and deallocate autoEth to the TokeAutoEth vault on Mainnet
 * @notice Also stakes all amounts allocated to the shares in the rewarder
 */
contract TokeAutoEthStrategy is MYTStrategy {
    IERC4626Like public immutable autoEth;
    IAutopilotRouter public immutable router;
    IMainRewarder public immutable rewarder;
    WETH public immutable weth;
    RootOracle public immutable oracle;
    address public immutable rewardToken;

    event TokeAutoETHStrategyTestLog(string message, uint256 value);

    constructor(
        address _myt,
        StrategyParams memory _params,
        address _autoEth,
        address _router,
        address _rewarder,
        address _weth,
        address _oracle,
        address _permit2Address
    ) MYTStrategy(_myt, _params, _permit2Address, _autoEth) {
        autoEth = IERC4626Like(_autoEth);
        router = IAutopilotRouter(_router);
        rewarder = IMainRewarder(_rewarder);
        weth = WETH(_weth);
        oracle = RootOracle(_oracle);
    }

    ///@dev Implementation can alternatively make use of a multicall
    // Deposit weth into the autoEth vault, stake the shares in the rewarder

    function _allocate(uint256 amount) internal override returns (uint256) {
        require(TokenUtils.safeBalanceOf(address(weth), address(this)) >= amount, "Strategy balance is less than amount");
        TokenUtils.safeApprove(address(weth), address(router), amount);
        uint256 shares = router.depositMax(autoEth, address(this), 0);
        TokenUtils.safeApprove(address(autoEth), address(rewarder), shares);
        rewarder.stake(address(this), shares);
        return amount;
    }



    // Withdraws auto eth shares from the rewarder with any claims
    // redeems same amount of shares from auto eth vault to weth


    function _deallocate(uint256 amount) internal override returns (uint256) {
        uint256 sharesNeeded = autoEth.convertToShares(amount);
        uint256 actualSharesHeld = rewarder.balanceOf(address(this));
        uint256 shareDiff = actualSharesHeld - sharesNeeded;   
        if (shareDiff <= 1e18) {
            sharesNeeded = actualSharesHeld;
        }
        rewarder.withdraw(address(this), sharesNeeded, true);
        uint256 wethBalanceBefore = TokenUtils.safeBalanceOf(address(weth), address(this));
        autoEth.redeem(sharesNeeded, address(this), address(this));
        uint256 wethBalanceAfter = TokenUtils.safeBalanceOf(address(weth), address(this));
        uint256 wethRedeemed = wethBalanceAfter - wethBalanceBefore;
        if (wethRedeemed < amount) {
            emit StrategyDeallocationLoss("Strategy deallocation loss.", amount, wethRedeemed);
        }
        require(TokenUtils.safeBalanceOf(address(weth), address(this)) >= amount, "Strategy balance is less than the amount needed");
        TokenUtils.safeApprove(address(weth), msg.sender, amount);
        return amount;
    }






    function _previewAdjustedWithdraw(uint256 amount) internal view override returns (uint256) {
        uint256 sharesNeeded = autoEth.convertToShares(amount);
        uint256 assets = autoEth.convertToAssets(sharesNeeded);
        return assets - (assets * slippageBPS / 10_000);
    }

    //📌🐧
    function _claimRewards() internal override returns (uint256 rewardsClaimed) {
        rewardsClaimed = rewarder.earned(address(this));
        rewarder.getReward(address(this), address(MYT), false);
    }

    function _unwrapWETH(uint256 amount, address to) internal {
        weth.withdraw(amount);
        (bool ok,) = to.call{value: amount}("");
        require(ok, "ETH send failed");
    }

    function _computeBaseRatePerSecond() internal override returns (uint256 ratePerSec, uint256 newIndex) {
        uint256 dt = lastSnapshotTime == 0 ? 0 : block.timestamp - lastSnapshotTime;

        uint256 currentPPS = autoEth.convertToAssets(1e18);

        newIndex = currentPPS;
        if (lastIndex == 0 || dt == 0 || currentPPS <= lastIndex) return (0, newIndex);
        uint256 growth = (currentPPS - lastIndex) * FIXED_POINT_SCALAR / lastIndex;
        ratePerSec = growth / dt;
        return (ratePerSec, newIndex);
    }


    function realAssets() external view override returns (uint256) {
        uint256 shares = rewarder.balanceOf(address(this));
        uint256 assets = autoEth.convertToAssets(shares);
        return assets;
    }
}
