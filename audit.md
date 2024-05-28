# Audit

## General
Besides test fixes we refactored the strategy contracts significantly.
What was previously Adapters is now called strategies.
The delegatecalls to external strategies are removed. All logic is now in the strategy contract itself.
The `harvest`-function is now permissioned. We added a keeper role. `harvest` can be called by `keeper` or `owner`. Aura, Balancer use shared inherited contracts stored in `./src/peripheral` same with Curve and Convex contracts.
Fees are moved from the strategies to the MultiStrategyVault.
Additionally strategies can now have a toggle `autoDeposit`. This changes if users deposit directly into the underlying protocol of a strategy or simply send the funds into the strategy itself.
Two new functions have been added `pushFunds` and `pullFunds` these allow the `owner` to deposit or withdraw funds from the underlying protocol. These functions can be used in conjunction with `autoDeposit` to control slippage that users may suffer better. Both functions allow the `owner` to send arbitrary data to the call which can be used for slippage protection or other safety features. 
We also removed the Gearbox Strategies from the audit since they still need more work and additionally dont provide anything useful after the recent GearboxV3 leverage feature. 

## Ignored Issues
### Issue 1 - Governance Privileges
We will ignore this issue since its an issue of setup and configuration. Now with more permissioned functions in strategies this becomes a bigger issue and must be taken care of in the contract setup.

### Issue 4 - The implementation of the proxies can be initialized
Its not entirely clear yet if we will simply construct and init strategies or create factories so we will add `_disableInitializers()` if it becomes necessary

### Issue 10 - Missing parameters in the NewStrategiesProposed event
We will keep these events simple. The proposed strategies can be read when reading the contract state.

### Issue 13 - _protocolWithdraw should be called after _burn
While the issue might be correct if the underlying protocol is attackable via reentrancy we need to call `_protocolWithdraw` before `_burn` so we can use `totalSupply` and asset or share conversions in `_protocolWithdraw` without any issues.

## Improvement Explanations