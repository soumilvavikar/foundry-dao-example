// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {VotingGovernor} from "../src/VotingGovernor.sol";
import {VotingToken} from "../src/VotingToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {ContractV1} from "../src/Contract_v1.sol";

/**
 * @title VotingGovernorTest
 * @author Soumil Vavikar
 * @notice A test suite for the VotingGovernor contract
 */
contract VotingGovernorTest is Test {
    VotingToken token;
    TimeLock timelock;
    VotingGovernor governor;
    ContractV1 contractV1;

    // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant MIN_DELAY = 3600;
    // Need 4% of voters to pass
    uint256 public constant QUORUM_PERCENTAGE = 4;
    // This is how long voting lasts
    uint256 public constant VOTING_PERIOD = 50400;
    // How many blocks till a proposal vote becomes active
    uint256 public constant VOTING_DELAY = 1;

    address[] proposers;
    address[] executors;

    bytes[] callData;
    address[] targets;
    uint256[] values;

    address public constant VOTER = address(1);

    /**
     * @notice Set up the test suite
     * @dev This function is called before each test.
     * It sets up the VotingToken, TimeLock, and VotingGovernor contracts
     */
    function setUp() public {
        // Setup voting token
        token = new VotingToken();
        token.mint(VOTER, 100e18);

        vm.startPrank(VOTER);
        token.delegate(VOTER);

        // Setup the TimeLock
        timelock = new TimeLock(MIN_DELAY, proposers, executors);
        // Setup the VotingGovernor
        governor = new VotingGovernor(token, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        // Grant roles to the governor to the timelock
        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        // Revoke the admin role from the deployer
        timelock.revokeRole(adminRole, msg.sender);
        vm.stopPrank();

        // Setup the contractV1
        contractV1 = new ContractV1();
        // Transfer ownership to the timelock
        contractV1.transferOwnership(address(timelock));
    }

    /**
     * @notice Can't update the contract without governance
     */
    function testCantUpdateContractV1WithoutGovernance() public {
        vm.expectRevert();
        contractV1.setValue(1);
    }

    /**
     * @notice Governance can update the contractV1
     */
    function testGovernanceUpdatesContractV1() public {
        uint256 valueToStore = 777;
        string memory description = "Store 1 in ContractV1";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("setValue(uint256)", valueToStore);
        targets.push(address(contractV1));
        values.push(0);
        callData.push(encodedFunctionCall);

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, callData, description);

        // Should return 0, as the proposal is in queue and is pending
        console.log("Proposal State:", uint256(governor.state(proposalId)));
        // governor.proposalSnapshot(proposalId)
        // governor.proposalDeadline(proposalId)

        vm.warp(block.timestamp + VOTING_DELAY + 10);
        vm.roll(block.number + VOTING_DELAY + 10);

        // Should be active now.
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "Trying something new";
        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, callData, descriptionHash);
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(targets, values, callData, descriptionHash);

        assert(contractV1.getValue() == valueToStore);
    }
}
