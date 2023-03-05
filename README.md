# FantasyAnimal
第一个项目 完整参与

## 补充

在写合约的时候测试发现，循环mint的操作消耗gas较高，看oz的源码发现gas高的核心问题是
1：oz用数组保存了tokenid 与 addrss的映射关系，并且每次循环都要更新映射，对数组操作的开销高，如果id是顺序自增的话，可以从数组降为map，节省gas
2：ERC721未提供批量mint的功能，在ERC1155中有。为了在ERC721批量mint不得不用循环，而oz内部有些事情在批量的时候可以合为一去做，比如id增加，从而节省gas
找了下 果然有人已经解决了这个问题
https://github.com/chiru-labs/ERC721A

## NFT 图片合成

https://github.com/AppsusUK/NFT-Art-Generator.git
能够生成图片，metadata，调整稀有度参数，不过在图片传完ipfs后，要手动写脚本更新json，并不复杂

```python

import os
import json

data = {"json": ....}

buri1 = '<ipfs cid>'
buri2 = ''
buri3 = ''
buri4 = ''
buri5 = ''
for i in range(1,5001):
    path = r'./metadata/' + str(i) + r'.json'
    with open(path, 'r') as f:
        data = json.load(f)
        data['image'] = "ipfs://" + buri1 + '/' + str(i) + r'.png'
        f.close()
    with open(path, 'w') as f:
        json.dump(data, f)
        f.close()
```

https://github.com/HashLips/hashlips_art_engine.git
这个工具提供多个脚本，可以一键更新image的链接

## IPFS 上传
最开始放本地IPFS的，但可能是网络不好，公共网关一直访问不了，不知道自己是否ipfs同步成功。后面改用的pinata

## ERC721合约
主要是继承自oz，没什么好说的。主要和NFT相关的主要是BaseUri的设置，NFT市场销售会访问这个。第一个项目的需求比较简单，设定好价格，mint上限，mint开关即可。后面项目逐渐把预售、白名单之类的功能也都补齐

### 补充功能预售、免费mint 

## 合约测试（abi）
主要用的web3的库，后面了解到有一些集成的框架比如thirdweb，后面再去了解下

```python

import web3

w3 = web3.Web3(web3.HTTPProvider('https://goerli.infura.io/v3/<infura key>'))
print("W3 start", w3.is_connected())
abi = """
[...abi...]
"""
contract_addr = "<...>"

c = w3.eth.contract(contract_addr, config="",default_priv_key=key, abi=abi)

print("saleStatus:", c.caller().getSaleStatus())

```


## 合约验证与发布（开源）
因为是用remix写的，并且在里面import 了 oz的库，单合约是不行的。
第一想法是用remix插件去验证，但总是提示network error 无奈放弃。 因为没有用truffle这样的框架部署合约，还不太方便用truffle插件
后面采取了一个笨方法，把合约依赖的所有oz的库文件全部down到本低，把所有的import 路径全部改为同级目录下

比如 ERC721.sol改为这样的。
```solidity
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
```
所有都改完再上传验证就能通过了。




