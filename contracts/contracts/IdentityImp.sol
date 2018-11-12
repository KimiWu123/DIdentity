pragma solidity ^0.4.24;

interface IdentityInterface {
    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) public;
    function recover(bytes32 _identityHash) public;
    function update(string _key, bytes _encryptedInfo) public;
    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey) public;
    function fetchGrant(bytes32 _idx) public;

    event Registered(address addr, uint time);
    event Recovered(address prePid, address newPid, uint time);
    event Updated(address pid, string key, uint time);
    event GrantedTo(bytes32 indexed idx, address from, address to, uint expiration, uint time);
    event GrantFeteched(bytes32 indexed serect);
}

contract IdentityImp {

    struct PersonalProfile {
        bytes32 UID;
        mapping(string => bytes) mapInfos;
    }
    mapping(address => PersonalProfile) public personalProfile;
    mapping(bytes32 => address) internal uidMap2Pid;

    struct GrantedData {
        address grantor;
        address grantee;
        bytes32 secret;
        uint expiration;
    }
    mapping(bytes32 => GrantedData) grantedRecords;

    function doRegister(bytes32 _identityHash, address _pid, bytes _encryptedInfo)  internal {
        require(uidMap2Pid[_identityHash]==0x0, "Already registered");
        require(personalProfile[_pid].UID==0x0, "user addr registered");
        
        PersonalProfile storage p = personalProfile[_pid];
        p.UID = _identityHash;
        p.mapInfos["id"] = _encryptedInfo;
        uidMap2Pid[_identityHash] = _pid;
    }

    // update a new address in case that users lose their key.
    function doRecover(bytes32 _identityHash, address _newPid)  internal {
        require(uidMap2Pid[_identityHash]!=0x0, "user doesn't exist");
        require(_newPid != address(0x0), "new pid is nil");
        require(personalProfile[_newPid].UID==0x0, "new addr existed");
        
        address oldAddr = uidMap2Pid[_identityHash];
        PersonalProfile storage p = personalProfile[oldAddr];
        personalProfile[_newPid] = p;
        uidMap2Pid[_identityHash] = _newPid;

        delete personalProfile[oldAddr];
    }

    function doUpdate(address _user, string _key, bytes _encryptedInfo) internal {
        require(_user!=0x0, "arg user is nil");

        PersonalProfile storage p = personalProfile[_user];
        p.mapInfos[_key] = _encryptedInfo;
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

    function doFetchGrant(bytes32 _idx) internal returns(bytes32) {
        require(now < grantedRecords[_idx].expiration, "expired");
        return grantedRecords[_idx].secret;
    }

    function getGrantor(bytes32 _idx) view internal returns(address) {
        return grantedRecords[_idx].grantor;
    }
    function getGrantee(bytes32 _idx) view internal returns(address) {
        return grantedRecords[_idx].grantee;
    }
}
