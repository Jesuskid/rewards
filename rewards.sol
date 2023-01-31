// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Stake is ERC20 {

    struct Investor{
        uint256 amount;
        uint256 lastRewardReedemed;
    }

    mapping(address=>Investor) public deposits;
    mapping(address=>uint256) public Asset;


    uint256 public STAKE_MULTIPLE = 10 ether;
    uint256 public REWARD_UNIT = 0.1 ether;
    bool inMotion;

    modifier nonReentrant(){
        require(inMotion == false);
        inMotion = true;
        _;
        inMotion = false;
    }

    IERC20 stakedToken;

    constructor(address _stakedToken) ERC20("SReward", "SRWD") {
        stakedToken = IERC20(_stakedToken);
        _mint(address(this), 10000 ether);
    }

    function takeDeposit(uint256 amount) external {
        require(amount % STAKE_MULTIPLE == 0, "Stake: Deposit amount must be a multiple of 10");
        //transfer tokens in
        // stakedToken.transferFrom(msg.sender, address(this), amount);

        uint256 stakedAssets = amount / STAKE_MULTIPLE;
        Investor storage investor = deposits[msg.sender];
        investor.amount = amount + investor.amount;
        
        //transfer any previous rewards held to avoid collision between old and new deposits
        (uint256 rewards, uint256 hoursInExcess) = calculateRewards(msg.sender);
        if(rewards >= REWARD_UNIT){
            _claimReward(msg.sender);
        }
        investor.lastRewardReedemed = block.timestamp - hoursInExcess;
        Asset[msg.sender] += stakedAssets;
    }

    function calculateRewards(address holder) internal view returns(uint256, uint256){
        Investor storage investor = deposits[holder];
        uint256 AssetHolding = Asset[holder];
        uint256 span = block.timestamp -  investor.lastRewardReedemed;

        uint256 hoursInExcess = span % 24 minutes;

        uint256 full24HourCycle = span - hoursInExcess;

        uint256 rewards = REWARD_UNIT * AssetHolding * (full24HourCycle/24 minutes);
        return (rewards, hoursInExcess);

    }

    function _claimReward(address claimant) internal {
        Investor storage investor = deposits[claimant];
        (uint256 rewards, uint256 hoursInExcess) = calculateRewards(claimant);
        require(rewards > 0, "Stake: You have no rewards to claim");
        IERC20(address(this)).transfer(msg.sender, rewards);
        investor.lastRewardReedemed = block.timestamp - hoursInExcess;
    }

    function claimReward() public {
        Investor storage investor = deposits[msg.sender];
        (uint256 rewards, uint256 hoursInExcess) = calculateRewards(msg.sender);
        require(rewards > 0, "Stake: You have no rewards to claim");
        IERC20(address(this)).transfer(msg.sender, rewards);
        investor.lastRewardReedemed = block.timestamp - hoursInExcess;
    }

     function myRewards() public view returns(uint256){
        (uint256 rewards, ) = calculateRewards(msg.sender);
        return rewards;
    }

}
