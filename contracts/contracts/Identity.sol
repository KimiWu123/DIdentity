pragma solidity ^0.4.24;

import "./IdentityImp.sol";
import "./contracts/Ownable.sol";
import "./DelegationCall.sol";


contract Identity is IdentityImp, IdentityInterface, DelegationCall, Ownable {

    modifier onlyProfileOwner(address addr)  {
        require(addr == msg.sender, "Not profile owner");
        _;
    }
    modifier onlyGrantee(bytes32 idx) {
        require(getGrantee(idx)==msg.sender, "Not grantee");
        _;
    }


    constructor() public {
    }

    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) 
    public 
    onlyOwner {
        super.doRegister(_identityHash, _pid, _encryptedInfo);
        emit Registered(_pid, now);
    }

    // TODO: CHECK SECURITY: it supposes only identity owner knows _identityHash
    function recover(bytes32 _identityHash) 
    public 
    onlyProfileOwner(msg.sender) {
        address orgPid = uidMap2Pid[_identityHash];
        super.doRecover(_identityHash, msg.sender);
        emit Recovered(orgPid, msg.sender, now);
    }

    function update(string _key, bytes _encryptedInfo) 
    public 
    onlyProfileOwner(msg.sender) {
        super.doUpdate(msg.sender, _key, _encryptedInfo);
        emit Updated(msg.sender, _key, now);
    }

    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey) 
    public 
    onlyProfileOwner(msg.sender) {
        bytes32 idx = super.doGrantTo(_to, _expiration, _encryptedRandomKey);
        emit GrantedTo(idx, msg.sender, _to, _expiration, now);
    }

    function fetchGrant(bytes32 _idx) 
    public 
    onlyGrantee(_idx) {
        emit GrantFeteched(super.doFetchGrant(_idx));
    }

    function approve(uint256 _id, bool _approve)
    public
    onlyProfileOwner(msg.sender) 
    returns (bool success) {
        return super.doApprove(_id, _approve);
    }

    function execute(address _to, uint256 _value, bytes _data)
    public
    onlyProfileOwner(msg.sender) 
    returns (uint256 executionId) {
        return super.doExecute(_to, _value, _data);
    }


    function() public {
        revert("fallback is not allowed");
    }
}
