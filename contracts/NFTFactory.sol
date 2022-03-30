// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/CloneFactory.sol";
import "./lib/SignerRole.sol";
import "./Template/InitializableERC1155.sol";
import "./Template/InitializableERC721.sol";
import "./Template/BlindBox.sol";
import "./Template/BlindBoxV2.sol";

contract NFTFactory is Ownable, SignerRole{

    // ============ Templates ============
    address public immutable CLONE_FACTORY;
    address public ERC721_TEMPLATE;
    address public ERC1155_TEMPLATE;
    address public ERC721_BLINDBOX;
    address public COMPLATE_BLINDBOX;

    event NewERC721(address erc721, address creator);
    event NewERC1155(address erc1155, address creator);
    event NewBlindBox(address blindbox, address creator);
    event NewBlindBoxV2(address blindbox, address creator);

    // ============ Registry ============
    mapping(address => address[]) public USER_ERC721_REGISTRY;
    mapping(address => address[]) public USER_ERC1155_REGISTRY;
    mapping(address => address[]) public USER_BLINDBOX_REGISTRY;
    mapping(address => address[]) public USER_BLINDBOX_V2_REGISTRY;

    constructor(
        address cloneFactory,
        address erc721Template,
        address erc1155Template,
        address blindboxTemplate,
        address complateBlindBoxTemplate,
        address firstSigner
    ) public {
        CLONE_FACTORY = cloneFactory;
        ERC721_TEMPLATE = erc721Template;
        ERC1155_TEMPLATE = erc1155Template;
        ERC721_BLINDBOX = blindboxTemplate;
        COMPLATE_BLINDBOX = complateBlindBoxTemplate;
        _addSigner(firstSigner);
    }

    function changeERC721Template(address newERC721Template) external onlyOwner {
        ERC721_TEMPLATE = newERC721Template;
    }

    function changeERC1155Template(address newERC1155Template) external onlyOwner {
        ERC1155_TEMPLATE = newERC1155Template;
    }

    function changeBlindBoxTemplate(address newBlindBoxTemplate) external onlyOwner {
        ERC721_BLINDBOX = newBlindBoxTemplate;
    }

    function changeComplateBlindBoxTemplate(address newBlindBoxTemplate) external onlyOwner {
        COMPLATE_BLINDBOX = newBlindBoxTemplate;
    }

    function addSigner(address account) external onlyOwner {
        _addSigner(account);
    }

    function removeSigner(address account) external onlyOwner {
        _removeSigner(account);
    }

    function verifySignedMessage(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        return _verifySignedMessage(messageHash, v, r, s);
    }

    function createERC721(
        address _admin,
        uint256 _startTime,
        uint256 _endTime,
        address _treasury,
        uint256 _maxSupply,
        address[] memory _saleToken,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) external returns (address newERC721) {
        newERC721 = ICloneFactory(CLONE_FACTORY).clone(ERC721_TEMPLATE);
        InitializableERC721(newERC721).initialize(_admin, _startTime,_endTime, _treasury,_maxSupply, _saleToken, _name, _symbol, _baseURI);
        USER_ERC721_REGISTRY[msg.sender].push(newERC721);
        emit NewERC721(newERC721, msg.sender);
    }

    function createBlindBox(
        address _admin,
        uint256 _startTime,
        uint256 _endTime,
        address _saleToken,
        uint256 _salePrice,
        address _treasury,
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        string memory _boxURI,
        string memory _baseURI
    ) external returns (address newBlindBox) {
        newBlindBox = ICloneFactory(CLONE_FACTORY).clone(ERC721_BLINDBOX);
        BlindBox(newBlindBox).initialize(_admin, _startTime, _endTime, _saleToken, _salePrice, _treasury,_maxSupply, _name, _symbol, _boxURI, _baseURI);
        USER_BLINDBOX_REGISTRY[msg.sender].push(newBlindBox);
        emit NewBlindBox(newBlindBox, msg.sender);
    }

    function createBlindBoxV2(
        address[] memory _addressConfigs,
        uint256[] memory _saleSettings,
        uint256[] memory _per721Supplys,
        uint256[] memory _per1155Supplys,
        address[] memory _erc20Tokens,
        uint256[] memory _tokensSupply,
        uint256[] memory _serverIds,
        string memory _name,
        string memory _symbol,
        string memory _boxURI,
        string memory _baseURI
    ) external returns (address newBlindBox) {
        newBlindBox = ICloneFactory(CLONE_FACTORY).clone(COMPLATE_BLINDBOX);
        BlindBoxV2(newBlindBox).initialize(
            _addressConfigs, _saleSettings, _per721Supplys, _per1155Supplys, _erc20Tokens, _tokensSupply, _serverIds, _name, _symbol, _boxURI, _baseURI
        );
        USER_BLINDBOX_V2_REGISTRY[msg.sender].push(newBlindBox);
        emit NewBlindBoxV2(newBlindBox, msg.sender);
    }

    function createERC1155(
        address _admin,
        uint256 _startTime,
        uint256 _endTime,
        address _saleToken,
        address _treasury
    ) external returns (address newERC1155) {
        newERC1155 = ICloneFactory(CLONE_FACTORY).clone(ERC1155_TEMPLATE);
        InitializableERC1155(newERC1155).initialize(_admin, _startTime, _endTime, _saleToken, _treasury);
        USER_ERC1155_REGISTRY[msg.sender].push(newERC1155);
        emit NewERC1155(newERC1155, msg.sender);
    }

}