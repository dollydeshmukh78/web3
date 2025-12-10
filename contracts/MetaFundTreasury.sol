// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface of the MetaFundTreasury implementation.
/// @dev Adjust constructor signature to match your MetaFundTreasury.sol.
interface IMetaFundTreasury {
    // Example constructor: constructor(address _governance, address _asset, address _owner)
}

contract MetaFundTreasuryDeployer {
    event MetaFundTreasuryDeployed(address indexed treasury, address indexed deployer);

    /// @notice Deploy a new MetaFundTreasury instance.
    /// @dev Replace parameters and constructor call to match your actual contract.
    function deployMetaFundTreasury(
        address governance,
        address asset,
        address owner
    ) external returns (address) {
        require(governance != address(0), "Invalid governance");
        require(asset != address(0), "Invalid asset");
        require(owner != address(0), "Invalid owner");

        // Replace this line with the real constructor for MetaFundTreasury.
        MetaFundTreasury treasury = new MetaFundTreasury(governance, asset, owner);

        emit MetaFundTreasuryDeployed(address(treasury), msg.sender);
        return address(treasury);
    }
}

/// @dev Stub for the real MetaFundTreasury contract.
/// Replace with `import "./MetaFundTreasury.sol";` in your project.
contract MetaFundTreasury {
    address public governance;
    address public asset;
    address public owner;

    constructor(address _governance, address _asset, address _owner) {
        governance = _governance;
        asset = _asset;
        owner = _owner;
    }
}
