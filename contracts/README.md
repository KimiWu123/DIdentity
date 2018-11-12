## Install
```
npm install babel-register
npm install babel-polyfill
```

## contracts

Only identity functionalities: Identity.sol

Identity with token model: IdentityWithToken.sol


Here is the dependencies

-------------------    
| IdentityImp.sol |    
-------------------   ----------------------
             \        | DelegationCall.sol |
              \       ----------------------
               \           /
                \         /
                 \       /
             -----------------          -------------------------      --------------------------------    
             | Identity.sol  |          | ERC165MappingImp.sol  |      | TokensRecipientInterface.sol |
             -----------------          -------------------------      -------------------------------- 
                    |                               |                                 |
                    |                               |                                 |  
                    -------------------|-----------------------------------------------
                                       | 
                            --------------------------    
                            | IdentityWithToken.sol  |    
                            --------------------------
