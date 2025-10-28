// SPDX-License-Identifier: MIT
// تغریف اینتر فیس برای تعامل با صرافی غیر مترمکز این که در شبکه اوپتیمسم هست Velodrome AMM
pragma solidity 0.8.28;
import {IERC20} from "./IERC20.sol";

interface IVelodromePair {
    function metadata()
        external
        view
        returns (
            uint256 basis0,
            uint256 basis1,
            uint256 reserve0,
            uint256 reserve1,
            bool stable,
            IERC20 token0,
            IERC20 token1
        );
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}


