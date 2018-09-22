pragma solidity ^0.4.24;

import "./contracts/ERC165Query.sol";
import "./contracts/ERC165MappingImp.sol";
import "./contracts/Ownable.sol";
import "./contracts/TokensRecipientInterface.sol";
import "./contracts/erc/ERC20.sol";


interface GovernmentInterface {
    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) public;
    function update(bytes32 _identityHash, address _prePid, address _newPid, bytes _encryptedInfo) public;
    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey) public;
    function fetchGrant(bytes32 _idx) public view returns(bytes32);

    event Registered(address addr, uint time);
    event Updated(address prePid, address newPid, uint time);
    event GrantedTo(bytes32 indexed idx, address from, address to, uint expiration, uint time);
}

contract GovernmentImp {

    struct PersonalProfile {
        bytes32 UID;
        bytes info;
    }
    mapping(address => PersonalProfile) public personalProfile;
    mapping(bytes32 => address) internal uidMap2Pid;

    struct GrantedData {
        address grantor;
        address grantee;
        bytes32 secret;
        uint expiration;
    }
    mapping(bytes32 => GrantedData) public grantedRecords;

    function doRegister(bytes32 _identityHash, address _pid, bytes _encryptedInfo)  internal {
        require(uidMap2Pid[_identityHash]==0x0, "Already registered");
        require(personalProfile[_pid].UID==0x0, "user addr registered");
        
        PersonalProfile storage p = personalProfile[_pid];
        p.UID = _identityHash;
        p.info = _encryptedInfo;
        uidMap2Pid[_identityHash] = _pid;
    }

    function doUpdate(bytes32 _identityHash, address _newPid, bytes _encryptedInfo)  internal {
        require(uidMap2Pid[_identityHash]!=0x0, "user doesn't exist");
        require(personalProfile[_newPid].UID!=0x0, "new addr existed");

        PersonalProfile storage p = personalProfile[uidMap2Pid[_identityHash]];
        // update a new address in case that users lose their key.
        if(_newPid != address(0x0))
            p = personalProfile[_newPid];
        p.UID = _identityHash;
        p.info = _encryptedInfo;
        uidMap2Pid[_identityHash] = _newPid;
    }

    function doGrantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey) internal returns(bytes32) {
        require(personalProfile[msg.sender].UID.length != 0, "<from> user doesn't exist");
        require(personalProfile[_to].UID.length != 0, "<to> user doesn't exist");

        bytes32 idx = keccak256(abi.encodePacked(msg.sender, _to, _expiration, _encryptedRandomKey));
        GrantedData storage p = grantedRecords[idx];
        p.grantor = msg.sender;
        p.grantee = _to;
        p.expiration = _expiration;
        p.secret = _encryptedRandomKey;
        return idx;
    }

    function doFetchGrant(bytes32 _idx) internal view returns(bytes32) {
        require(now < grantedRecords[_idx].expiration, "expired");
        return grantedRecords[_idx].secret;
    }

    function getGrantor(bytes32 _idx) view internal returns(address) {
        return grantedRecords[_idx].grantor;
    }
}

contract Government is GovernmentImp, GovernmentInterface, Ownable {

    constructor() public {
    }

    modifier onlyProfileOwner(address addr)  {
        require(addr == msg.sender, "Not profile owner");
        _;
    }
    modifier onlyGrantee(bytes32 idx) {
        require(grantedRecords[idx].grantee==msg.sender, "Not grantee");
        _;
    }

    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) public onlyOwner {
        super.doRegister(_identityHash, _pid, _encryptedInfo);
        emit Registered(_pid, now);
    }

    function update(bytes32 _identityHash, address _newPid, bytes _encryptedInfo) public onlyOwner {
        address orgPid = uidMap2Pid[_identityHash];
        super.doUpdate(_identityHash, _newPid, _encryptedInfo);
        emit Updated(orgPid, _newPid, now);
    }

    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey) public onlyProfileOwner(msg.sender) {
        bytes32 idx = super.doGrantTo(_to, _expiration, _encryptedRandomKey);
        emit GrantedTo(idx, msg.sender, _to, _expiration, now);
    }

    function fetchGrant(bytes32 _idx) public view /*onlyGrantee(_idx)*/ returns(bytes32) {
        return super.doFetchGrant(_idx);
    }
}

contract GovernmentWithToken is Government, ERC165MappingImp, TokensRecipientInterface {
    
    event TokenReceipt(bytes32 indexed receiptId, address to, uint amount, uint time);
    event CashOut(address receiver, uint amount, uint time);
    

    uint serial = 0;
    ERC20 erc20;
    uint8 private constant ID_MASK = 0xF;
    uint private constant BYTES32_MASK = 0xFFFFFFFF;
    uint private constant TOKEN_DECIMAL = 10**18;
    uint private constant REG_TOKEN_INCENTIVE = 1000 * TOKEN_DECIMAL;
    uint private constant UPDATE_TOKEN_EXPENSE = 10 * TOKEN_DECIMAL;
    uint private constant GRANT_TOKEN_EXPENSE = 10 * TOKEN_DECIMAL;
    uint private constant FETCH_TOKEN_EXPENSE = 50 * TOKEN_DECIMAL;

    struct ReceiptContent {
        address to;
        uint amount;
        bytes32 data;
    }
    mapping(bytes32 => ReceiptContent) private tokenReceipt;
    

    constructor (address token) public {
        erc20 = ERC20(token);
    }

    function tokensReceived(address _from, address _to, uint _amount, bytes32 _data) external returns (bool) {
        bytes32 idx = keccak256(abi.encodePacked(serial++, _from, gasleft(), now));
        ReceiptContent storage r = tokenReceipt[idx];
        r.to = _to;
        r.amount = _amount;
        r.data = _data;
        // TODO: support this.call(_data), _data is type of bytes
        emit TokenReceipt(idx, _to, _amount, now);
    }

    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) public {
        super.register(_identityHash, _pid, _encryptedInfo);
        require(erc20.transfer(_pid, REG_TOKEN_INCENTIVE), "transfer failed");
    }

    function update(bytes32 _identityHash, address _newPid, bytes _encryptedInfo, bytes32 _receiptId) public {
        require(tokenReceipt[_receiptId].to == address(this), "Haven't got tokens");
        require(tokenReceipt[_receiptId].amount >= UPDATE_TOKEN_EXPENSE, "Not enough tokens");
        delete tokenReceipt[_receiptId];
        super.update(_identityHash, _newPid, _encryptedInfo);
    }

    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey, bytes32 _receiptId) public {
        require(tokenReceipt[_receiptId].to == address(this), "Haven't got tokens");
        require(tokenReceipt[_receiptId].amount >= GRANT_TOKEN_EXPENSE, "Not enough tokens");
        delete tokenReceipt[_receiptId];
        super.grantTo(_to, _expiration, _encryptedRandomKey);
    }

    function fetchGrant(bytes32 _idx, bytes32 _receiptId) public view returns(bytes32) {
        require(tokenReceipt[_receiptId].to == super.getGrantor(_idx), "Haven't got tokens");
        require(tokenReceipt[_receiptId].amount >= FETCH_TOKEN_EXPENSE, "Not enough tokens");

        // TODO: transfer tokens to data owner and fetch count limit?
        return super.fetchGrant(_idx);
    }

    function cashOut() public onlyOwner {
        uint totalBalance = erc20.balanceOf(address(this));
        erc20.transfer(owner, totalBalance);
        emit CashOut(owner, totalBalance, now);
    }

}

