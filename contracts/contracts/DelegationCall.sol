pragma solidity ^0.4.24;

// This contract leverages partial EIP725 functionalities, execution and approve. Here is the reference,  
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md#identity-usage

contract DelegationCall {

    event ExecutionRequested(address _from, uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(address _from, uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(address _from, uint256 indexed executionId, bool approved);
    event ExecutionFailed(address _from, uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);


    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }
    mapping(uint256 => Execution) executions;


    function doApprove(uint256 _id, bool _approve)
    internal
    returns (bool success)
    {
        emit Approved(msg.sender, _id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;
            success = executions[_id].to.call(executions[_id].data, 0);
            if (success) {
                executions[_id].executed = true;
                emit Executed(
                    msg.sender,
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return;
            } else {
                emit ExecutionFailed(
                    msg.sender,
                    _id,
                    executions[_id].to,
                    executions[_id].value,
                    executions[_id].data
                );
                return;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    function doExecute(address _to, uint256 _value, bytes _data)
    internal
    returns (uint256 executionId)
    {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(msg.sender, executionNonce, _to, _value, _data);
        return executionNonce++;
    }
}