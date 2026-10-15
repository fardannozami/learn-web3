// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";
import "../src/MyVault.sol";

contract MyVaultTest is Test {
    MyToken public token;
    MyVault public vault;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 6;
    uint256 constant DEPOSIT_AMOUNT = 1000 * 10 ** 6;

    function setUp() public {
        // Jalankan sebagai owner untuk deployment
        vm.startPrank(owner);
        token = new MyToken(owner);
        vault = new MyVault(address(token));
        vm.stopPrank();

        // Distribusikan token ke alice dan bob untuk testing
        vm.startPrank(owner);
        token.transfer(alice, DEPOSIT_AMOUNT * 2);
        token.transfer(bob, DEPOSIT_AMOUNT * 2);
        vm.stopPrank();
    }

    // Test deposit pertama (vault kosong)
    function test_DepositFirst() public {
        vm.startPrank(alice);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Shares alice harus sama dengan amount yang dideposit (1:1 untuk deposit pertama)
        assertEq(vault.shares(alice), DEPOSIT_AMOUNT);
        assertEq(vault.totalShares(), DEPOSIT_AMOUNT);
        assertEq(token.balanceOf(address(vault)), DEPOSIT_AMOUNT);
    }

    // Test withdraw setelah deposit
    function test_WithdrawAfterDeposit() public {
        // Alice deposit
        vm.startPrank(alice);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        uint256 aliceSharesBefore = vault.shares(alice);
        uint256 aliceTokenBefore = token.balanceOf(alice);

        // Alice withdraw semua sharesnya
        vm.prank(alice);
        vault.withdraw(aliceSharesBefore);

        // Setelah withdraw, shares alice harus 0
        assertEq(vault.shares(alice), 0);
        assertEq(vault.totalShares(), 0);

        // Token alice harus kembali ke jumlah semula
        assertEq(token.balanceOf(alice), aliceTokenBefore + DEPOSIT_AMOUNT);
    }

    // Test revert ketika deposit amount = 0
    function test_RevertWhen_DepositZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(MyVault.ZeroAmount.selector);
        vault.deposit(0);
    }

    // Test revert ketika withdraw melebihi shares
    function test_RevertWhen_WithdrawExceedingShares() public {
        vm.startPrank(alice);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        uint256 aliceShares = vault.shares(alice);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                MyVault.InsufficientShares.selector,
                aliceShares + 1,
                aliceShares
            )
        );
        vault.withdraw(aliceShares + 1);
    }

    // Test proporsi shares untuk dua depositor
    function test_SharesProportionMultipleDepositors() public {
        // Alice deposit dulu
        vm.startPrank(alice);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Bob deposit jumlah yang sama
        vm.startPrank(bob);
        token.approve(address(vault), DEPOSIT_AMOUNT);
        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        // Shares alice dan bob harus sama
        assertEq(vault.shares(alice), vault.shares(bob));
    }

    // Test event Deposited dipancarkan dengan benar
    function test_EmitDepositedEvent() public {
        vm.startPrank(alice);
        token.approve(address(vault), DEPOSIT_AMOUNT);

        vm.expectEmit(true, false, false, true, address(vault));
        emit MyVault.Deposited(alice, DEPOSIT_AMOUNT, DEPOSIT_AMOUNT);

        vault.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();
    }
}