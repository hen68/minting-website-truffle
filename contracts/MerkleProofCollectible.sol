// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleProofCollectible is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_WHITELIST_MINT = 3;
    uint256 public constant PUBLIC_SALE_PRICE = .01 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .005 ether;

    string private baseTokenUri;
    string public placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Hen Project", "HEN") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Hen project :: Cannot be called by a contract"
        );
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Square Bears :: Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Hen project :: Beyond Max Supply"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Hen project :: Already minted 3 times!"
        );
        require(
            msg.value >= (PUBLIC_SALE_PRICE * _quantity),
            "Hen project :: Below "
        );

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        require(whiteListSale, "Hen project :: Minting is on Pause");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Hen projects :: Cannot mint beyond max supply"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "Hen project :: Cannot mint beyond whitelist max mint!"
        );
        require(
            msg.value >= (WHITELIST_SALE_PRICE * _quantity),
            "Hen project :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "Hen project :: You are not whitelisted"
        );

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner {
        require(!teamMinted, "Square Bears :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 200);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 trueId = tokenId + 1;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri)
        external
        onlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function togglePause() external onlyOwner {
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
