const { utils } = require("ethers");

const main = async () => {

    const [owner] = await hre.ethers.getSigners();
    const factory = await hre.ethers.getContractFactory('DescrowFactory');
    const descrowFactory = await factory.deploy();
    await descrowFactory.deployed();

    console.log("Contract deployed to: ", descrowFactory.address);
    console.log("Contract deployed by: ", owner.address);

    let allDescrows = await descrowFactory.getAllContracts();
    console.log(allDescrows);

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