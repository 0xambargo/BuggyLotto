### **The Issue**
The `fulfillRandomWords()` function, which reverts if the winner is a contract:

- **Chainlink VRF:** Chainlink’s VRF system requires the `fulfillRandomWords` function to **never revert**. If it does, Chainlink will not retry the call, leaving the contract in a broken state.
you can check this in Chainlink's [documentation](https://docs.chain.link/vrf/v2/security#fulfillrandomwords-must-not-revert).
- **State Lock:** The `requestRandomWinner()` function sets the `s_submitted` flag to `true`. Since `s_submitted` is reset to `false` only when `fulfillRandomWords()` completes successfully, a revert in `fulfillRandomWords()` leaves the contract stuck in an unusable state.
- **Denial of Service (DoS):** The stuck `s_submitted` flag prevents the owner from requesting another random number, trapping users' ETH in the contract indefinitely.

### **Root Cause**
The `fulfillRandomWords()` function includes this line:
```solidity
require(recentWinner == tx.origin, "Winner should be EOA");
```
This condition ensures that the winner must be an wallet (EOA). If the randomly chosen winner is a smart contract, the function reverts, causing the issue described above.

### **Mitigation**
We need to move the `require` condition to the `enterLottery()` function:
```diff
    function enterLottery() public payable nonReentrant {
+        require(msg.sender == tx.origin, "Winner should be EOA");
        require(msg.value >= i_entranceFee, "Not enough ETH to enter lottery");
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_prizeAmount = address(this).balance;

-       require(recentWinner == tx.origin, "Winner should be EOA");

        // Reset lottery state
        s_players = new address payable[](0);
        s_submitted = false;
        s_prizeClaimed = false;
        emit WinnerPicked(recentWinner);
    }
```