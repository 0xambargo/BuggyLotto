## Changes and Fixes

### 1. Bug Fix
In the previous version, a bug related to the **Chainlink VRF system** was identified. The EOA check has now been moved from the `fulfillRandomWords()` function to the `enterLottery()` function.

### 2. Migration to Polygon Network
To reduce transaction costs and improve processing speed, the contract has been adapted for deployment on the Polygon network. This update makes the lottery system more accessible to users by leveraging Polygon's efficient infrastructure.

## **Hint for the Bug**
The bug is in the `requestRandomWinner()` function.

## Notes
Other potential vulnerabilities or issues are out of scope for this challenge.
