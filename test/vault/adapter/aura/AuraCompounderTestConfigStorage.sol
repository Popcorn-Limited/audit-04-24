pragma solidity ^0.8.15;

import {ITestConfigStorage} from "../abstract/ITestConfigStorage.sol";

struct AuraCompounderTestConfig {
    uint256 pid;
    address balVault;
    bytes32 balPoolId;
    address weth;
}

contract AuraCompounderTestConfigStorage is ITestConfigStorage {
    AuraCompounderTestConfig[] internal testConfigs;

    constructor() {
        testConfigs.push(
            AuraCompounderTestConfig(
                152,
                0xBA12222222228d8Ba445958a75a0704d566BF2C8,
                0xe7e2c68d3b13d905bbb636709cf4dfd21076b9d20000000000000000000005ca,
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            )
        );
    }

    function getTestConfig(uint256 i) public view returns (bytes memory) {
        return
            abi.encode(
                testConfigs[i].pid,
                testConfigs[i].balVault,
                testConfigs[i].balPoolId,
                testConfigs[i].weth
            );
    }

    function getTestConfigLength() public view returns (uint256) {
        return testConfigs.length;
    }
}