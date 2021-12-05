//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Descrow.sol";

contract DescrowFactory {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Descrow[] public descrows;
    Counters.Counter private _contractIds;

    mapping(address => Descrow[]) public partyToContractMapping;
    mapping(address => uint ) public contractToIndexMapping;

    event ContractCreated(address indexed buyer, 
                          address indexed seller, 
                          uint price,
                          address contractAddress);

    function createContract(address payable _buyer, 
                            address payable _seller, 
                            uint _price) public {
        
        // Create a new Descrow contract
        Descrow descrow = new Descrow(_buyer, _seller, _price);

        // Store contract in an array
        descrows.push(descrow);

        // Map contract to particular index
        uint currIdx = _contractIds.current();
        address conAddr = descrow.contractAddress();
        contractToIndexMapping[conAddr] = currIdx; 
        _contractIds.increment();

        // Map contract to both parties involved
        partyToContractMapping[_buyer].push(descrow);
        partyToContractMapping[_seller].push(descrow);

        // Emit new contract creation event
        emit ContractCreated(_buyer, _seller, _price, conAddr);
    }

    // Return all contracts that a party is participating in
    function getContractsByParty(address _party) public view returns (Descrow[] memory) {
        return partyToContractMapping[_party];
    }

    // Return contract at a particular index
    function getContractByIndex(uint _index) public view returns (Descrow) {
        return descrows[_index];
    }

    // Return contract by its address
    function getContractByAddress(address _addr) public view returns (Descrow) {
        uint idx = contractToIndexMapping[_addr];
        return descrows[idx]; 
    }

    // Return all contracts
    function getAllContracts() public view returns (Descrow[] memory) {
        return descrows;
    }
}