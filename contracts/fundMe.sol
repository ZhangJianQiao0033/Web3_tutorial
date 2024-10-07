// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract FundMe {
    mapping(address => uint256) public fundersToAmount;
    uint256 constant MINIMUM_VALUE = 100 * 10 ** 18;  // 最小为100美元
    uint256 constant TARGET = 1000 * 10 ** 18;
    address public owner;
    uint256 constant ETH_TO_USD_RATE = 2500 * 10 ** 8; // 假设1 ETH = 2500 USD (使用8位小数点精度)
    uint256 deploymentTimeStamp;
    uint256 lockTime;
    address erc20Addr;
    bool public getFundSuccess  = false;
    constructor(uint256 _lockTime) {
        owner = msg.sender;
        deploymentTimeStamp = block.timestamp;
        lockTime = _lockTime; 
    }

    function setErc20Addr(address _erc20Addr) public onlyOwner {
        erc20Addr = _erc20Addr;
    }


    function setFunderToAmount(address funder, uint256 amountUpdate) external  {
        require(msg.sender == erc20Addr, "You do not have permission to call this function!");
        fundersToAmount[funder] = amountUpdate;
    }

    function fund() external payable {
        require(block.timestamp < deploymentTimeStamp+lockTime,"window is closed.");
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "send more ETH");
        fundersToAmount[msg.sender] += msg.value; // 改为累加
    }

    // 这里不再使用Chainlink，而是使用一个固定的汇率
    function convertEthToUsd(uint256 ethAmount) internal pure returns (uint256) {
        return ethAmount * ETH_TO_USD_RATE / (10 ** 8);
    }

    function getFund() external onlyOwner {
        require(block.timestamp > deploymentTimeStamp+lockTime,"The time has expired.");
        require(convertEthToUsd(address(this).balance) >= TARGET, "TARGET is not reached");
        // payable(msg.sender).transfer(address(this).balance);
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success,"tx failed");
        bool success;
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success,"transfer tx is failed");
        fundersToAmount[msg.sender] = 0;
        getFundSuccess = true;


    }

    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    function refund() external windowClosed{
        require(TARGET > convertEthToUsd(address(this).balance),"TARGET is  reached");

        uint256 amount = fundersToAmount[msg.sender];
        require(amount >0,"There is no foud for you");
        bool success;
        fundersToAmount[msg.sender] = 0;
        (success,) = payable(msg.sender).call{value: amount}("");
        require(success,"transfer tx is failed");

    }
    modifier windowClosed() {
        require(block.timestamp > deploymentTimeStamp+lockTime,"The time has expired.");
        _;
    }

    modifier onlyOwner() {
       require(msg.sender == owner, "this function can only be called by the owner"); 
       _;
    }
}
