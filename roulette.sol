/**
 *Submitted for verification at Etherscan.io on 2017-05-14
*/
pragma solidity ^0.4.24;

contract Roulette {
    
    // Global variables
    string sWelcome;
    /* Remark: 
     *  Private Seed for generateRand(), 
     *  since this is nowhere visibile, 
     *  it's very hard to guess.
     */
    uint public privSeed; 
    struct Casino {
        address addr;
        uint balance;
        uint bettingLimitMin;
        uint bettingLimitMax;
    }
    Casino public casino;
    event ReturnValue(bytes32 myData);

    // Init Constructor
    constructor() public{
        sWelcome = "\n-----------------------------\n     Welcome to Roulette \n Got coins? Then come on in! \n-----------------------------\n";
        privSeed = 1;

        casino.addr = msg.sender;
        casino.balance = 1000*10;
        casino.bettingLimitMin = 1;
        casino.bettingLimitMax = 10;
    }
    uint[]mt;
    uint index;
    function initialize(uint seed) public {
        mt = new uint[](624);
        mt[0] = seed;
        for (uint i = 1; i < 624; i++) {
            mt[i] = uint(1812433253) * (mt[i-1] ^ (mt[i-1] >> 30)) + i;
        }
        index = 0;
    }

    function twist() private {
        uint y;
        for (uint i = 0; i < 624; i++) {
            y = (mt[i] & uint(0x80000000)) + 
                (mt[(i+1) % 624] & uint(0x7fffffff));
            mt[i] = mt[(i+397) % 624] ^ (y >> 1);
            if (y % 2 != 0) {
                mt[i] = mt[i] ^ uint(0x9908b0df);
            }
        }
    }
    function extractNumber() public returns (uint) {
        twist();
        uint y = mt[0];
        y = y ^ (y >> 11);
        y = y ^ ((y << 7) & 2636928640);
        y = y ^ ((y << 15) & 4022730752);
        y = y ^ (y >> 18);
        index = (index + 1) % 624;
        return y;
    }

    function getseed() public view returns(uint){
        return privSeed;
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function welcome() constant public returns (string) {
        return sWelcome;
    }
    function casinoBalance() constant public returns (uint) {
        return casino.balance;
    }
    function getcasinoaddr() public view returns (address){
        return casino.addr;
    }
    function casinoDeposit() payable public returns (uint){
        uint _balance = casino.balance;
        if (msg.sender == casino.addr)
            _balance = _balance + msg.value;
        else {
            _balance = _balance + msg.value;
            msg.sender.transfer(msg.value);
        }
        casino.balance = _balance;
        return casino.balance;
    }
    function casinoWithdraw(uint amount) public {
        if (msg.sender == casino.addr && amount <= casino.balance) {
            casino.balance -= amount;
            casino.addr.transfer(amount);
        }
    }
    
    // Bet on Number
    function betOnNumber(uint number) payable public returns (string) {
        // Input Handling
        // address addr = msg.sender;
        // uint betSize = msg.value;
        // if (betSize < casino.bettingLimitMin || betSize > casino.bettingLimitMax) {
        //     // Return Funds
        //     if (betSize >= 1)
        //         addr.transfer(betSize);
        //     return uint2str(betSize);
        // }
        // if (betSize * 36 > casino.balance) {
        //     // Return Funds
        //     addr.transfer(betSize);
        //     return "Casino has insufficient funds for this bet amount";
        // }
        if (number < 0 || number > 36) {
            // Return Funds
            //addr.transfer(betSize);
            emit ReturnValue(bytes32("number"));

            return "Please choose a number between 0 and 36";
        }
        // Roll the wheel
        privSeed += 1;
        uint rand = generateRand();
        if (number == rand) {
            // // Winner winner chicken dinner!
            // uint winAmount = betSize * 36;
            // casino.balance -= (winAmount - betSize);
            // addr.transfer(winAmount);
            emit ReturnValue(bytes32("winner"));
            return "winner";
        }
        else {
            //casino.balance += betSize;
            emit ReturnValue(bytes32("rand"));
            return uint2str(rand);
        }
    }
    
    // Bet on Color
    function betOnColor(uint color) payable public returns (string) {
        // Input Handling
        address addr = msg.sender;
        uint betSize = msg.value;
        if (betSize < casino.bettingLimitMin || betSize > casino.bettingLimitMax) {
            // Return Funds
            if (betSize >= 1*10)
                addr.transfer(betSize);
            return "Please choose an amount within between 1 and 10 ETH";
        }
        if (betSize * 2 > casino.balance) {
            // Return Funds
            addr.transfer(betSize);
            return "Casino has insufficient funds for this bet amount";
        }
        if (color != 0 && color != 1) {
            // Return Funds
            addr.transfer(betSize);
            return "Please choose either '0' = red or '1' = black as a color";
        }
        // Roll the wheel
        privSeed += 1;
        uint rand = generateRand();
        uint randC = (rand + 1) % 2;
        // Win
        if (rand != 0 && (randC == color)) {
            uint winAmount = betSize * 2;
            casino.balance -= (winAmount - betSize);
            addr.transfer(winAmount);
            return "Win! Good job.";
        }
        else {
            casino.balance += betSize;
            return "Wrong color.";           
        }
    }
    
    // Returns a pseudo Random number.
    function generateRand() private returns (uint) { 
        // Seeds
        privSeed = extractNumber();
        uint number = block.number; // ~ 10**5 ; 60000
        uint diff = block.difficulty; // ~ 2 Tera = 2*10**12; 1731430114620
        uint time = block.timestamp; // ~ 2 Giga = 2*10**9; 1439147273
        uint gas = block.gaslimit; // ~ 3 Mega = 3*10**6
        // Rand Number in Percent
        uint total = privSeed + number + diff + time + gas;
        uint rand = total % 37;
        return rand;
    }

    // Function to recover the funds on the contract
    function kill() public {
        if (msg.sender == casino.addr) 
            selfdestruct(casino.addr);
    }
}
