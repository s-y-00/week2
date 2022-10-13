//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    uint8 private constant depth = 3;
    uint256 private leafCount;
    
    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        leafCount = 2**depth;
        hashes = new uint256[](16);

        for (uint8 i = 0; i < leafCount; i++) {
            hashes[i] = 0;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < leafCount);

        hashes[index] = hashedLeaf;

        uint256 currentIndex = index;
        index++;
        uint256 nodeIndex = 0;
        uint256 left = 0;
        uint256 right = 0;
        uint256 hash = 0;

        for (uint8 i = 0; i < depth; i++) {
            // index = 0, i = 0, currentIndex=0, nodeIndex=0, left=hashes[0], right=hashes[1], hashes[8]=[left,right]
            // index = 0, i = 1, currentIndex=0, nodeIndex=8, left=hashes[8], right=hashes[9], hashes[12]=[left,right]
            // index = 0, i = 2, currentIndex=0, nodeIndex=12, left=hashes[12], right=hashes[13], hashes[14]=[left,right]
            // index = 1, i = 0, currentIndex=1, nodeIndex=0, left=hashes[0], right=hashes[1], hashes[8]=[left,right]
            // index = 1, i = 1, currentIndex=0, nodeIndex=8, left=hashes[8], right=hashes[9], hashes[12]=[left,right]
            // index = 1, i = 2, currentIndex=0, nodeIndex=12, left=hashes[12], right=hashes[13], hashes[14]=[left,right]
            
            if (currentIndex % 2 == 0) {
                left = hashes[nodeIndex + currentIndex];
                right = hashes[nodeIndex + currentIndex + 1];
                hash = PoseidonT3.poseidon([left, right]);

                hashes[nodeIndex + 2**(depth-i) + currentIndex / 2] = hash;
            } else {
                left = hashes[nodeIndex + currentIndex -1];
                right = hashes[nodeIndex + currentIndex];
                hash = PoseidonT3.poseidon([left, right]);

                hashes[nodeIndex + 2**(depth-i) + currentIndex / 2] = hash;
            }
            currentIndex = currentIndex / 2;
            nodeIndex += 2**(depth-i);
        }

        root = hash;

        return currentIndex;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root
            bool isVerified = Verifier.verifyProof(a, b, c, input);
            bool isRoot = input[0] == root;

            return isVerified && isRoot;
    }
}
