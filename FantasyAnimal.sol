// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract FantasyAnimal is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool isSale = false;
    uint256 constant maxSupply = 5000;
    uint256 constant cost = 0.003 ether;
    uint256 constant nftPeerMintCnt = 50;
    string uriBase;
    string constant uriExtension = ".json";

    struct Buyer
    {
        // 白名单可以按需使用
        bool isAddrWhiteList;
        //  可以提前mint
        bool isPreMint;
        // 可以免费mint
        bool isFreeMint;
        // 免费mint数量
        uint256 freeMintNum;
    }
    mapping(address => Buyer) whiteListAddress;

    constructor(string memory _BaseUri) ERC721("Fantasy Animal", "FAT") 
    {
        setBaseURI(_BaseUri);
    }

    function setBaseURI(string memory _BaseUri) public onlyOwner
    {
        uriBase = _BaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return uriBase;
    }

    function tokenURI(uint256 _tokenId) override public view returns(string memory){
        _requireMinted(_tokenId);
        return string(abi.encodePacked(uriBase, Strings.toString(_tokenId + 1), ".json"));
    }

    modifier onlyOnSale(){ 
        require(isSale,"not on sale");
        _;
    }

    modifier onlyFreeMint(address addr, uint256 mintNum)
    {
        require(isAddrFreeMint(addr), "not allow free mint");
        require(getFreeMintNumBalance(addr) >= mintNum, "not enough free mint nums");
        _;
    }

    modifier onlyPremint(address addr)
    {
        require(isAddrPreMint(addr), "not allow premint");
        _;
    }

    modifier onlyWhiteList(address addr)
    {
        require(isAddrWhiteList(addr), "not whilte List Number");
        _;
    }

    function nftMint(bool isPremint, bool isFreeMint, uint256 mintNum) public payable
    {
        // isOnSale isFree isPre 三个参数互相组合会有几种情况，按需求实现
        // 搞个demo
        // 预售+免费mint
        if(isPremint && isFreeMint)
        {
            // Premint这里不考虑 onSale状态
            freeMint(mintNum);
            return;
        }
        // 仅预售
        if(isPremint)
        {
            // Premint这里不考虑 onSale状态
            preMint(mintNum);
            return;
        }
        // 仅免费mint
        if(isFreeMint)
        {
            // 非preMint需要考虑onSale状态
            require(getSaleStatus(), "not on sale");
            freeMint(mintNum);
            return;
        }

        // 都不是 那就是正常sale
        onSaleMint(mintNum);
    }

    // 特权mint 不应被继承
    function freeMint(uint256 mintNum) private onlyFreeMint(msg.sender, mintNum)
    {
        // 不校验msg.value 但还是要校验超发
        require(totalSupply() + mintNum <= maxSupply,"over max supply");
        require(mintNum <= nftPeerMintCnt, "limited mint num");
        commonMint(mintNum);

        // after free mint update num
        updateAddrFreeMintNum(msg.sender, false, mintNum); 
    }

    // 特权mint 不应被继承
    function preMint(uint256 mintNum) private onlyPremint(msg.sender)
    {
        require(totalSupply() + mintNum <= maxSupply,"over max supply");
        require(mintNum <= nftPeerMintCnt, "limited mint num");
        require(mintNum * cost <= msg.value, "not enough ether");
        commonMint(mintNum);
    }

    function onSaleMint(uint256 mintNum) internal onlyOnSale
    {
        require(totalSupply() + mintNum <= maxSupply,"over max supply");
        require(mintNum <= nftPeerMintCnt, "limited mint num");
        require(mintNum * cost <= msg.value, "not enough ether");
        commonMint(mintNum);
    }

    function commonMint(uint256 mintNum) internal
    {

        for (uint256 i = 0; i < mintNum; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw(address to) public onlyOwner {
        require(to != address(0));
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }


    function updateAddrBuyerPropertyList(address addr, bool isWhiteList, bool, bool Premint, bool canFreeMint, uint freeMintNum) public onlyOwner 
    {
        // 可调整何时addr被加入到白名单
        require(!isSale);

        whiteListAddress[addr] = Buyer(isWhiteList, Premint, canFreeMint, freeMintNum);
    }

    function removeAddrFromBuyerPropertyList(address addr) public onlyOwner 
    {
        // 可调整
        require(!isSale);
        // 需要在白名单
        whiteListAddress[addr] = Buyer(false, false , false, 0);
    }

    function isAddrWhiteList(address addr) internal view returns(bool)
    {
        return whiteListAddress[addr].isAddrWhiteList;
    }

    function isAddrFreeMint(address addr) internal view returns(bool)
    {
        return whiteListAddress[addr].isPreMint;
    }

    function isAddrPreMint(address addr) internal view returns(bool)
    {
        return whiteListAddress[addr].isFreeMint;
    }



    // 获取可以免费mint的数量余额，免费mint后，该余额会减少，该值在updateAddrWhiteList被初始化
    function getFreeMintNumBalance(address addr) public view returns(uint256) 
    {
        return whiteListAddress[addr].freeMintNum;
    }

    // 提供给特权mint 所以也不应被继承
    function updateAddrFreeMintNum(address addr, bool forward, uint256 cnt) private onlyOwner 
    {
        // forwart == true 正向，增加额度
        if(forward)
        {
            //防止上溢出
            whiteListAddress[addr].freeMintNum =  whiteListAddress[addr].freeMintNum >= type(uint256).max - cnt ? type(uint256).max : whiteListAddress[addr].freeMintNum + cnt;
        }
        // false 反向减额度
        else
        {
            // 防止下溢出
            whiteListAddress[addr].freeMintNum = whiteListAddress[addr].freeMintNum <= cnt ? 0 : whiteListAddress[addr].freeMintNum - cnt;
        }

    }

    // 加freeMint余额
    function addAddrFreeMintNum(address addr, uint256 cnt) public onlyOwner
    {
        updateAddrFreeMintNum(addr, true, cnt);
    }


    function setStartSale() public onlyOwner { isSale = true; }
    function setStopSale() public onlyOwner { isSale = false; }
    function getSaleStatus() public view returns(bool){ return isSale; }
}
