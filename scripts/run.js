const { utils } = require("ethers");
const { abi } = require("../artifacts/contracts/Descrow.sol/Descrow.json");

const main = async () => {

    const [owner, buyer, seller] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory('DescrowFactory');
    const descrowFactory = await factory.deploy();
    await descrowFactory.deployed();

    console.log("Contract deployed to: ", descrowFactory.address);
    console.log("Contract deployed by: ", owner.address);
    console.log("Buyer's address: ", buyer.address);
    console.log("Seller's address: ", seller.address);

    let price = utils.parseEther('10');

    let allDescrows = await descrowFactory.getAllContracts();
    console.log(allDescrows);

    let txn = await descrowFactory.createContract(buyer.address, seller.address, price);
    await txn.wait();

    let descrows = await descrowFactory.getContractsByParty(buyer.address);
    console.log(descrows);

    let descrowAddress = descrows[0];
    let descrow = new hre.ethers.Contract(descrowAddress, abi, buyer);
    let contractStatus = await descrow.getStatus();
    console.log(contractStatus);

};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    }
    catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();