import React, {  useState, useEffect } from "react";
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount,useContractRead, useWaitForTransaction } from "wagmi";
import { ethers } from "ethers";
import lotteryContract from "../contracts/Lottery.json"; // Raw ABI import (pulled from etherscan)

export default function NumberSelection() {

  const Lotto_ADDRESS = "0x08c7EdB1FC6ce100725698B343f77285b28652C0";
  const {address, isConnected} = useAccount();
  const [ethSale, setEthSale] = useState(0);  // cost of NFTs being purchased
  const [endDate, setEndDate] = useState(0);  // cost of NFTs being purchased  
  const [txHash, setTxHash] = useState(0);
  const [selectedNumbers, setSelectedNumbers] = useState([]);
  const [saleSucceeded, setSaleSucceeded] = useState(false);
  const [submitButtonText, setSubmitButtonText] = useState('Submit');

  const contractConfig = {
    address: Lotto_ADDRESS,
    abi: lotteryContract,
  };

  const { data: getEth, error: lotteryNumberError } = useContractRead({
    ...contractConfig,
    functionName: "s_lotteryNumber",
  });

  const { data: getEndDate, error: getEndDateError } = useContractRead({
    ...contractConfig,
    functionName: "claimPeriodLeft",
  });

  useEffect(() => {
    if (getEndDate) {
      let temp = getEndDate;
      setEndDate(temp);
    }
  }, [getEth]);

  useEffect(() => {
    if (getEth) {
      let temp = getEth;
      setEthSale(temp);
    }
  }, [getEth]);

const buyLottoTicket = async () => {
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const marketContract = new ethers.Contract(Lotto_ADDRESS, lotteryContract, provider);
  const marketWithSigner = marketContract.connect(signer);
  try {
    // Call buyNFT function
    setSubmitButtonText('Pending');
    let tx
     tx = await marketWithSigner.enterLottery(selectedNumbers[0],selectedNumbers[1],selectedNumbers[2], { value: ethers.utils.parseEther("0.001") });
     const receipt = await tx.wait();
     setTxHash(`https://sepolia.etherscan.io/tx/${tx.hash}`);
     setSaleSucceeded(true)
    } catch (e) {
    alert(e);
    console.log(e);
  }finally {
    // Reset the submit button text after the transaction completes
    setSubmitButtonText('Submit');
  }
};

  function selectNumber(number) {
    if (selectedNumbers.includes(number)) {
      // Number is already selected, remove it from the array
      setSelectedNumbers(selectedNumbers.filter((n) => n !== number));
    } else {
      // Number is not selected, add it to the array
      if (selectedNumbers.length < 3) {
        setSelectedNumbers([...selectedNumbers, number]);
      }
    }
  }

  const enterLotto = async () => { 
    if (selectedNumbers.length !== 3) {
      alert('Please select exactly 3 numbers.');
      return; 
  }
    buyLottoTicket()
  }

  function getDate(dt) {
    const currentDateTime = new Date(); // Get current date and time
    const milliseconds = dt * 1000;
    const dateObject = new Date(milliseconds);
  
    // Add current date to the received parameter
    dateObject.setDate(currentDateTime.getDate());
    dateObject.setMonth(currentDateTime.getMonth());
    dateObject.setFullYear(currentDateTime.getFullYear());
  
    let humanDateFormat = dateObject.toLocaleString(); // 2019-12-9 10:30:15
    return humanDateFormat;
  }

  return (
    <div>
      <ConnectButton />
      <h1 style={{ textAlign: 'center' }}>Crypto Lotto Draw # {  ethSale.toString() } </h1>
      <h1 style={{ textAlign: 'center' }}>Prizepool {  ethSale.toString() } ETH</h1>
      <h1 style={{ textAlign: 'center' }}>Draw ends {(endDate / 86400).toFixed(2)} days</h1>
      <h1 style={{ textAlign: 'center' }}>Select 3 Numbers</h1>
      <div id="numberSelection">
      <div className="numberRow">
      <button
            className={`numberButton firstRow ${selectedNumbers.includes(1) ? 'selected' : ''}`}
            onClick={() => selectNumber(1)}
            id="numberButton1"
          >
            1
          </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(2) ? 'selected' : ''}`}
    onClick={() => selectNumber(2)}
    id="numberButton2"
  >
    2
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(3) ? 'selected' : ''}`}
    onClick={() => selectNumber(3)}
    id="numberButton3"
  >
    3
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(4) ? 'selected' : ''}`}
    onClick={() => selectNumber(4)}
    id="numberButton4"
  >
    4
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(5) ? 'selected' : ''}`}
    onClick={() => selectNumber(5)}
    id="numberButton5"
  >
    5
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(6) ? 'selected' : ''}`}
    onClick={() => selectNumber(6)}
    id="numberButton6"
  >
    6
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(7) ? 'selected' : ''}`}
    onClick={() => selectNumber(7)}
    id="numberButton7"
  >
    7
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(8) ? 'selected' : ''}`}
    onClick={() => selectNumber(8)}
    id="numberButton8"
  >
    8
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(9) ? 'selected' : ''}`}
    onClick={() => selectNumber(9)}
    id="numberButton9"
  >
    9
  </button>
  <button
    className={`numberButton firstRow ${selectedNumbers.includes(10) ? 'selected' : ''}`}
    onClick={() => selectNumber(10)}
    id="numberButton10"
  >
    10
  </button>
</div>

<div className="numberRow">
  <button
    className={`numberButton ${selectedNumbers.includes(11) ? 'selected' : ''}`}
    onClick={() => selectNumber(11)}
    id="numberButton11"
  >
    11
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(12) ? 'selected' : ''}`}
    onClick={() => selectNumber(12)}
    id="numberButton12"
  >
    12
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(13) ? 'selected' : ''}`}
    onClick={() => selectNumber(13)}
    id="numberButton13"
  >
    13
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(14) ? 'selected' : ''}`}
    onClick={() => selectNumber(14)}
    id="numberButton14"
  >
    14
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(15) ? 'selected' : ''}`}
    onClick={() => selectNumber(15)}
    id="numberButton15"
  >
    15
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(16) ? 'selected' : ''}`}
    onClick={() => selectNumber(16)}
    id="numberButton16"
  >
    16
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(17) ? 'selected' : ''}`}
    onClick={() => selectNumber(17)}
    id="numberButton17"
  >
    17
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(18) ? 'selected' : ''}`}
    onClick={() => selectNumber(18)}
    id="numberButton18"
  >
    18
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(19) ? 'selected' : ''}`}
    onClick={() => selectNumber(19)}
    id="numberButton19"
  >
    19
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(20) ? 'selected' : ''}`}
    onClick={() => selectNumber(20)}
    id="numberButton20"
  >
    20
  </button>
</div>
<div className="numberRow">
  <button
    className={`numberButton ${selectedNumbers.includes(21) ? 'selected' : ''}`}
    onClick={() => selectNumber(21)}
    id="numberButton21"
  >
    21
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(22) ? 'selected' : ''}`}
    onClick={() => selectNumber(22)}
    id="numberButton22"
  >
    22
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(23) ? 'selected' : ''}`}
    onClick={() => selectNumber(23)}
    id="numberButton23"
  >
    23
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(24) ? 'selected' : ''}`}
    onClick={() => selectNumber(24)}
    id="numberButton24"
  >
    24
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(25) ? 'selected' : ''}`}
    onClick={() => selectNumber(25)}
    id="numberButton25"
  >
    25
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(26) ? 'selected' : ''}`}
    onClick={() => selectNumber(26)}
    id="numberButton26"
  >
    26
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(27) ? 'selected' : ''}`}
    onClick={() => selectNumber(27)}
    id="numberButton27"
  >
    27
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(28) ? 'selected' : ''}`}
    onClick={() => selectNumber(28)}
    id="numberButton28"
  >
    28
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(29) ? 'selected' : ''}`}
    onClick={() => selectNumber(29)}
    id="numberButton29"
  >
    29
  </button>
  <button
    className={`numberButton ${selectedNumbers.includes(30) ? 'selected' : ''}`}
    onClick={() => selectNumber(30)}
    id="numberButton30"
  >
    30
  </button>
</div>

      </div>

      <h3 style={{ textAlign: 'center' }}>
        <div id="selectedNumbers">Selected Numbers: {selectedNumbers.join(', ')}</div>
      </h3>
    {/* Submit button */}
<button
  style={{
    display: 'block',
    margin: '0 auto',
    padding: '10px 20px',
    fontSize: '16px',
    borderRadius: '5px',
    border: 'none',
    backgroundColor: '#0d6efd',
    color: '#fff',
    cursor: 'pointer',
  }}
  onClick={enterLotto}
>
{submitButtonText}
</button>
{saleSucceeded && ( 
<div>Success! Lotto ticket purchased <br /><a href={txHash} target="_blank" rel="noreferrer" className="underline underline-offset-2"
>View TX on polygonscan </a></div>
)}

    dddd { ethers.utils.formatEther(ethSale) } 
    <br />
    <a href="https://sepolia.etherscan.io/address/0x08c7EdB1FC6ce100725698B343f77285b28652C0#code">
    View Contract</a><br />
        {/* CSS Styles */}
        <style>
  {`

    .numberButton {
      margin: 5px;
      padding: 10px 15px;
      font-size: 16px;
      border-radius: 5px;
      border: 1px solid #ccc;
      background-color: #fff;
      cursor: pointer;
      flex: 1;
      text-align: center;
      max-width: 70px; /* Adjust the max-width as needed */
    }

    .numberButton.selected {
      background-color: #0d6efd;
      color: #fff;
    }

    .numberRow {
      display: flex;
      justify-content: center;
    }
  `}
</style>
    </div>
  );
}
