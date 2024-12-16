
### **The Issue**
The contract uses the `REQUEST_CONFIRMATIONS` constant set to 3, which defines how many blocks should be waited before receiving randomness from the **Chainlink VRF** service. On the Polygon network, however, chain reorganizations can occur with depths greater than 3 blocks as we can see [here](https://polygonscan.com/blocks_forked), which introduces a risk of the winner being changed if the block containing the randomness request is reorganized. This is particularly problematic in the context of the lottery, as it could lead to different results than intended.

### **Root Cause**

Chain reorganization on the Polygon network can result in block heights being reorganized by more than 3 blocks. Since the contract is set to wait for only 3 blocks (`REQUEST_CONFIRMATIONS = 3`), there is a risk that the request for randomness may be affected by a chain reorganization. If the transaction requesting randomness is moved to a different block during a reorganization, the randomness output would change, potentially leading to a different winner than expected.

### **Mitigation**

The issue can be mitigated by increasing the value of `REQUEST_CONFIRMATIONS` to a higher number (e.g., 6 or more), which would ensure that the contract waits for enough confirmations before proceeding, reducing the likelihood that the randomness output will be affected by chain reorgs.
