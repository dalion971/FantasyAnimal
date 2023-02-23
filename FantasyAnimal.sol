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

    function setStartSale() public onlyOwner { isSale = true; }
    function setStopSale() public onlyOwner { isSale = false; }
    function getSaleStatus() public view returns(bool){ return isSale; }

    function nftFantasyAnimalMint(uint256 mintNum) public payable onlyOnSale
    {
        require(mintNum * cost <= msg.value, "not enough ether");
        require(totalSupply() + mintNum <= maxSupply,"over max supply");
        require(mintNum <= nftPeerMintCnt, "limited mint num");
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
}