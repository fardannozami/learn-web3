// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MyVault is ReentrancyGuard {
    IERC20 public immutable token;

    uint256 public totalShares;
    mapping(address => uint256) public shares;

    // Custom errors
    error ZeroAmount();
    error InsufficientShares(uint256 requested, uint256 available);
    error ZeroSharesMinted();

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 sharesMinted);
    event Withdrawn(address indexed user, uint256 shares, uint256 amountReturned);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        uint256 sharesToMint;
        uint256 totalTokenBalance = token.balanceOf(address(this));

        if (totalShares == 0 || totalTokenBalance == 0) {
            // Deposit pertama: shares = amount (1:1)
            sharesToMint = amount;
        } else {
            // Shares proporsional terhadap total balance saat ini
            sharesToMint = (amount * totalShares) / totalTokenBalance;
        }

        if (sharesToMint == 0) revert ZeroSharesMinted();

        totalShares += sharesToMint;
        shares[msg.sender] += sharesToMint;

        token.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount, sharesToMint);
    }

    function withdraw(uint256 sharesToBurn) external nonReentrant {
        if (sharesToBurn == 0) revert ZeroAmount();
        if (sharesToBurn > shares[msg.sender])
            revert InsufficientShares(sharesToBurn, shares[msg.sender]);

        uint256 amountToReturn =
            (sharesToBurn * token.balanceOf(address(this))) / totalShares;

        totalShares -= sharesToBurn;
        shares[msg.sender] -= sharesToBurn;

        token.transfer(msg.sender, amountToReturn);

        emit Withdrawn(msg.sender, sharesToBurn, amountToReturn);
    }
}