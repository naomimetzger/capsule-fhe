// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@fhenixprotocol/contracts/FHE.sol";

contract TimeCapsule {

    struct Capsule {
        string name;
        uint256 unlockDate;
        uint8 threshold;
        uint8 signCount;
        bool decrypted;
        address[] members;
    }

    Capsule[] public capsules;

    mapping(uint256 => mapping(address => euint256)) private messages;
    mapping(uint256 => mapping(address => bool)) public submitted;
    mapping(uint256 => mapping(address => bool)) public signed;
    mapping(uint256 => mapping(address => bool)) public isMember;
    mapping(uint256 => mapping(address => string)) public revealed;

    function createCapsule(string calldata name, address[] calldata members, uint8 threshold, uint256 unlockDate) external returns (uint256 id) {
        id = capsules.length;
        capsules.push(Capsule(name, unlockDate, threshold, 0, false, members));
        for (uint i = 0; i < members.length; i++) isMember[id][members[i]] = true;
    }

    function submitMessage(uint256 id, inEuint256 calldata msg) external {
        require(isMember[id][msg.sender] && !submitted[id][msg.sender]);
        messages[id][msg.sender] = FHE.asEuint256(msg);
        submitted[id][msg.sender] = true;
    }

    function signUnlock(uint256 id) external {
        Capsule storage c = capsules[id];
        require(isMember[id][msg.sender] && !signed[id][msg.sender]);
        require(block.timestamp >= c.unlockDate && !c.decrypted);
        signed[id][msg.sender] = true;
        c.signCount++;
        if (c.signCount >= c.threshold) {
            c.decrypted = true;
            for (uint i = 0; i < c.members.length; i++) {
                address m = c.members[i];
                if (submitted[id][m]) revealed[id][m] = _toString(FHE.decrypt(messages[id][m]));
            }
        }
    }

    function getCapsule(uint256 id) external view returns (string memory, uint256, uint8, uint8, bool, address[] memory) {
        Capsule storage c = capsules[id];
        return (c.name, c.unlockDate, c.threshold, c.signCount, c.decrypted, c.members);
    }

    function _toString(uint256 v) internal pure returns (string memory) {
        if (v == 0) return "0";
        uint256 t = v; uint256 d;
        while (t != 0) { d++; t /= 10; }
        bytes memory b = new bytes(d);
        while (v != 0) { b[--d] = bytes1(uint8(48 + v % 10)); v /= 10; }
        return string(b);
    }
}
