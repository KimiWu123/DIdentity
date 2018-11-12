pragma solidity ^0.4.24;

import "./contracts/ERC165Query.sol";
import "./contracts/ERC165MappingImp.sol";

import "./contracts/TokensRecipientInterface.sol";
import "./contracts/erc/ERC20.sol";
import "./Identity.sol";


contract IdentityWithToken is Identity, ERC165MappingImp, TokensRecipientInterface {
    
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
        address from;
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
        r.from = _from;
        r.amount = _amount;
        r.data = _data;
        // TODO: support this.call(_data), _data is type of bytes
        emit TokenReceipt(idx, _to, _amount, now);
    }

    function register(bytes32 _identityHash, address _pid, bytes _encryptedInfo) public {
        super.register(_identityHash, _pid, _encryptedInfo);
        require(erc20.transfer(_pid, REG_TOKEN_INCENTIVE), "transfer failed");
    }

    function recover(bytes32 _identityHash, bytes32 _receiptId) public {
        require(tokenReceipt[_receiptId].from == msg.sender, "It's not payer");
        require(tokenReceipt[_receiptId].amount >= UPDATE_TOKEN_EXPENSE, "Not enough tokens");
        delete tokenReceipt[_receiptId];
        super.recover(_identityHash);
    }

    function update(string _key, bytes _encryptedInfo, bytes32 _receiptId) public {
        require(tokenReceipt[_receiptId].from == msg.sender, "It's not payer");
        require(tokenReceipt[_receiptId].amount >= UPDATE_TOKEN_EXPENSE, "Not enough tokens");
        delete tokenReceipt[_receiptId];
        super.update(_key, _encryptedInfo);
    }

    function grantTo(address _to, uint _expiration, bytes32 _encryptedRandomKey, bytes32 _receiptId) public {
        require(tokenReceipt[_receiptId].from == msg.sender, "It's not payer");
        require(tokenReceipt[_receiptId].amount >= GRANT_TOKEN_EXPENSE, "Not enough tokens");
        delete tokenReceipt[_receiptId];
        super.grantTo(_to, _expiration, _encryptedRandomKey);
    }

    function fetchGrant(bytes32 _idx, bytes32 _receiptId) public{
        require(tokenReceipt[_receiptId].from == super.getGrantee(_idx), "It's not payer");
        require(tokenReceipt[_receiptId].amount >= FETCH_TOKEN_EXPENSE, "Not enough tokens");

        super.fetchGrant(_idx);
        erc20.transfer(super.getGrantor(_idx), GRANT_TOKEN_EXPENSE);
    }

    function cashOut() public onlyOwner {
        uint totalBalance = erc20.balanceOf(address(this));
        erc20.transfer(owner, totalBalance);
        emit CashOut(owner, totalBalance, now);
    }

}

