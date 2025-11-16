// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 基础功能
contract stuerc20 {
    string public constant name = "hulatang06"; // 代币名字
    string public constant symbol = "HLT06"; // 代币符号
    uint8 public constant decimals = 18; // 小数位数

    // 记录每个地址的余额
    mapping(address => uint256) private balances;
    // 记录授权详情 第一个adderess 授权人的地址， 第二个adderess 是被授权人的地址， value 是被授权人可以操作的余额
    mapping(address => mapping(address => uint256)) private allowance;

    // from 来源，to 目标， value 多少币
    event Transfer(address indexed from, address indexed to, uint256 value);

    // owner 持币者， spender  被授权者， value 被授权者可以操作多少币
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // 代币总量
    uint256 private _totalSupply;

    // 推荐加上这个函数
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // 铸造
    constructor(uint256 totalAmt) {
        owner = msg.sender;
        _totalSupply = totalAmt * (10 ** decimals);
        balances[msg.sender] = _totalSupply;
    }

    // balanceOf 查询账户余额 必须叫这个名字 为了在小狐狸上显示余额
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // transfer 转账, 由用户地址调用 必须叫这个名字 为了在小狐狸上转账
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // spender 授权人， value 授权的金额
    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), unicode"无效地址");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 代理转账
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        // 校验余额
        require(allowance[from][msg.sender] >= amount, unicode"授权额度不足");

        // 代理记账
        // 把授权额度设为 type(uint256).max，省gas
        if (amount != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    // mint 函数，允许合约所有者增发代币。
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18; // 例如最多 1000 万枚

    // ============ 所有者控制 ============
    address private owner;

    function mint(address to, uint256 amount) public {
        amount = amount * (10 ** decimals); //这里只是调试使用 实际代码不应该存在
        require(msg.sender == owner, unicode"无权限");
        require(to != address(0), unicode"不能增发到零地址");
        // 实际 0.8+ 不需要，但显式更安全 防止溢出
        require(_totalSupply + amount >= _totalSupply, "Uint256 overflow");
        require(amount <= MAX_SUPPLY - _totalSupply, unicode"超过最大供应量");

        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    // 真正转账的逻辑
    function _transfer(address from, address to, uint256 amount) private {
        // 检查地址是否正确
        require(from != address(0) && to != address(0), unicode"无效地址");
        require(balances[from] >= amount, unicode"余额不足");
        // 记录账户变化
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}
