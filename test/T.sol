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



