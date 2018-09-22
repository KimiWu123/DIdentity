 //var erc165 = artifacts.require("ERC165Query");

var token = artifacts.require("CrowdsaleToken.sol");
var prop = artifacts.require("Vote_Proposal");
var issue = artifacts.require("Vote_Issue");
var dao = artifacts.require("PubEthDAO");
var backupDao = artifacts.require("NewDAO");
var profit = artifacts.require("ProfitDistribution");

module.exports = function(deployer, network, accounts) {
   //deployer.deploy(erc165);

  var voter = accounts[1];
  var arb = accounts[2];
  deployer.deploy(backupDao);
  deployer.deploy(token).then(function() {
    return deployer.deploy(prop, 60, 1, 3, voter).then(function() {
      return deployer.deploy(issue, 3, 1, 3, voter, arb, prop.address).then(function() {
        return deployer.deploy(profit).then(function() {
          return deployer.deploy(dao, token.address, profit.address, prop.address, issue.address);
        })
      });
    });
  });
  
  // deployer.deploy(Factory).then(function(){
    //return deployer.deploy(Tokendeployer, Factory.address)
  // });
};



// module.exports = (deployer, network, accounts) => {
//   const userAddress = accounts[3];
//   deployer.deploy(BaconMaker, userAddress)
// }
