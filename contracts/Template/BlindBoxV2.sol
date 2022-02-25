// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../lib/InitializableOwnable.sol";
import "../interfaces/INFTFactory.sol";
import "../ERC1155/ERC1155.sol";


contract BlindBoxV2 is ERC1155, InitializableOwnable, Pausable {

    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // EnumerableSet.UintSet private pools;
    address public factory;

    uint256 public nextTokenId;
    string public boxURI;
    string public baseURI;

    uint256 public maxSupply;
    uint256[] public perSupplys;
    address[] public erc20Tokens;
    mapping (address=>uint256) tokensSupply;
    mapping (uint256=>EnumerableSet.UintSet) private pools;
    // mapping (address=>EnumerableSet.UintSet) private tokenPools;

    struct SaleConfig {
        uint256  startTime;
        uint256  endTime;
        address  saleToken;
        uint256  salePrice;
        address  treasury;
    }

    struct boxState {
        bool isOpen;
        mapping (uint256=>EnumerableSet.UintSet) realTokenId;
    }

    // Mapping from blindbox token ID to index of the token ID
    mapping(uint256 => boxState) private boxStatus;
    SaleConfig public saleConfig;


    event SaleConfigChanged(uint256 startTime, uint256 endTime, address saleToken, uint256 salePrice, address treasury);
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    event BaseURIChanged(string newBaseURI);
    event BoxURIChanged(string newBoxURI);
    event SaleMint(address minter, uint256 tokenId);
    event Open(address owner, uint256 boxId, uint256[][] tokenId, uint256[] amounts);

    
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }

    function initialize(
        address[3] memory _addressConfigs,
        uint256[4] memory _saleSettings,
        uint256[] memory _perSupplys,
        address[] memory _erc20Tokens,
        uint256[] memory _tokensSupply,
        // string memory name,
        // string memory symbol,
        string memory _boxURI,
        string memory _baseURI
    ) public {
        InitializableOwnable._initialize();
        transferOwnership(_addressConfigs[0]);
        maxSupply = _saleSettings[3];
        for (uint256 i = 0; i < _perSupplys.length; i++) {
            perSupplys[i] = _perSupplys[i];
        }

        for (uint256 i = 0; i < _erc20Tokens.length; i++) {
            erc20Tokens[i] = _erc20Tokens[i];
            tokensSupply[erc20Tokens[i]] = _tokensSupply[i];
            IERC20(erc20Tokens[i]).transferFrom(_msgSender(), address(this), _tokensSupply[i] * maxSupply);
        }

        saleConfig = SaleConfig({
            startTime: _saleSettings[0],
            endTime: _saleSettings[1],
            saleToken: _addressConfigs[1],
            salePrice: _saleSettings[2],
            treasury: _addressConfigs[2]
        });
        // _name = name;
        // _symbol = symbol;
        boxURI = _boxURI;
        _setURI(_baseURI);

        factory = _msgSender();
    }

    function setUpSale(
        uint256 _startTime,
        uint256 _endTime,
        address _saleToken,
        uint256 _salePrice,
        address _treasury
    )external onlyOwner {
        require(_startTime > block.timestamp, "invalid start time");
        require(_endTime > _startTime, "invalid end time");

        saleConfig = SaleConfig({
            startTime: _startTime,
            endTime: _endTime,
            saleToken: _saleToken,
            salePrice: _salePrice,
            treasury: _treasury
        });

        emit SaleConfigChanged(_startTime, _endTime, _saleToken, _salePrice, _treasury);
    }



    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseURIChanged(newbaseURI);
    }

    function setBoxURI(string calldata newboxURI) external onlyOwner {
        boxURI = newboxURI;
        emit BoxURIChanged(newboxURI);
    }

    function mint(uint256 count, uint8 v, bytes32 r, bytes32 s) external payable onlyEOA {
        bytes32 messageHash = keccak256(abi.encodePacked(this, _msgSender(), count));
        require(INFTFactory(factory).verifySignedMessage(messageHash, v, r, s),"BlindBox: signer should sign buyer address and tokenId");

        // Gas optimization
        uint256 _nextTokenId = nextTokenId;

        // Make sure sale config has been set up
        SaleConfig memory _saleConfig = saleConfig;
        require(_saleConfig.startTime > 0, "BlindBox: sale not configured");
        require(_saleConfig.salePrice > 0, "BlindBox: sale price not set");
        require(_saleConfig.treasury != address(0), "BlindBox: treasury not set");
        require(count > 0, "BlindBox: invalid count");
        require(block.timestamp >= _saleConfig.startTime, "BlindBox: sale not started");
        require(block.timestamp <= _saleConfig.endTime, "BlindBox: sale already end");

        require(_nextTokenId + count <= maxSupply, "BlindBox: max supply exceeded");
        if (_saleConfig.saleToken == address(0)) {
            require(_saleConfig.salePrice * count == msg.value, "BlindBox: incorrect Ether value");
            // The contract never holds any Ether. Everything gets redirected to treasury directly.
            payable(_saleConfig.treasury).transfer(msg.value);
        }else{
            uint256 amount = _saleConfig.salePrice * count;
            IERC20(_saleConfig.saleToken).safeTransferFrom(_msgSender(), _saleConfig.treasury, amount);
        }

        for (uint256 ind = 0; ind < count; ind++) {
            // _safeMint(_msgSender(), _nextTokenId + ind);
            // _mint(_msgSender(), id, amount, data);

            for (uint256 j = 0; j < perSupplys.length; j++) {
                uint256 itemCount = perSupplys[j] / maxSupply;
                for (uint256 k = 0; k < itemCount; k++) {
                    _mint(_msgSender(), j, _nextTokenId + ind + j + k, "");
                    pools[j].add( _nextTokenId + ind + j + k);
                }
            }

            // for (uint256 j = 0; j < erc20Tokens.length; j++) {
            //     uint256 totalAmount = tokensSupply[erc20Tokens[j]] / maxSupply;
            //     // IERC20(erc20Tokens[j])
            // }
            // pools.add(_nextTokenId + ind);
        }

        nextTokenId += count;

        emit SaleMint(_msgSender(), _nextTokenId);
    }

    function _generateSignature(uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt)));
    }


    function open(uint256 _boxTokenId, uint8 v, bytes32 r, bytes32 s) external onlyEOA {

        // require(ownerOf(_boxTokenId) == _msgSender(), "BlindBox: not owner");
        require(boxStatus[_boxTokenId].isOpen == false, "BlindBox: box already open");

        bytes32 messageHash = keccak256(abi.encodePacked(this, _msgSender(), _boxTokenId));
        require(INFTFactory(factory).verifySignedMessage(messageHash, v, r, s),"BlindBox: signer should sign buyer address and tokenId");

        uint256[][] memory tokenIds = new uint256[][](perSupplys.length);

        for (uint256 i = 0; i < perSupplys.length; i++) {
            for (uint256 j = 0; j < perSupplys[i]; j++) {
                uint256 salt = uint256(keccak256(abi.encodePacked(msg.sender, _boxTokenId, pools[i].length())));
                uint256 seed = _generateSignature(salt);
                uint256 randomIdx = uint256(keccak256(abi.encodePacked(seed))).mod(pools[i].length());
                uint256 tokenId = pools[i].at(randomIdx);
                pools[i].remove(tokenId);
                boxStatus[_boxTokenId].realTokenId[i].add(tokenId);
                tokenIds[i][j] = tokenId;
            }
        }

        uint256[] memory amounts = new uint256[](erc20Tokens.length);

        for (uint256 i = 0; i < erc20Tokens.length; i++) {
            IERC20(erc20Tokens[i]).transfer(msg.sender, tokensSupply[erc20Tokens[i]]);
            amounts[i] = tokensSupply[erc20Tokens[i]];
        }
        // uint256 salt = uint256(keccak256(abi.encodePacked(msg.sender, _boxTokenId, pools.length())));
        // uint256 seed = _generateSignature(salt);
        // uint256 randomIdx = uint256(keccak256(abi.encodePacked(seed))).mod(pools.length());
        // uint256 tokenId = pools.at(randomIdx);
        // pools.remove(tokenId);
        boxStatus[_boxTokenId].isOpen = true;
        // boxStatus[_boxTokenId].realTokenId = tokenId;
        emit Open(_msgSender(), _boxTokenId, tokenIds, amounts);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    //     // check blindbox status
    //     if(boxStatus[tokenId].isOpen == true){
    //         tokenId = boxStatus[tokenId].realTokenId;
    //         return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    //     }else{
    //         return bytes(boxURI).length > 0 ? string(abi.encodePacked(boxURI, tokenId.toString())) : "";
    //     }
    // }

    function setPause() external onlyOwner {
        _pause();
    }

    function unsetPause() external onlyOwner {
        _unpause();
    }

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId);

    //     require(!paused(), "ERC721Pausable: token transfer while paused");
    // }


}