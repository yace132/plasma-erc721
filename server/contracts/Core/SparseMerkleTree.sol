pragma solidity ^0.4.24;


// Based on https://rinkeby.etherscan.io/address/0x881544e0b2e02a79ad10b01eca51660889d5452b#code
contract SparseMerkleTree {

    uint8 constant DEPTH = 64;
    bytes32[DEPTH + 1] public defaultHashes;

    constructor() public {
        // defaultHash[0] is being set to keccak256(uint256(0));
        defaultHashes[0] = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
        setDefaultHashes(1, DEPTH);
        // 在合約創造時先算好defaulthashes
    }

    function checkMembership(
        bytes32 leaf,
        bytes32 root,
        uint64 tokenID,
        bytes proof) public view returns (bool)
    {
        bytes32 computedHash = getRoot(leaf, tokenID, proof);
        return (computedHash == root);
    }

    // first 64 bits of the proof are the 0/1 bits
    function getRoot(bytes32 leaf, uint64 index, bytes proof) public view returns (bytes32) {
        require((proof.length - 8) % 32 == 0 && proof.length <= 2056);
        bytes32 proofElement;
        bytes32 computedHash = leaf;
        uint16 p = 8;
        uint64 proofBits;
        assembly {proofBits := div(mload(add(proof, 32)), exp(256, 24))}
        //proofBits用一連串0,1表示merkle tree路徑上的節點是否為空
        //可參考 https://ethresear.ch/t/plasma-cash-with-sparse-merkle-trees-bloom-filters-and-probabilistic-transfers/2006
        

        for (uint d = 0; d < DEPTH; d++ ) {
            if (proofBits % 2 == 0) { // check if last bit of proofBits is 0
                proofElement = defaultHashes[d]; //空的節點用defaultHash
            } else {
                p += 32;
                require(proof.length >= p);
                assembly { proofElement := mload(add(proof, p)) } //有東西的節點就去讀hash值
            }
            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            proofBits = proofBits / 2; // shift it right for next bit
            index = index / 2; //index代表一路上走左邊或右邊，在sparse merkle tree裡，即slot，coin的真正id
        }
        return computedHash;
    }

    function setDefaultHashes(uint8 startIndex, uint8 endIndex) private {
        for (uint8 i = startIndex; i <= endIndex; i ++) {
            defaultHashes[i] = keccak256(abi.encodePacked(defaultHashes[i-1], defaultHashes[i-1]));
        }
    }
}
