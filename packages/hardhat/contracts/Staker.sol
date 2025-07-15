// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline;
    bool public openForWithdraw;
    event Stake(address indexed staker, uint256 amount);

    modifier notCompleted {
        require(!exampleExternalContract.completed(), "Already Completed");
        _;
    }

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 30 seconds;
    }

    function stake() public payable {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reachded");
        if(address(this).balance > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw() public notCompleted {
        require(openForWithdraw, "Withdraw not open.");
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Nothing to withdraw.");
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to withdraw.");
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    receive() external payable {
        stake();
    }
}