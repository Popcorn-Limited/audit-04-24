// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {CloneRegistry} from "../src/vault/CloneRegistry.sol";
import {CloneFactory} from "../src/vault/CloneFactory.sol";
import {PermissionRegistry} from "../src/vault/PermissionRegistry.sol";
import {TemplateRegistry, Template} from "../src/vault/TemplateRegistry.sol";
import {DeploymentController} from "../src/vault/DeploymentController.sol";
import {VaultController, IAdapter, VaultInitParams, VaultMetadata, IERC4626, IERC20, VaultFees} from "../src/vault/VaultController.sol";
import {Vault} from "../src/vault/Vault.sol";
import {AdminProxy} from "../src/vault/AdminProxy.sol";
import {VaultRegistry} from "../src/vault/VaultRegistry.sol";

import {MultiRewardEscrow} from "../src/utils/MultiRewardEscrow.sol";
import {MultiRewardStaking} from "../src/utils/MultiRewardStaking.sol";

import {ICloneRegistry} from "../src/interfaces/vault/ICloneRegistry.sol";
import {ICloneFactory} from "../src/interfaces/vault/ICloneFactory.sol";
import {IPermissionRegistry, Permission} from "../src/interfaces/vault/IPermissionRegistry.sol";
import {ITemplateRegistry} from "../src/interfaces/vault/ITemplateRegistry.sol";
import {IDeploymentController} from "../src/interfaces/vault/IDeploymentController.sol";
import {IVaultRegistry} from "../src/interfaces/vault/IVaultRegistry.sol";
import {IAdminProxy} from "../src/interfaces/vault/IAdminProxy.sol";
import {IVaultController, DeploymentArgs} from "../src/interfaces/vault/IVaultController.sol";

import {IMultiRewardEscrow} from "../src/interfaces/IMultiRewardEscrow.sol";
import {IMultiRewardStaking} from "../src/interfaces/IMultiRewardStaking.sol";
import {IOwned} from "../src/interfaces/IOwned.sol";
import {IPausable} from "../src/interfaces/IPausable.sol";

import {VaultRouter} from "../src/vault/VaultRouter.sol";
import {YearnAdapter} from "../src/vault/adapter/yearn/YearnAdapter.sol";
import {BeefyAdapter} from "../src/vault/adapter/beefy/BeefyAdapter.sol";

import {VaultRouter} from "../src/vault/VaultRouter.sol";

import {MockStrategy} from "../test/utils/mocks/MockStrategy.sol";

contract DeployVaultSystem is Script {
    ITemplateRegistry templateRegistry =
        ITemplateRegistry(0xA18735b352a926aD957F94Ff40764E63139ec0a6);
    IPermissionRegistry permissionRegistry =
        IPermissionRegistry(0x7a33b5b57C8b235A3519e6C010027c5cebB15CB4);
    ICloneRegistry cloneRegistry =
        ICloneRegistry(0x795d90945e5B9b320410b31e6E544b647d0ea5AA);
    IVaultRegistry vaultRegistry =
        IVaultRegistry(0xdD0d135b5b52B7EDd90a83d4A4112C55a1A6D23A);

    ICloneFactory factory =
        ICloneFactory(0x504f828886aB10D09ca1c116d6E1C5b8963cB109);
    IDeploymentController deploymentController =
        IDeploymentController(0xa8C5815f6Ea5F7A1551541B0d7F970D546126bDB);
    IAdminProxy adminProxy =
        IAdminProxy(0x7D224F9Eaf3855CE3109b205e6fA853d25Bb457f);

    IMultiRewardStaking staking;
    IMultiRewardEscrow escrow =
        IMultiRewardEscrow(0x823033d1014F0f4da2Bb5B2cE4bC73D6e7eAe7a8);

    VaultController controller =
        VaultController(0xa199409F99bDBD998Ae1ef4FdaA58b356370837d);
    VaultRouter router;

    IERC20 pop = IERC20(0x6F0fecBC276de8fC69257065fE47C5a03d986394);

    address stakingImpl = 0x9C45FE2Bf8F76f0de45ea9f56c3aCF6613C87675;
    address yearnImpl = 0xfc90a1B7e86E20607871A23b0ca560591A5Db30d;
    address beefyImpl = 0xaa733e18a26C23fBfdAdF9b2bE846F67412d0467;
    address strategyImpl;
    address vaultImpl = 0xA04f549b1eAb2D6669Ba57DA3e528587082ef5b1;

    address deployer;
    address feeRecipient = address(0x47fd36ABcEeb9954ae9eA1581295Ce9A8308655E);

    bytes32 templateCategory = "templateCategory";
    bytes32 templateId = "MockAdapter";
    string metadataCid = "";
    bytes4[8] requiredSigs;
    address[8] swapTokenAddresses;

    event log(string);
    event log_uint(uint256);
    event log_address(address);

    event log_named_address(string str, address addr);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        emit log_address(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // stakingImpl = address(new MultiRewardStaking());
        // yearnImpl = address(new YearnAdapter());
        // beefyImpl = address(new BeefyAdapter());
        // strategyImpl = address(new MockStrategy());
        // vaultImpl = address(new Vault());

        // adminProxy = IAdminProxy(address(new AdminProxy(deployer)));

        // permissionRegistry = IPermissionRegistry(
        //     address(new PermissionRegistry(address(adminProxy)))
        // );
        // vaultRegistry = IVaultRegistry(
        //     address(new VaultRegistry(address(adminProxy)))
        // );
        // escrow = IMultiRewardEscrow(
        //     address(new MultiRewardEscrow(address(adminProxy), feeRecipient))
        // );
        // router = new VaultRouter(vaultRegistry);

        // deployDeploymentController();
        // deploymentController.nominateNewOwner(address(adminProxy));
        // adminProxy.execute(
        //     address(deploymentController),
        //     abi.encodeWithSelector(IOwned.acceptOwnership.selector, "")
        // );

        // controller = new VaultController(
        //     deployer,
        //     adminProxy,
        //     deploymentController,
        //     vaultRegistry,
        //     permissionRegistry,
        //     escrow
        // );

        // adminProxy.nominateNewOwner(address(controller));
        // controller.acceptAdminProxyOwnership();

        // bytes32[] memory templateCategories = new bytes32[](4);
        // templateCategories[0] = "Vault";
        // templateCategories[1] = "Adapter";
        // templateCategories[2] = "Strategy";
        // templateCategories[3] = "Staking";
        // controller.addTemplateCategories(templateCategories);

        // addTemplate(
        //     "Staking",
        //     "MultiRewardStaking",
        //     stakingImpl,
        //     address(0),
        //     true,
        //     true
        // );
        // addTemplate(
        //     "Adapter",
        //     "YearnAdapter1",
        //     yearnImpl,
        //     address(0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804),
        //     true,
        //     true
        // );
        // addTemplate(
        //     "Adapter",
        //     "BeefyAdapter3",
        //     beefyImpl,
        //     address(permissionRegistry),
        //     true,
        //     true
        // );
        // addTemplate("Vault", "V1", vaultImpl, address(0), true, true);

        // emit log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        // emit log_named_address("VaultController: ", address(controller));
        // emit log_named_address("VaultRegistry: ", address(vaultRegistry));
        // emit log_named_address("VaultRouter: ", address(router));
        // emit log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

        // // approve pop for staking rewards
        // pop.approve(address(controller), 2000 ether);

        // // approve usdc for inital deposit
        // IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
        //     address(controller),
        //     100e6
        // );

        // // deploy usdc yearn vault
        // address yearn = controller.deployVault(
        //     VaultInitParams({
        //         asset: IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
        //         adapter: IERC4626(address(0)),
        //         fees: VaultFees({
        //             deposit: 0,
        //             withdrawal: 0,
        //             management: 0,
        //             performance: 0
        //         }),
        //         feeRecipient: feeRecipient,
        //         depositLimit: type(uint256).max,
        //         owner: deployer
        //     }),
        //     DeploymentArgs({id: "YearnAdapter", data: abi.encode(uint256(1))}),
        //     DeploymentArgs({id: "", data: ""}),
        //     false,
        //     "",
        //     VaultMetadata({
        //         vault: address(0),
        //         staking: address(0),
        //         creator: address(this),
        //         metadataCID: metadataCid,
        //         swapTokenAddresses: swapTokenAddresses,
        //         swapAddress: address(0),
        //         exchange: uint256(0)
        //     }),
        //     0
        // );

        // emit log_named_address("YearnVault: ", yearn);

        // // approve and stake vault
        // VaultMetadata memory yearnMetadata = vaultRegistry.getVault(yearn);
        // IERC20(yearn).approve(yearnMetadata.staking, 100e15);
        // IMultiRewardStaking(yearnMetadata.staking).deposit(100e15, deployer);

        // // deposit usdc and stake through the router
        // IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve(
        //     address(router),
        //     100e6
        // );
        // router.depositAndStake(IERC4626(yearn), 100e6, deployer);

        // IERC20(yearnMetadata.staking).approve(address(router), 10e15);
        // router.redeemAndWithdraw(IERC4626(yearn), 10e15, deployer, deployer);

        // // beefyVault stEth/eth = 0xa7739fd3d12ac7F16D8329AF3Ee407e19De10D8D
        // setPermission(0xa7739fd3d12ac7F16D8329AF3Ee407e19De10D8D, true, false);
        // // beefyBooster = 0xAe3F0C61F3Dc48767ccCeF3aD50b29437BE4b1a4
        // setPermission(0xAe3F0C61F3Dc48767ccCeF3aD50b29437BE4b1a4, true, false);

        // // approve stEth/eth for inital deposit
        // IERC20(0x06325440D014e39736583c165C2963BA99fAf14E).approve(
        //     address(controller),
        //     10e18
        // );

        // // crvSthEth/Eth = 0x06325440D014e39736583c165C2963BA99fAf14E
        // // deploy stEth/eth beefy vault
        // address beefy = controller.deployVault(
        //     VaultInitParams({
        //         asset: IERC20(0x06325440D014e39736583c165C2963BA99fAf14E),
        //         adapter: IERC4626(address(0)),
        //         fees: VaultFees({
        //             deposit: 0,
        //             withdrawal: 0,
        //             management: 0,
        //             performance: 0
        //         }),
        //         feeRecipient: feeRecipient,
        //         depositLimit: type(uint256).max,
        //         owner: deployer
        //     }),
        //     DeploymentArgs({
        //         id: "BeefyAdapter",
        //         data: abi.encode(
        //             0xa7739fd3d12ac7F16D8329AF3Ee407e19De10D8D,
        //             0xAe3F0C61F3Dc48767ccCeF3aD50b29437BE4b1a4
        //         )
        //     }),
        //     DeploymentArgs({id: "", data: ""}),
        //     false,
        //     "",
        //     VaultMetadata({
        //         vault: address(0),
        //         staking: address(0),
        //         creator: deployer,
        //         metadataCID: "",
        //         swapTokenAddresses: swapTokenAddresses,
        //         swapAddress: address(0),
        //         exchange: uint256(0)
        //     }),
        //     10e18
        // );

        // emit log_named_address("BeefyVault: ", beefy);

        // // approve and stake vault
        // VaultMetadata memory beefyMetadata = vaultRegistry.getVault(beefy);
        // IERC20(beefy).approve(beefyMetadata.staking, 10e27);
        // IMultiRewardStaking(beefyMetadata.staking).deposit(10e27, deployer);

        vm.stopBroadcast();
    }

    function deployDeploymentController() public {
        factory = ICloneFactory(address(new CloneFactory(deployer)));
        cloneRegistry = ICloneRegistry(address(new CloneRegistry(deployer)));
        templateRegistry = ITemplateRegistry(
            address(new TemplateRegistry(deployer))
        );

        deploymentController = IDeploymentController(
            address(
                new DeploymentController(
                    deployer,
                    factory,
                    cloneRegistry,
                    templateRegistry
                )
            )
        );

        factory.nominateNewOwner(address(deploymentController));
        cloneRegistry.nominateNewOwner(address(deploymentController));
        templateRegistry.nominateNewOwner(address(deploymentController));
        deploymentController.acceptDependencyOwnership();
    }

    function addTemplate(
        bytes32 templateCategory,
        bytes32 templateId,
        address implementation,
        address registry,
        bool requiresInitData,
        bool endorse
    ) public {
        // deploymentController.addTemplate(
        //     templateCategory,
        //     templateId,
        //     Template({
        //         implementation: implementation,
        //         endorsed: false,
        //         metadataCid: metadataCid,
        //         requiresInitData: requiresInitData,
        //         registry: registry,
        //         requiredSigs: requiredSigs
        //     })
        // );
        bytes32[] memory templateCategories = new bytes32[](1);
        bytes32[] memory templateIds = new bytes32[](1);
        templateCategories[0] = templateCategory;
        templateIds[0] = templateId;
        if (endorse)
            controller.toggleTemplateEndorsements(
                templateCategories,
                templateIds
            );
    }

    function setPermission(
        address target,
        bool endorsed,
        bool rejected
    ) public {
        address[] memory targets = new address[](1);
        Permission[] memory permissions = new Permission[](1);
        targets[0] = target;
        permissions[0] = Permission(endorsed, rejected);
        controller.setPermissions(targets, permissions);
    }
}
