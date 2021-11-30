//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Descrow.sol";

contract DescrowFactory {
	address[] public deployedContracts;
	mapping(address => address[]) userContracts;

	function createContract(address payable _buyer, address payable _seller, uint _price) public {
		address newContract = address(new Descrow( _buyer, _seller, _price));
		deployedContracts.push(newContract);
		userContracts[_buyer].push(newContract);
		userContracts[_seller].push(newContract);
	}

	function getDeployedContracts() public view returns(address[] memory) {
		return deployedContracts;
	}

	function getUserContracts (address _user) public view returns(address[] memory) {
		return userContracts[_user];
	}
}