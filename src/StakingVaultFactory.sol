pragma solidity ^0.8.0 <0.8.20;

import {StakingVault} from "./vaults/StakingVault.sol";

contract StakingVaultFactory {
    address[] public allVaults;
    event VaultDeployed(address indexed asset, address indexed rewardToken);

    function deploy(
        address asset,
        address rewardToken,
        uint maxLockTime,
        address strategy,
        string memory name,
        string memory symbol
    ) external {
        StakingVault vault = new StakingVault(
            asset,
            maxLockTime,
            rewardToken,
            strategy,
            name,
            symbol
        );
        allVaults.push(address(vault));

        emit VaultDeployed(asset, rewardToken);
    }

    function getTotalVaults() external view returns (uint256) {
        return allVaults.length;
    }

    function getRegisteredAddresses() external view returns (address[] memory) {
        return allVaults;
    }
}
