// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    // string[] public templates;
    mapping(uint256 => string) public templates;
    // mapping(string => mapping(uint256 => string)) public terms;
    // maps hashAddressId to boolean
    mapping(bytes32 => bool) hasAcceptedTerms;
    mapping(uint256 => string) public renderers;
    mapping(uint256 => uint256) public lastTermChange;
    // mapping of hash of key and template token ID to the value
    mapping(bytes32 => string) public terms;
    mapping(uint256 => address) public templateOwners;
    // address[] owners;

    /// @notice The default value of the global renderer.
    /// @dev The default value of the global renderer.
    string _globalRenderer = "";

    event AcceptedTerms(
        address indexed user,
        uint256 indexed templateId,
        string uri
    );
    /// @notice This event is emitted when the global renderer is updated.
    /// @dev This event is emitted when the global renderer is updated.
    /// @param _renderer The new renderer.
    event GlobalRendererChanged(string indexed _renderer);

    /// @notice Event emitted when a new token term is added.
    /// @dev Event emitted when a new token term is added.
    /// @param _term The term being added to the contract.
    /// @param _templateId The token id of the token for which the term is being added.
    /// @param _value The value of the term being added to the contract.
    event TermChanged(
        string indexed _term,
        uint256 indexed _templateId,
        string _value
    );

    /// @notice This event is emitted when the global template is updated.
    /// @dev This event is emitted when the global template is updated.
    /// @param _template The new template.
    /// @param _templateId The token id of the token for which the template is being updated.
    event TemplateChanged(
        uint256 indexed _templateId,
        string indexed _template
    );

    // change to internal later
    function hashKeyId(string memory key, uint256 templateId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(templateId, key));
    }

    // change to internal later
    function hashAddressId(address user, uint256 templateId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, templateId));
    }

    function acceptedTerms(address to, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _acceptedTerms(to, tokenId);
    }

    function _acceptedTerms(address to, uint256 templateId)
        internal
        view
        returns (bool)
    {
        bytes32 hash = hashAddressId(to, templateId);
        return hasAcceptedTerms[hash];
    }

    function acceptTerms(uint256 tokenId, string memory newTemplateUrl)
        external
    {
        _acceptTerms(tokenId, newTemplateUrl);
    }

    function _acceptTerms(uint256 _templateId, string memory _newtemplateUrl)
        internal
        virtual
    {
        require(
            keccak256(bytes(_newtemplateUrl)) ==
                keccak256(bytes(_templateUrl(_templateId))),
            "Terms Url does not match"
        );
        bytes32 hash = hashAddressId(msg.sender, _templateId);
        hasAcceptedTerms[hash] = true;
        emit AcceptedTerms(msg.sender, _templateId, _templateUrl(_templateId));
    }

    function templateUrl(uint256 templateId)
        external
        view
        returns (string memory)
    {
        return _templateUrlWithPrefix(templateId, "ipfs://");
    }

    function _templateUrl(uint256 templateId)
        internal
        view
        returns (string memory)
    {
        return _templateUrlWithPrefix(templateId, "ipfs://");
    }

    function _templateUrlWithPrefix(uint256 templateId, string memory prefix)
        internal
        view
        returns (string memory _templateUrl)
    {
        _templateUrl = string(
            abi.encodePacked(
                prefix,
                _renderer(templateId),
                "/#/",
                _template(templateId),
                "::",
                Strings.toString(block.chainid),
                "::",
                Strings.toHexString(uint160(address(this)), 20),
                "::",
                Strings.toString(lastTermChange[templateId]),
                "::",
                Strings.toString(templateId)
            )
        );
    }

    function templateUrlWithPrefix(uint256 tokenId, string memory prefix)
        public
        view
        returns (string memory)
    {
        return _templateUrlWithPrefix(tokenId, prefix);
    }

    function _renderer(uint256 _tokenId) internal view returns (string memory) {
        if (bytes(renderers[_tokenId]).length == 0) return _globalRenderer;
        else return renderers[_tokenId];
    }

    function _template(uint256 _tokenId) internal view returns (string memory) {
        // if (bytes(templates[_tokenId]).length == 0) return _globalDocTemplate;
        // else return templates[_tokenId];
        return templates[_tokenId];
    }

    function _setGlobalRenderer(string memory _newGlobalRenderer) internal {
        _globalRenderer = _newGlobalRenderer;
    }

    function setGlobalRenderer(string memory _newGlobalRenderer)
        external
        onlyOwner
    {
        _setGlobalRenderer(_newGlobalRenderer);
    }

    function setTemplate(uint256 _templateId, string memory _newTemplate)
        external
        onlyTemplateOwner(_templateId)
    {
        templates[_templateId] = _newTemplate;
        emit TemplateChanged(_templateId, _newTemplate);
    }

    function setTerm(
        uint256 _templateId,
        string memory _key,
        string memory _value
    ) external onlyTemplateOwner(_templateId) {
        bytes32 hash = hashKeyId(_key, _templateId);
        terms[hash] = _value;
        emit TermChanged(_key, _templateId, _value);
    }

    modifier onlyTemplateOwner(uint256 _templateId) {
        require(
            templateOwners[_templateId] == msg.sender,
            "Not template owner"
        );
        _;
    }

    // function
}