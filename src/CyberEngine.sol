// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import { EIP712 } from "./dependencies/openzeppelin/EIP712.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "./upgradeability/Initializable.sol";
import { IBoxNFT } from "./interfaces/IBoxNFT.sol";
import { IProfileNFT } from "./interfaces/IProfileNFT.sol";
import { ProfileNFT } from "./ProfileNFT.sol";
import { ISubscribeNFT } from "./interfaces/ISubscribeNFT.sol";
import { ISubscribeMiddleware } from "./interfaces/ISubscribeMiddleware.sol";
import { Auth } from "./base/Auth.sol";
import { RolesAuthority } from "./base/RolesAuthority.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Constants } from "./libraries/Constants.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC721 } from "./base/ERC721.sol";

// TODO: separate storage contract
contract CyberEngine is Initializable, Auth, EIP712, UUPSUpgradeable {
    enum State {
        Operational, // green light, all running
        EssensePaused, // cannot issue new essense, TODO: maybe remove for now
        Paused // everything paused
    }
    address public profileAddress;
    address public boxAddress;
    address public signer;
    bool public boxGiveawayEnded;
    // Shared between register and other withSig functions. Always query onchain to get the current nounce
    mapping(address => uint256) public nonces;
    address public subscribeNFTBeacon;
    State private _state;

    string private constant VERSION_STRING = "1";
    uint256 private constant VERSION = 1;

    enum Tier {
        Tier0,
        Tier1,
        Tier2,
        Tier3,
        Tier4,
        Tier5
    }
    mapping(Tier => uint256) public feeMapping;

    function initialize(
        address _owner,
        address _profileAddress,
        address _boxAddress,
        address _subscribeNFTBeacon,
        RolesAuthority _rolesAuthority
    ) external initializer {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        EIP712.__EIP712_Init("CyberEngine", VERSION_STRING);

        signer = _owner;
        profileAddress = _profileAddress;
        boxAddress = _boxAddress;
        subscribeNFTBeacon = _subscribeNFTBeacon;
        _setInitialFees();
    }

    function setSigner(address _signer) external requiresAuth {
        require(_signer != address(0), "zero address signer");
        signer = _signer;
    }

    function setProfileAddress(address _profileAddress) external requiresAuth {
        require(_profileAddress != address(0), "zero address profile");
        profileAddress = _profileAddress;
    }

    function setBoxAddress(address _boxAddress) external requiresAuth {
        require(_boxAddress != address(0), "zero address box");
        boxAddress = _boxAddress;
    }

    function setFeeByTier(Tier tier, uint256 amount) external requiresAuth {
        feeMapping[tier] = amount;
    }

    function setBoxGiveawayEnded(bool ended) external requiresAuth {
        boxGiveawayEnded = ended;
    }

    function register(
        address to,
        string calldata handle,
        DataTypes.EIP712Signature calldata sig
    ) external payable returns (uint256) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_TYPEHASH,
                        to,
                        handle,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            signer,
            sig
        );

        _requireEnoughFee(handle, msg.value);

        if (!boxGiveawayEnded) {
            IBoxNFT(boxAddress).mint(to);
        }
        return
            IProfileNFT(profileAddress).createProfile(
                to,
                // TODO: maybe use profile struct
                DataTypes.CreateProfileParams(handle, "", address(0))
            );
    }

    function withdraw(address to, uint256 amount) external requiresAuth {
        require(to != address(0), "withdraw to the zero address");
        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient balance");
        payable(to).transfer(amount);
    }

    function _setInitialFees() internal {
        feeMapping[Tier.Tier0] = Constants._INITIAL_FEE_TIER0;
        feeMapping[Tier.Tier1] = Constants._INITIAL_FEE_TIER1;
        feeMapping[Tier.Tier2] = Constants._INITIAL_FEE_TIER2;
        feeMapping[Tier.Tier3] = Constants._INITIAL_FEE_TIER3;
        feeMapping[Tier.Tier4] = Constants._INITIAL_FEE_TIER4;
        feeMapping[Tier.Tier5] = Constants._INITIAL_FEE_TIER5;
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        require(sig.deadline >= block.timestamp, "Deadline expired");
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress == expectedSigner, "Invalid signature");
    }

    function _requireEnoughFee(string calldata handle, uint256 amount)
        internal
        view
    {
        bytes memory byteHandle = bytes(handle);
        uint256 fee = feeMapping[Tier.Tier5];

        require(byteHandle.length >= 1, "Invalid handle length");
        if (byteHandle.length < 6) {
            fee = feeMapping[Tier(byteHandle.length - 1)];
        }
        require(amount >= fee, "Insufficient fee");
    }

    function subscribeWithSig(
        uint256[] calldata profileIds,
        bytes[] calldata subDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external whenNotPaused returns (uint256[] memory) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SUBSCRIBE_TYPEHASH,
                        profileIds,
                        subDatas,
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, profileIds, subDatas);
    }

    function subscribe(uint256[] calldata profileIds, bytes[] calldata subDatas)
        external
        whenNotPaused
        returns (uint256[] memory)
    {
        return _subscribe(msg.sender, profileIds, subDatas);
    }

    function _subscribe(
        address sender,
        uint256[] calldata profileIds,
        bytes[] calldata subDatas
    ) internal returns (uint256[] memory) {
        require(profileIds.length > 0, "No profile ids provided");
        require(
            profileIds.length == subDatas.length,
            "Lenght missmatch profile ids and sub datas"
        );
        uint256[] memory result = new uint256[](profileIds.length);
        for (uint256 i = 0; i < profileIds.length; i++) {
            (address subscribeNFT, address subscribeMw) = IProfileNFT(
                profileAddress
            ).getSubscribeAddrAndMwByProfileId(profileIds[i]);
            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                bytes memory initData = abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileIds[i]
                );
                subscribeNFT = address(
                    new BeaconProxy(subscribeNFTBeacon, initData)
                );
                IProfileNFT(profileAddress).setSubscribeNFTAddress(
                    profileIds[i],
                    subscribeNFT
                );
            }
            // run middleware before subscribe
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).preProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    profileIds[i],
                    sender,
                    subscribeNFT,
                    subDatas[i]
                );
            }
        }
        return result;
    }

    // State
    modifier whenNotPaused() {
        require(_state != State.Paused, "Contract is paused");
        _;
    }

    modifier whenEssensePaused() {
        require(_state != State.EssensePaused, "Essense is paused");
        _;
    }

    function getState() external view returns (State) {
        return _state;
    }

    function setState(State state) external requiresAuth {
        State preState = _state;
        _state = state;
        // TODO: emit event
    }

    // Set Metadata
    function setMetadata(uint256 profileId, string calldata metadata) external {
        require(
            msg.sender == ERC721(profileAddress).ownerOf(profileId) ||
                IProfileNFT(profileAddress).getOperatorApproval(
                    profileId,
                    msg.sender
                ),
            "Only owner or operator can set metadata"
        );
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);
    }

    // only owner's signature works
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_METADATA_TYPEHASH,
                        profileId,
                        metadata,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setMetadata(profileId, metadata);
    }

    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external {
        require(
            msg.sender == ERC721(profileAddress).ownerOf(profileId),
            "Only owner can set operator"
        );
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );
    }

    function setOperatorApprovalWithSig(
        uint256 profileId,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external {
        address owner = ERC721(profileAddress).ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                        profileId,
                        operator,
                        approved,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        IProfileNFT(profileAddress).setOperatorApproval(
            profileId,
            operator,
            approved
        );
    }

    // TODO: need test
    function upgradeProfile(address newImpl) external {
        ProfileNFT(profileAddress).upgradeTo(newImpl);
    }

    // UUPS upgradeability
    function version() external pure virtual returns (uint256) {
        return VERSION;
    }

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override requiresAuth {}
}
