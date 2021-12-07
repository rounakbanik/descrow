//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Descrow {
    using SafeMath for uint256;

    // Cannot be modified after contract creation.
    address payable private _buyer;
    address payable private _seller;
    uint private _salePrice;
    mapping(address => uint) private _stakeAmount;

    // Contract state variables
    mapping(address => bool) private _stakeStatus;
    mapping(address => bool) private _cancelStatus;
    bool private _isActive;
    bool private _isCancelled;

    // Contract address
    address public contractAddress;

    // Get contract status at a glance
    struct ContractStatus {
        address buyer;
        address seller;
        uint salePrice;
        bool buyerStake;
        bool sellerStake;
        bool buyerCancel;
        bool sellerCancel;
        bool active;
        bool cancelled;
        address conAddr;
    }

    // Event to detect change in contract state
    event ContractStateChanged(
        address indexed buyer,
        address indexed seller,
        ContractStatus state
    );

    
    // Set buyer, seller, and price during contract creation
    constructor(address payable _buyerParty, address payable _sellerParty, uint _price) {

        // Buyer and seller can't be the same
        require(_buyerParty != _sellerParty, "Buyer and seller can't be the same");

        // Set participating parties and agreed price
        _buyer = _buyerParty;
        _seller = _sellerParty;
        _salePrice = _price;

        // Set stake amounts
        _stakeAmount[_buyer] = _salePrice.mul(2);
        _stakeAmount[_seller] = _salePrice;

        // Set contract state to active
        _isActive = true;

        // Store contract address
        contractAddress = address(this);
    } 

    modifier onlyParties() {
        require(msg.sender == _buyer || msg.sender == _seller, 
                "Function can only be invoked by participating parties.");
        
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == _buyer, "Function can only be invoked by the buyer");

        _;
    }

    modifier onlyActive() {
        require(_isActive, "Contract is not active");

        _;
    }

    modifier contractLocked(bool _status) {
        bool contractLockStatus = _stakeStatus[_buyer] && _stakeStatus[_seller];
        require(contractLockStatus == _status, "Contract status does not permit this action.");
        _;
    }

    function stake() public payable onlyParties onlyActive contractLocked(false) {

        // Reject staking if already done before
        require(!_stakeStatus[msg.sender], "Party has already staked the correct amount.");

        // Check if correct amount was sent
        require(msg.value == _stakeAmount[msg.sender], "Incorrect staking amount sent.");
        
        // Set stake status of invoking party to true
        _stakeStatus[msg.sender] = true;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Allow parties to withdraw amount if contract has not been locked yet
    function revokeStake() public payable onlyParties onlyActive contractLocked(false) {
        uint balance = address(this).balance;

        // Check if party has actually staked
        require(_stakeStatus[msg.sender], "Party does not have any amount staked.");

        // Check if contract has enough ether left to withdraw
        require(balance >= _stakeAmount[msg.sender], "Not enough ether left to withdraw.");

        // Attempt a transfer
        (bool success, ) = (msg.sender).call{value: _stakeAmount[msg.sender]}("");
        require(success, "Transfer failed.");

        // Set staking status of party to false
        _stakeStatus[msg.sender] = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Allow parties to invoke cancellation if contract has been locked
    function cancel() public payable onlyParties onlyActive contractLocked(true) {
        
        // Check if party had already cancelled before
        require(!_cancelStatus[msg.sender], "Party has already issued a cancellation request.");

        // Set cancellation status of party to true
        _cancelStatus[msg.sender] = true;

        // Check if both parties have cancelled. If yes, refund amounts and set staking to false
        if (_cancelStatus[_buyer] && _cancelStatus[_seller]) {

            // Simple sanity check to see if balance exists
            require(address(this).balance >= _salePrice.mul(3), "Not enough ether left to give out.");

            (bool buyerRefunded, ) = (_buyer).call{value: _stakeAmount[_buyer]}("");
            (bool sellerRefunded, ) = (_seller).call{value: _stakeAmount[_seller]}("");
            require(buyerRefunded && sellerRefunded, "Transfer has failed");

            // Reset stake, cancel, and confirmation status
            address payable[2] memory parties = [_buyer, _seller];

            for (uint i = 0; i < parties.length; i++) {
                _cancelStatus[parties[i]] = false;
                _stakeStatus[parties[i]] = false;
            }

            // Set contract to inactive and cancelled
            _isActive = false;
            _isCancelled = true;
        }

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Revoke cancellation if possible
    function revokeCancellation() public onlyParties onlyActive contractLocked(true) {

        require(_cancelStatus[msg.sender], "Party doesn't have a cancellation request to revoke");
        _cancelStatus[msg.sender] = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Confirm that the seller has honored the contract
    function confirm() public payable onlyBuyer onlyActive contractLocked(true) {

        // Require that no party has requested cancellation
        require(!_cancelStatus[_buyer] && !_cancelStatus[_seller], 
                "Cannot confirm as at least one party has requested cancellation.");

        // Simple sanity check to see if balance exists
        require(address(this).balance >= _salePrice.mul(3), "Not enough ether left to give out.");

        // Swap stake amounts
        (bool buyerRefunded, ) = (_buyer).call{value: _stakeAmount[_seller]}("");
        (bool sellerRefunded, ) = (_seller).call{value: _stakeAmount[_buyer]}("");
        require(buyerRefunded && sellerRefunded, "Transfer has failed");

        // Reset stake status
        _stakeStatus[_buyer] = false;
        _stakeStatus[_seller] = false;

        // Set contract to inactive
        _isActive = false;

        // Emit state change event
        emit ContractStateChanged(_buyer, _seller, getStatus());
    }

    // Get current status of contract
    function getStatus() public view returns (ContractStatus memory) {
        return ContractStatus(
            _buyer,
            _seller,
            _salePrice,
            _stakeStatus[_buyer],
            _stakeStatus[_seller],
            _cancelStatus[_buyer],
            _cancelStatus[_seller],
            _isActive,
            _isCancelled,
            contractAddress
        );
    }
}