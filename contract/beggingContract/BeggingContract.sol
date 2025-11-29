// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 已经部署的合约地址： 0xfCAa23D361bfa164137Df5c08FCc5Ce8A40d9ce0
contract BeggingContract{


    address private owner;

    // 设置开始时间和结束时间
    constructor(uint256 etime, uint256 stime) {
        owner = msg.sender;
        _setDonateTime(etime, stime);
    }


    // 1. 使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
    // 2. 记录每个捐赠者的地址和捐赠金额。
    // 3. 允许合约所有者提取所有捐赠的资金。

    //  捐赠事件：添加 Donation 事件，记录每次捐赠的地址和金额。
    event Donation(address indexed  user, uint256 amt);


    // 用于排名计算
    struct DonationDetail{
        address user;
        uint256 amt;
    }

    // 0下标最大, 记录钱数最大的前三个
    DonationDetail[3] private _topThree ;

    // mapping 来记录每个捐赠者的捐赠金额
    mapping (address => uint256) donation;

    // 开始时间
    uint256 startTime; 

    // 截至时间
    uint256 endTime; 

    // donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
    function donate() external payable {
        require(block.timestamp >= startTime,  unicode"捐赠时间未开始");
        require(block.timestamp < endTime,  unicode"捐赠时间已经结束");
        donation[msg.sender] += msg.value;
        _calculateFirstThree(msg.sender);
        emit Donation(msg.sender, msg.value);
    }

    // withdraw 函数，允许合约所有者提取所有资金。
    function withdraw(uint256 amt) external  {
        require(msg.sender == owner,  unicode"非管理者不能调用");
        require(amt <= address(this).balance, unicode"提取金额大于剩余金额");

        // 转账
        payable(msg.sender).transfer(amt); 
    }

    // getDonation 函数，允许查询某个地址的捐赠金额。
    function getDonation(address useraddr) external view returns(uint256){
        return donation[useraddr];
    }


    // 捐赠排行榜：实现一个功能，显示捐赠金额最多的前 3 个地址。
    // 返回数组如果是一个固定数量的数组 要写上固定数量，且数量与定义保持一致
    function getFirstThree() external view returns(DonationDetail[3] memory){
        return _topThree;
    }

    // 计算前三 , 不考虑并列情况
    function _calculateFirstThree(address useraddr) private {
        // 当前捐赠者总共捐赠的钱
        uint256 allAmt = donation[useraddr];

        // 捐赠者未曾在榜单中出现过
        bool nofind = true;
        for (uint i = 0; i < _topThree.length; i++) {
            if(_topThree[i].user == useraddr){
                _topThree[i] = DonationDetail({user: useraddr, amt: allAmt});
                nofind = false;
                break;
            }
        }

        if(nofind){
            for (uint i = 0; i < _topThree.length; i++) {
                if (allAmt > _topThree[i].amt) {
                    // 后移
                    for (uint j = _topThree.length - 1; j > i; j--) {
                        _topThree[j] = _topThree[j - 1];
                    }
                    _topThree[i] = DonationDetail({user: useraddr, amt: allAmt});
                    break;
                }
            }
        }

        // 冒泡排序
        for (uint i = 0; i < _topThree.length - 1; i++) {
            for (uint j = 0; j < _topThree.length - 1 - i; j++) {
                if (_topThree[j].amt < _topThree[j + 1].amt) {
                    // 交换
                    DonationDetail memory temp = _topThree[j];
                    _topThree[j] = _topThree[j + 1];
                    _topThree[j + 1] = temp;
                }
            }
        }

    }


    // 时间限制：添加一个时间限制，只有在特定时间段内才能捐赠。
    function _setDonateTime(uint256 etime, uint256 stime) private {
        require(msg.sender == owner,  unicode"非管理者不能调用");

        // 当前时间
        uint256 nowtime = block.timestamp;

        require(stime < etime, "Start time must be before end time");

        // 设置截至时间
        endTime = nowtime + etime * 1 minutes;
        // 设置起始时间
        startTime = nowtime + stime * 1 minutes;
    }

}