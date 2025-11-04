// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting{

    string[] public nameList;
    // 默认值是false
    mapping(string => bool) private exists;

    mapping(string => uint8) public countVote;

    // 投票
    function vote(string memory name) public {
        countVote[name]++; 
        if(!exists[name]){
            // 如果存在过就不在执行 
            exists[name] = true;
            nameList.push(name); 
        }
    }

    // 获取票数
    function getVotes(string memory name) public view returns(uint8){
        return countVote[name];
    }

    // 重置
    function resetVotes() public {
        for(uint i = 0; i < nameList.length; i++){
            countVote[nameList[i]] = 0;
        }
    }

}