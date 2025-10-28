
#  Smart Contract Vulnerability Report
**Alchemix V3**:

##  Vulnerability Title 

Incorrect Output Due to Unimplemented Logic


## 🗂 Report Type

Smart Contract


##  Target

- https://github.com/alchemix-finance/v3-poc/blob/immunefi_audit/src/MYTStrategy.sol


## Asset

MYTStrategy.sol



##  Rating

Severity: Medium

Impact: Medium

Likelihood: Low




##  Description

The functions `claimRewards()` and `claimWithdrawalQueue()` do not return the values from their internal functions `_claimRewards()` and `_claimWithdrawalQueue()`.

In practice, whenever someone calls these functions, the returned value is always the default `0`, even if the internal functions produce a non-zero value.

This prevents the caller from observing the real reward or withdrawal amounts, which can lead to unexpected behavior or misinterpretation when interacting with the contract.


Here is important:👇🏽

📌`_claimRewards()` always equals 0.

📌`_claimWithdrawalQueue()` always equals 0, but  `_claimWithdrawalQueue()` is only implemented in `SfrxETHStrategy`. The `MYTStrategy` contract does not have access to it, so in this contract it effectively always returns 0.

For `MYTStrategy` to actually execute the operations, it would need access to `_claimWithdrawalQueue()`, but it currently does not. That’s why the output is always 0.



🐧Step by Step in POC :




##  Impact

1_ Users cannot see or obtain their actual rewards or withdrawal amounts.

2_ Systems relying on the outputs of these functions for reward or withdrawal calculations will always receive zero, potentially making incorrect decisions.

3_ This is a logical bug that may affect application behavior but does not directly allow asset theft.





##  Vulnerability Details


In both functions, the return value of the internal function is ignored,
 resulting in a default return of `0`.


```solidity 

    function claimWithdrawalQueue(uint256 positionId) public virtual returns (uint256 ret) {

        require(whitelistedAllocators[msg.sender], "PD");
        require(!killSwitch, "emergency");
        _claimWithdrawalQueue(positionId);
    }




    function claimRewards() public virtual returns (uint256) {

        require(!killSwitch, "emergency");
        _claimRewards();
    }
    
```




## Proof of Concept (PoC)
 
🐧Step by Step POC

Full POC Downlaod and Run  from Github👇🏽

``https://github.com/AidenNabavi/Alchemix.report``


use this  -----> forge test -vv


```solidity



// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MYTStrategy.sol";



// This is only used so that we can deploy this test contract for MYTStrategy
// It is used in the setUp() function
contract Vault {

}



// This is only used so that we can deploy this test contract for MYTStrategy
// It is used in the setUp() function
contract AutoEthMock {
    function convertToShares(uint256 amount) external pure returns (uint256) {
        return amount;
    }
    function redeem(uint256, address, address) external {}
    function approve(address, uint256) external pure returns (bool) {
        return true; 
    }
}





/// @notice This contract is a mock of the Rewarder contract, which is used in the _claimRewards() function in the TokeAutoEth.sol contract.
/// @notice By default, we set it so that it always returns 50, just to observe how this function behaves.
/// The main goal is to test the 👉🏽 claimRewards()   and see whether it returns 50 or not.

/// @dev 👇🏽 To understand exactly what this mock does, go to this path:
/// @dev src/TokeAutoEth.sol -------> _claimRewards()   
/// @dev This mock represents the rewarder. The only difference is that we set the default output to 50 to see if this output is reflected in the claimRewards() function? or not?

contract RewarderMock {
    function earned(address) external pure returns (uint256) {
        return 50; // default value for testing
    }
    function getReward(address) external pure returns (uint256) {
        return 50; // default value for testing
    }

}



//test
contract TestDeallocateUnderflow is Test {
    MYTStrategy strategy;
    AutoEthMock autoeth;
    Vault vault;
    RewarderMock rewarder;

    address owner=address(0x00001);

    function setUp() public {

        autoeth= new AutoEthMock();
        vault=new Vault();
        rewarder=new RewarderMock();

        IMYTStrategy.StrategyParams memory _params = IMYTStrategy.StrategyParams({
            owner: address(this),
            name: "Auto_Eth",
            protocol: "AutoEth",
            riskClass: IMYTStrategy.RiskClass.MEDIUM,
            cap: 0,
            globalCap: 0,
            estimatedYield: 0,
            additionalIncentives: false,
            slippageBPS: 0
        });

        strategy = new MYTStrategy(address(vault), _params, address(0x1234), address(autoeth));
        
        // Grant control access ------> whitelistedAllocators
        strategy.setWhitelistedAllocator(owner,true);

        // Disable the kill switch so that we can call the functions
        strategy.setKillSwitch(false);

    }




    // Test the two functions :  claimRewards()   and   claimWithdrawalQueue()
    function test_claimRewards_claimWithdrawalQueue() public {

        vm.startPrank(owner);

        uint256 ret1 = strategy.claimRewards();
        console.log("claimRewards  Should return 50, but it actually returns  : ", ret1);
         // Should return 50, but it actually returns 0    
        
        uint256 positionId = 1;
        uint256 ret2 = strategy.claimWithdrawalQueue(positionId);
        console.log("claimWithdrawalQueue  Since it's not implemented, you can see the output is  : ", ret2);
        // Since it's not implemented, you can see the output is 0

        if (ret1 == 0 || ret2 == 0) {
            console.log(" Bug exists: functions are not returning expected values!");
        } else {
            console.log(" Functions returned values correctly");
        }
    }


}





```







## How to fix it (Recommended)

Explicitly assigning and returning the internal function's output ensures the caller receives the actual values.

```solidity

//1_This function also needs to be **imported** from the `SfrxETH.sol` contract.
import ../src/strategies/SfrxETH.sol;



//2_Inheritance
contract MYTStrategy is SfrxETHStrategy {}



//3_fix   ---->   return ret;
function claimWithdrawalQueue(uint256 positionId) public virtual returns (uint256 ret) {
    require(whitelistedAllocators[msg.sender], "PD");
    require(!killSwitch, "emergency");
    ret = _claimWithdrawalQueue(positionId); // explicitly assign internal function return value
    return ret;
}


//4_fix   ---->   return ret;
function claimRewards() public virtual returns (uint256 ret) {
    require(!killSwitch, "emergency");
    ret = _claimRewards(); // explicitly assign internal function return value
    return ret;
}


```




##  References

- https://github.com/alchemix-finance/v3-poc/blob/immunefi_audit/src/MYTStrategy.sol





