// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "hardhat/console.sol";

    /* Errors */
    error Lottery__TIME_PERIOD_HASNT_ENDED(uint256 _timeEnds);
    error Lottery__TransferFailed();
    error Lottery__Send_More_To_Enter_Lottery();
    error Lottery__NotOpen();
    error Lottery__NoEntries();
    error Lottery___has_ended();
    error number_out_of_range();
  /* @title Decentralised Lottery
  / @author Fraxima1ist
  / Forked from https://github.com/PatrickAlphaC/hardhat-smartcontract-lottery-fcc
  / @notice Decentralised lottery that can't be tampered with
  / @dev uses chainlink VRF2 to get random number
 */

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
      /* Type declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }   

     // Lottery Variables
    uint256 public s_lotteryNumber ;
    uint256 private s_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] public s_players;
    LotteryState private s_lotteryState;
    uint256 private  s_interval;   

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event lotteryEnterEvent(address indexed player, uint256 indexed ticket, uint256 lotteryNumer);
    event WinnerPickedEvent(address indexed player, uint256 indexed amount, uint256 lotteryNumer);

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RandomWordsfulfill(address indexed player, uint256 indexed amount);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    mapping(string => address) public numbersToAddress;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus       maps the chainlink random numbers */   
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c ;  // sepolia
    //bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f ;  // mumbai
    //bytes32 keyHash =   0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;  // polygon

    address VRF_SEOPLIA_ADDRESS =  0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    //address VRF_MUMBAI_ADDRESS =  0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
   // address VRF_POLYGON_ADDRESS =  0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    // Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
     uint32 callbackGasLimit =    2500000; //polygon

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 3 random values in one request.
    uint32 numWords = 3;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(VRF_SEOPLIA_ADDRESS) ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(VRF_SEOPLIA_ADDRESS);
        s_subscriptionId = subscriptionId;
        s_lastTimeStamp = block.timestamp;  
        s_interval = 604800;   // 1 week
        s_entranceFee = 1000000000000000 ;  // = 0.001
        s_lotteryState = LotteryState.OPEN;
        s_lotteryNumber = 1;
    }

// FUNCTIONS FOR TESTING

// ------------------------ALERT

// the time period the lotto draw is open for
   function setInterval(uint256 _interval) public{
       s_interval = _interval;
   }

  // generates the random numbers for the current lotto game
   function generateWinningNumbers() public {
       /*
    // if Lottery time period hasnt ended REVERT
    if (block.timestamp < s_lastTimeStamp + s_interval )
       { revert Lottery__TIME_PERIOD_HASNT_ENDED(s_lastTimeStamp + s_interval); }
    // put the lottery into calculatin mode
     require (s_lotteryState == LotteryState.OPEN, "Lottery is currently in calculating mode");

     */
     s_lotteryState = LotteryState.CALCULATING;  
     getRequestStatus(requestRandomWords());
   }

   // checks for duplicates , orders the winning numbers from lowest to highest
function iterateRandomWords(uint256 requestId, uint256 pozzi) public view returns (uint256) {
   // require (s_lotteryState == LotteryState.CALCULATING, "Lottery is currently open");   
    require(s_requests[requestId].exists, "request not found");
    RequestStatus memory request = s_requests[requestId];

    uint256[] memory result = new uint256[](request.randomWords.length);

    uint256 randomWord = request.randomWords[0] % 30 + 1; // Generate the first random number (cannot have a duplicate)
    result[0] = randomWord;

    for (uint256 i = 1; i < request.randomWords.length; i++) {
        // Access each random word in the array
        randomWord = request.randomWords[i] % 30 + 1;

        // Check for duplicates
        for (uint256 j = 0; j < i; j++) {
            if (randomWord == result[j]) {
                // Adjust the duplicate value to make it unique
                randomWord = (randomWord % 30) + 1;

                // Start the loop again to recheck the adjusted value with previous numbers
                j = 0; // j will be incremented to 1 in the next iteration
            }
        }

        result[i] = randomWord;
    }

    // Sort the result array from lowest to highest
    for (uint256 i = 0; i < result.length - 1; i++) {
        for (uint256 j = i + 1; j < result.length; j++) {
            if (result[i] > result[j]) {
                // Swap the values
                uint256 temp = result[i];
                result[i] = result[j];
                result[j] = temp;
            }
        }
    }

    return result[pozzi];
}


// --------------------END

    // Enter the lottery, buys however many tickets the user has selected
    function enterLottery(uint256 _num1,uint256 _num2, uint256 _num3) public payable {
        if (msg.value < (s_entranceFee )) {
            revert Lottery__Send_More_To_Enter_Lottery();
        }
        if (s_lotteryState != LotteryState.OPEN) {         // lottery needs to be in open state
            revert Lottery__NotOpen();
        }
         // if Lottery time period has ended REVERT
       if (block.timestamp > s_lastTimeStamp + s_interval ){
            revert Lottery___has_ended();
        }

        // Check if numbers are within the valid range
    require(_num1 >= 1 && _num1 <= 30, "Number 1 is out of range (1-30)");
    require(_num2 >= 1 && _num2 <= 30, "Number 2 is out of range (1-30)");
    require(_num3 >= 1 && _num3 <= 30, "Number 3 is out of range (1-30)");
    // Check for duplicates
    require(_num1 != _num2, "Numbers cannot have duplicates");
    require(_num1 != _num3, "Numbers cannot have duplicates");
    require(_num2 != _num3, "Numbers cannot have duplicates");

        // Sort the numbers
    uint256[] memory sortedNumbers = sortNumbers(_num1, _num2, _num3);

    // Convert sorted numbers to strings
    string memory num1String = uintToString(sortedNumbers[0]);
    string memory num2String = uintToString(sortedNumbers[1]);
    string memory num3String = uintToString(sortedNumbers[2]);

        // Concatenate the numbers into a string to be used as a mapping
    string memory numbersString = string(abi.encodePacked(num1String, ",", num2String, ",", num3String));
    // Check for duplicate key
    require(!hasDuplicate(numbersString), "Duplicate key found");
    // Map the numbersString to the address of the sender
    numbersToAddress[numbersString] = msg.sender;
    }

function sortNumbers(uint256 num1, uint256 num2, uint256 num3) internal pure returns (uint256[] memory) {
    uint256[] memory numbers = new uint256[](3);
    numbers[0] = num1;
    numbers[1] = num2;
    numbers[2] = num3;
    // Sort the numbers using a simple bubble sort algorithm
    for (uint256 i = 0; i < 3; i++) {
        for (uint256 j = 0; j < 2; j++) {
            if (numbers[j] > numbers[j + 1]) {
                uint256 temp = numbers[j];
                numbers[j] = numbers[j + 1];
                numbers[j + 1] = temp;
            }
        }
    }
    return numbers;
}
function hasDuplicate(string memory key) internal view returns (bool) {
    // Check if the key exists in the mapping
    // If the value type is an address, it will return the zero-initialized address if the key doesn't exist
    return numbersToAddress[key] != address(0);
}

function uintToString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
        return "0";
    }
    
    uint256 temp = value;
    uint256 digits;
    
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    
    bytes memory buffer = new bytes(digits);
    
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    
    return string(buffer);
}

  // this function gets called by anyone
  // it gets a random number from VRF chainlink oracle
  // it then calls the testWinner function which distributes the reward
  function getWinner() public{
      // if there are no entries in the lottery
      if (s_players.length < 1 )
          { s_lastTimeStamp = block.timestamp;  // if time period has ended then reset it as there have been no entries
            revert Lottery__NoEntries(); 
          }  
          // if Lottery time period hasnt ended REVERT
    if (block.timestamp < s_lastTimeStamp + s_interval )
       { revert Lottery__TIME_PERIOD_HASNT_ENDED(s_lastTimeStamp + s_interval); }

     require (s_lotteryState == LotteryState.OPEN, "Lottery is currently in calculating mode");
     s_lotteryState = LotteryState.CALCULATING;
     testWinner( requestRandomWords() );
  }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        s_lotteryState = LotteryState.CALCULATING;
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

  // returns the number of seconds remaining until the draw ends
  function claimPeriodLeft() public view returns (uint256) {
    if (s_lastTimeStamp + s_interval >  block.timestamp)
      {return (s_lastTimeStamp + s_interval - block.timestamp);}
    else {
        return 0;
    }
  }

    // this is called by the chainlink VRF may take a couple of minutes
    // you need to have funded the subscription and added the contract address to the subscription for it to work
    function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);  
    }

   // make INTERNAL FOR MAINNET
       function testWinner(uint256 _requestId  ) internal {
        if(s_players.length ==0)
        {  revert Lottery__NoEntries();
        }
        uint256 indexOfWinner = _requestId % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_lotteryNumber ++;
        uint256 prize = address(this).balance; // record how much the winner won
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
         emit WinnerPickedEvent(recentWinner, prize, s_lotteryNumber - 1);
    }

    function getRequestStatus(uint256 _requestId) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function getPlayers() public view returns(uint){
        return s_players.length;
    }

    function getPlayersFromAddress(uint256 _lotteryNumber) public view returns(bool){
        if (s_players[_lotteryNumber] == msg.sender)
        return true;
          else 
        return false;
    }

    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }

    function getLotteryState() public view returns(LotteryState){
        return s_lotteryState;
    }

}
