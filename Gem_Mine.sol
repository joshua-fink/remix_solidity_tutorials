// SPDX-License-Identifier: MIT

// pragma keyword helps to configure compiler features properly
pragma solidity ^0.8.2;

// contract - a collection of states and functions deployed on blockchain at specified address
contract GemMine {

    // functions: public-visible to other contracts
    // pure-fucntion does not modify any state
    // returns is function's return type which indicates data types returned by function
    // string keyword specifies the data type of returned value
    // memory keyword means vars of function will be stored in temporary place while function is called
    function checkStatus() public pure returns (string memory) {
        return "Mine is working with 100% accuracy";
    }

    // mapping effectively is a hash table
    mapping(uint256 => Mine) mines;
    uint256 public counter = 0;


    // user defined data type goes here
    struct Mine {
        uint256 id;
        string location;
    }

    function addMine(string memory location) public {
        counter += 1;
        mines[counter] = Mine(counter, location);
    }

    function getLocation(uint256 id) public view returns (uint256 mineID, string memory location) {
        return (mines[id].id, mines[id].location);
    }
}

// from https://dev.to/envoy_/build-your-first-smart-contract-using-solidity-111p