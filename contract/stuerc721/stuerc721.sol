// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

// NFT 基础功能
contract stuERC721 is IERC721, IERC721Metadata {
    // mapping: tokenId → 被授权操作该 token 的地址
    // 零地址 (address(0)) 表示“未授权”
    mapping(uint256 => address) private _tokenApprovals;

    // 存储授权所有的NFR到另一个地址
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // 存储tokenid 与 uri 的映射
    mapping(uint256 => string) private _tokenUriStore;

    // 记录每个用户拥有的 NFT 数量
    mapping(address => uint256) private _balances;

    // 记录每个 token 的所有者（标准 ERC-721 必须有）
    mapping(uint256 => address) private _owners;

    string private _nftName;
    string private _nftSymbol;

    // tokenId 初始值
    uint256 private _nextTokenId = 1;

    constructor(string memory nftName, string memory nftSymbol){
        _nftName = nftName;
        _nftSymbol = nftSymbol;
    }

    // 返回代币集合的名称
    function name() external view returns (string memory) {
        return _nftName;
    }

    // 返回代币集合的符号
    function symbol() external view returns (string memory) {
        return _nftSymbol;
    }

    // 返回`tokenId`代币的统一资源标识符（URI）。
    // 通常是一个指向JSON文件的URI
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenUriStore[tokenId];
    }

    // 这个方法是一个技术规范，目的是告诉调用者自己实现了接口
    // 小狐狸钱包会调用这个方法，告诉小狐狸自己实现的是一个 NFT 功能，要不然小狐狸不会正确的显示NFT图片
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // 返回用户下面的NFT 数量
    function balanceOf(address owner) external view returns (uint256 balance) {
        require(owner != address(0), unicode"地址不能为0");
        return _balances[owner];
    }

    // 返回NFT的拥有者
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        require(_owners[tokenId] != address(0), unicode"token 不存在");
        return _owners[tokenId];
    }

    // 核心转移
    // 内部函数：只做状态变更，信任调用者已通过校验
    // from 是资产来源方
    function _transfer(address from, address to, uint256 tokenId) private {
        address owner = _owners[tokenId];
        require(owner == from, unicode"token资产不属于来源方");
        require(owner != address(0), unicode"token 不存在");

        _owners[tokenId] = to;

        // token 维护, unchecked 是solidity中一个内置的检查溢出方法
        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }

        // 清除单 token 授权
        delete _tokenApprovals[tokenId];

        // 通知
        emit Transfer(from, to, tokenId);
    }

    // 附加额外数据的转移
    // 带有 安全措施的转移
    // 防止 NFT 转入不兼容合约而永久丢失
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        // 为了消除不使用的变量的警告可以不写变量名字
        require(to != address(0), unicode"转移的地址不能为0地址");
        require(_isApprovedOrOwner(msg.sender, tokenId), unicode"无权限操作");
        _transfer(from, to, tokenId);

        // 如果返回的字节码长度为0 (<address>.code.length == 0)，则该地址不是智能合约
        if(to.code.length > 0){
            
        }

    }

    // 无附加额外数据的转移
    // 带有 安全措施的转移
    // 防止 NFT 转入不兼容合约而永久丢失
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        this.safeTransferFrom(from, to, tokenId, "");
    }

    // 基础转移函数：将 NFT 从 from 转移到 to。
    // 不检查接收方是否能 "安全处理" NFT。
    // 谁可以调用？
    // token 的所有者（owner）
    // 被授权的操作者（approved operator）
    // 被授权管理该 token 的地址（approved for this token）
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(to != address(0), unicode"转移的地址不能为0地址");
        require(_isApprovedOrOwner(msg.sender, tokenId), unicode"无权限操作");
        _transfer(from, to, tokenId);
    }

    // spender ：校验的是调用者，这个调用者可以是被授权的人，也可以是资产拥有者
    // 保证操作者合法
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId]; // 会检查 token 是否存在
        if (owner == address(0)) return false; // Token 不存在
        // 只要满足一个就可以
        return (spender == owner || spender == _tokenApprovals[tokenId] || _operatorApprovals[owner][spender]);
    }

    // 授权某个地址（to）操作指定的 NFT（tokenId）
    function approve(address to, uint256 tokenId) external {
        // address(0)代表着默认值
        require(_owners[tokenId] != address(0), unicode"token 不存在");
        // 检查NFT的所有者是否是调用者
        // _operatorApprovals[_owners[tokenId]][msg.sender] 被全局授权的人使用权力授权单个 NFT给某一个地址的
        require(_owners[tokenId] == msg.sender || _operatorApprovals[_owners[tokenId]][msg.sender], unicode"该NFT不属于你,无权操作");

        _tokenApprovals[tokenId] = to;

        emit Approval(msg.sender, to, tokenId);
    }

    // 授权/取消 某地址操作所有 NFT
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 查询某个 NFT 当前被授权给了哪个地址（即谁可以操作它）
    function getApproved(uint256 tokenId) external view returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    // 查询是否全局授权给某地址
    // operator 是否被 owner 授权可以操作他名下的所有 NFT？
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    //  允许用户铸造 NFT
    function mint(string memory tokenUri) external{
        _mintTo(msg.sender, tokenUri);
    }

    // 内部复用逻辑
    function _mintTo(address to, string memory tokenUri) internal {
        require(to != address(0), unicode"不能给0地址");
        uint256 tokenId = _nextTokenId++;
        // 记录nft的所属用户
        _owners[tokenId] = to;
        _balances[to]++;
        _tokenUriStore[tokenId] = tokenUri;

        emit Transfer(address(0), to, tokenId); 
    }
}
