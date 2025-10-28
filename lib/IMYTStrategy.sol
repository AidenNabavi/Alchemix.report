// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMYTStrategy {
    // Enums
    enum RiskClass {
        LOW,
        MEDIUM,
        HIGH
    }

    // Structs
    struct StrategyParams {
        address owner;
        string name;
        string protocol;
        RiskClass riskClass;
        uint256 cap;
        uint256 globalCap;
        uint256 estimatedYield;
        bool additionalIncentives;
        uint256 slippageBPS;
    }

    // Events
    event Allocate(uint256 indexed amount, address indexed strategy);
    event Deallocate(uint256 indexed amount, address indexed strategy);
    event DeallocateDex(uint256 indexed amount);
    event YieldUpdated(uint256 indexed yield);
    event RiskClassUpdated(RiskClass indexed class);
    event IncentivesUpdated(bool indexed enabled);
    event Emergency(bool indexed isEmergency);

    // Functions

    /// @dev override this function to handle wrapping/allocation/moving funds to
    /// the respective protocol of this strategy
    function allocate(bytes memory data, uint256 assets, bytes4 selector, address sender) external returns (bytes32[] memory strategyIds, int256 change);

    /// @dev override this function to handle unwrapping/deallocation/moving funds from
    /// the respective protocol of this strategy
    function deallocate(bytes memory data, uint256 assets, bytes4 selector, address sender) external returns (bytes32[] memory strategyIds, int256 change);

    /// @dev override this function to handle strategies with withdrawal queue NFT
    function claimWithdrawalQueue(uint256 positionId) external returns (uint256);

    /// @dev override this function to claim all available rewards from the respective
    /// protocol of this strategy
    function claimRewards() external returns (uint256);

    /// @notice can be called by anyone to recalculate the
    /// estimated yields of this strategy based on external price
    /// oracles and protocol heuristics.
    function snapshotYield() external returns (uint256);

    /// @notice recategorize this strategy to a different risk class
    function setRiskClass(RiskClass newClass) external;

    function setAdditionalIncentives(bool newValue) external;

    function setWhitelistedAllocator(address to, bool val) external;

    /// @notice enter/exit emergency mode for this strategy
    function setKillSwitch(bool val) external;

    /// @notice get the current snapshotted estimated yield for this strategy.
    /// This call does not guarantee the latest up-to-date yield and there might
    /// be discrepancies from the respective protocols numbers.
    function getEstimatedYield() external view returns (uint256);

    // Getter for params
    function params()
        external
        view
        returns (
            address owner,
            string memory name,
            string memory protocol,
            RiskClass riskClass,
            uint256 cap,
            uint256 globalCap,
            uint256 estimatedYield,
            bool additionalIncentives,
            uint256 slippageBPS
        );

    function getCap() external view returns (uint256);
    function getGlobalCap() external view returns (uint256);
    function realAssets() external view returns (uint256);
    function getIdData() external view returns (bytes memory);
    function ids() external view returns (bytes32[] memory);
    function adapterId() external view returns (bytes32);
    function previewAdjustedWithdraw(uint256 amount) external view returns (uint256);
}
