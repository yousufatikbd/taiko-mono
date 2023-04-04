// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Uncomment if you want to compare fee/vs reward
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {AddressManager} from "../contracts/thirdparty/AddressManager.sol";
import {TaikoConfig} from "../contracts/L1/TaikoConfig.sol";
import {TaikoData} from "../contracts/L1/TaikoData.sol";
import {TaikoL1} from "../contracts/L1/TaikoL1.sol";
import {TaikoToken} from "../contracts/L1/TaikoToken.sol";
import {SignalService} from "../contracts/signal/SignalService.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {TaikoL1TestBase} from "./TaikoL1TestBase.t.sol";

contract TaikoL1WithNonMintingConfig is TaikoL1 {
    function getConfig()
        public
        pure
        override
        returns (TaikoData.Config memory config)
    {
        config = TaikoConfig.getConfig();

        config.enableTokenomics = true;
        config.txListCacheExpiry = 5 minutes;
        config.maxVerificationsPerTx = 0;
        config.enableSoloProposer = false;
        config.enableOracleProver = false;
        config.maxNumProposedBlocks = 10;
        config.ringBufferSize = 12;
        config.allowMinting = false;
        // this value must be changed if `maxNumProposedBlocks` is changed.
        config.slotSmoothingFactor = 4160;

        config.provingConfig = TaikoData.FeeConfig({
            avgTimeMAF: 1024,
            dampingFactorBips: 5000
        });
    }
}

// Since the fee/reward calculation heavily depends on the baseFeeProof and the proofTime
// we need to simulate proposing/proving so that can calculate them.
contract LibL1TokenomicsTest is TaikoL1TestBase {
    function deployTaikoL1() internal override returns (TaikoL1 taikoL1) {
        taikoL1 = new TaikoL1WithNonMintingConfig();
    }

    function setUp() public override {
        TaikoL1TestBase.setUp();

        _depositTaikoToken(Alice, 1E6 * 1E8, 100 ether);
        _depositTaikoToken(Bob, 1E6 * 1E8, 100 ether);
        _depositTaikoToken(Carol, 1E6 * 1E8, 100 ether);
    }

    /// @dev The only thing we need to check that the differences converges to a balance
    /// @dev so we need to determine, some kind of ratio, this is the purpose of this
    function ratioBetween(uint128 x, uint128 y) internal returns (uint256) {
        unchecked {
            if (y == 0) assertEq(x, (x + 1));

            //Safe to 'upshift'
            uint256 result = (uint256(x) << 64) / y;
            return result;
        }
    }

    /// @dev Test what happens when proof time increases
    function test_non_minting_reward_and_fee_if_proof_time_increases()
        external
    {
        mine(1);
        _depositTaikoToken(Alice, 1E6 * 1E8, 100 ether);
        _depositTaikoToken(Bob, 1E6 * 1E8, 100 ether);
        _depositTaikoToken(Carol, 1E6 * 1E8, 100 ether);

        bytes32 parentHash = GENESIS_BLOCK_HASH;

        // Check balances
        uint256 Alice_start_balance = L1.getBalance(Alice);
        uint256 Bob_start_balance = L1.getBalance(Bob);
        console2.log("Alice balance:", Alice_start_balance);
        console2.log("Bob balance:", Bob_start_balance);

        for (uint256 blockId = 1; blockId < 5; blockId++) {
            printVariables("before propose");
            TaikoData.BlockMetadata memory meta = proposeBlock(Alice, 1024);
            uint64 proposedAt = uint64(block.timestamp);
            printVariables("after propose");
            mine(blockId);

            bytes32 blockHash = bytes32(1E10 + blockId);
            bytes32 signalRoot = bytes32(1E9 + blockId);
            proveBlock(Bob, meta, parentHash, blockHash, signalRoot);
            uint64 provenAt = uint64(block.timestamp);
            verifyBlock(Carol, 1);
            console2.log(
                "Proof reward is:",
                L1.getProofReward(provenAt, proposedAt, 1000000)
            );
            parentHash = blockHash;
        }

        /// @dev Long term the sum of deposits / withdrawals converge towards the balance
        /// @dev The best way to assert this is to observ: the higher the loop counter
        /// @dev the smaller the difference between deposits / withrawals

        //Check end balances
        uint256 deposits = Alice_start_balance - L1.getBalance(Alice);
        uint256 withdrawals = L1.getBalance(Bob) - Bob_start_balance;

        console2.log(
            "Alice current balance after first iteration:",
            L1.getBalance(Alice)
        );
        console2.log(
            "Bob current balance after first iteration:",
            L1.getBalance(Bob)
        );
        console2.log("Deposits:", deposits);
        console2.log("withdrawals:", withdrawals);

        uint256 difference_ratio_1 = ratioBetween(
            uint128(deposits),
            uint128(withdrawals)
        );
        //console2.log("Ratio now is:", difference_ratio_1);

        // Run another sessioins
        for (uint256 blockId = 1; blockId < 10; blockId++) {
            printVariables("before propose");
            TaikoData.BlockMetadata memory meta = proposeBlock(Alice, 1024);
            uint64 proposedAt = uint64(block.timestamp);
            printVariables("after propose");
            mine(blockId);

            bytes32 blockHash = bytes32(1E10 + blockId);
            bytes32 signalRoot = bytes32(1E9 + blockId);
            proveBlock(Bob, meta, parentHash, blockHash, signalRoot);
            uint64 provenAt = uint64(block.timestamp);
            verifyBlock(Carol, 1);
            console2.log(
                "Proof reward is:",
                L1.getProofReward(provenAt, proposedAt, 1000000)
            );
            parentHash = blockHash;
        }

        //Check end balances
        deposits = Alice_start_balance - L1.getBalance(Alice);
        withdrawals = L1.getBalance(Bob) - Bob_start_balance;

        console2.log(
            "Alice current balance after second iteration:",
            L1.getBalance(Alice)
        );
        console2.log(
            "Bob current balance after second iteration:",
            L1.getBalance(Bob)
        );
        console2.log("Deposits:", deposits);
        console2.log("withdrawals:", withdrawals);

        uint256 difference_ratio_2 = ratioBetween(
            uint128(deposits),
            uint128(withdrawals)
        );
        //console2.log("Ratio now is:", difference_ratio_2);

        //Assert that the deposits and withdrawals are converging towards a balance
        // difference_1, shall be greater than difference_2
        assertGe(difference_ratio_1, difference_ratio_2);
    }
}
