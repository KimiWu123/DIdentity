pragma solidity ^0.4.24;

interface TokensRecipientInterface {
    event TokenReceived(address indexed user, uint amount, uint time);
    function tokensReceived(address _from, address _to, uint _amount, bytes32 _data) external returns (bool);
}

