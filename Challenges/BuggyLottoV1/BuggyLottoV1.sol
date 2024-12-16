// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BuggyLottoV1 is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    address private s_recentWinner;
    bool private s_submitted;
    bool private s_prizeClaimed;
    uint256 private s_prizeAmount;

    // Events
    event LotteryEnter(address indexed player);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);
    event LotteryStateChanged(bool isOpen);
    event PrizeClaimed(address winner, uint256 amount);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) Ownable(msg.sender) ReentrancyGuard(){
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterLottery() public payable nonReentrant {
        require(msg.value >= i_entranceFee, "Not enough ETH to enter lottery");
        s_players.push(payable(msg.sender));
        emit LotteryEnter(msg.sender);
    }

    function requestRandomWinner() external onlyOwner {
        require(!s_submitted, "Random number already requested");
        require(s_players.length >= 10, "Minimum players is 10");
        
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_submitted = true;
        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_prizeAmount = address(this).balance;

        require(recentWinner == tx.origin, "Winner should be EOA");

        // Reset lottery state
        s_players = new address payable[](0);
        s_submitted = false;
        s_prizeClaimed = false;
        emit WinnerPicked(recentWinner);
    }

    function claimPrize() external nonReentrant {
        require(msg.sender == s_recentWinner, "Only winner can claim prize");
        require(!s_prizeClaimed, "Prize already claimed");
        require(s_prizeAmount > 0, "No prize to claim");
        
        uint256 prizeAmount = s_prizeAmount;
        s_prizeClaimed = true;
        s_prizeAmount = 0;
        
        (bool success,) = payable(msg.sender).call{value: prizeAmount}("");
        require(success, "Transfer failed");
        
        emit PrizeClaimed(msg.sender, prizeAmount);
    }

    // View Functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}