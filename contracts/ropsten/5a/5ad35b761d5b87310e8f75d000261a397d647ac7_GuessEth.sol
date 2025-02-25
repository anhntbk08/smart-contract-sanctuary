pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library utils{
    function inArray(uint[] _arr,uint _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
    
    function inArray(address[] _arr,address _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
    
    function addressToString(address x)  internal pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    function addresstoBytes(address a) internal pure returns (bytes b){
       assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }
    
    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}


contract Ownable {
  address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }
  

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    //emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract GuessEthEvents{
    event drawLog(uint,uint,uint);
    
     
    event evtDisburse(
        uint _amount,
        uint _numShareholders
        );
    event guessEvt(
        address indexed playerAddr,
        uint[] numbers, uint amount
        );
    event winnersEvt(
        uint blockNumber,
        address indexed playerAddr,
        uint amount,
        uint winAmount
        );
    event withdrawEvt(
        address indexed to,
        uint256 value
        );
    event drawEvt(
        uint indexed blocknumberr,
        uint number
        );
    
    event sponseEvt(
        address indexed addr,
        uint amount
        );
  
}

contract GuessEth is Ownable,GuessEthEvents{
    using SafeMath for uint;

    /* Player Bets */
    uint public betKey=0;
    
    struct bnumber{
        address addr;
        uint number;
        uint value;
        int8 result;
        uint prize;
    }
    mapping(uint => bnumber[]) public bets;
    mapping(uint => uint) public betNo;
    mapping(uint => address) public betNumber;
    
    /* player address => blockNumber[]*/
    mapping(address => uint[]) private playerBetBNumber;
    
    /* Awards Records */
    struct winner{
        bool result;
        uint prize;
    }
    
    mapping(uint => winner[]) private winners;
    mapping(uint => uint) private winResult;
    
    address private wallet1;
    address private wallet2;
    
    uint private predictBlockInterval=2;
    uint public odds=2;
    uint public blockInterval=10;
    uint public curOpenBNumber=0;
    uint public numberRange=100;

    bool public gamePaused=false;
    

    /* Sponsors */
    mapping(address => uint) Sponsors;
    uint public balanceOfSPS=0;
    address[] public SponsorAddresses;
    uint reservefund=0.02 ether;
   
  
    /**
    * @dev prevents contracts from interacting with fomo3d
    */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
    
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    constructor(address _wallet1,address _wallet2) public{
        wallet1=_wallet1;
        wallet2=_wallet2;
        
        curOpenBNumber=blockInterval*(block.number.div(blockInterval));
    }
    
    function pauseGame(bool _status) public onlyOwner returns(bool){
            gamePaused=_status;
    }
    
    function setOdds(uint _odds) isHuman() public onlyOwner returns(bool){
            odds = _odds;
    }
    
    function getTargetBNumber() view isHuman() public returns(uint){
        uint n;
        n=blockInterval*(predictBlockInterval + block.number/blockInterval);
        return n;
    }
    
    function guess(uint[] _numbers) payable isHuman() public returns(uint){
        /*
        n:destination block number at this game
        */
        
        if(msg.value  < _numbers.length * 0.05 ether){
            msg.sender.transfer(msg.value);
            return 0;
        }
        
        uint n=blockInterval*(predictBlockInterval + block.number/blockInterval);
        
        for(uint _i=0;_i < _numbers.length;_i++){
            bnumber memory b;
            
            b.addr=msg.sender;
            b.number=_numbers[_i];
            b.value=msg.value/(_numbers.length * 1.0);
            b.result=-1;
            
            bets[n].push(b);
            betKey++;
        }
        
        
        if(utils.inArray(playerBetBNumber[msg.sender],n)==false){
            playerBetBNumber[msg.sender].push(n);
        }
        
        emit guessEvt(msg.sender,_numbers, msg.value);
        
        return _numbers.length;
    }
    

    function getPlayerGuessNumbers() view public returns (uint[],uint[],uint256[],int8[],uint[]){
        uint _c=0;
        uint _i=0;
        uint _j=0;
        uint _bnumber;
        uint limitRows=100;
        
        while(_i < playerBetBNumber[msg.sender].length){
            _bnumber=playerBetBNumber[msg.sender][_i];
            for(_j=0 ; _j < bets[_bnumber].length && _c < limitRows ; _j++){
                if(msg.sender==bets[_bnumber][_j].addr){
                    _c++;
                }
            }
            _i++;
        }

        uint[] memory _blockNumbers=new uint[](_c);
        uint[] memory _numbers=new uint[](_c);
        uint[] memory _values=new uint[](_c);
        int8[] memory _result=new int8[](_c);
        uint[] memory _prize=new uint[](_c);
        
        if(_c<=0){
            return(_blockNumbers,_numbers,_values,_result,_prize);
        }

        //uint[] memory _b=new uint[](bettings[_blocknumber].length);

        uint _count=0;
        for(_i=0 ; _i < playerBetBNumber[msg.sender].length ; _i++){
            _bnumber=playerBetBNumber[msg.sender][_i];
            
            for(_j=0 ; _j < bets[_bnumber].length && _count < limitRows ; _j++){
                if(bets[_bnumber][_j].addr == msg.sender){
                    _blockNumbers[_count] = _bnumber;
                    _numbers[_count] =  bets[_bnumber][_j].number;
                    _values[_count] =  bets[_bnumber][_j].value;
                    _result[_count] =  bets[_bnumber][_j].result;
                    _prize[_count] =  bets[_bnumber][_j].prize;
                    
                    _count++;
                }
            }
        }


        return(_blockNumbers,_numbers,_values,_result,_prize);
    }
    

    function draw(uint _blockNumber,uint _blockTimestamp) public onlyOwner returns (uint){
        require(block.number >= curOpenBNumber * blockInterval);
        /*
        require(winResult[_blockNumber] == 0);
        
        
        if(bets[_blockNumber].length<=0 || _blockNumber < currentOpenBNumber){
            return 0;
        }
        
        */
        
        /*Set open Result*/
        curOpenBNumber=_blockNumber;
        uint result=_blockTimestamp % numberRange;
        winResult[_blockNumber]=result;

        for(uint _i=0;_i < bets[_blockNumber].length;_i++){
            //result+=1;
            
            
            if(bets[_blockNumber][_i].number==result){
                bets[_blockNumber][_i].result = 1;
                bets[_blockNumber][_i].prize = bets[_blockNumber][_i].value * odds;
                
                emit winnersEvt(_blockNumber,bets[_blockNumber][_i].addr,bets[_blockNumber][_i].value,bets[_blockNumber][_i].prize);

                withdraw(bets[_blockNumber][_i].addr,bets[_blockNumber][_i].prize);

            }else{
                bets[_blockNumber][_i].result = 0;
                bets[_blockNumber][_i].prize = 0;
            }
        }
        
        emit drawEvt(_blockNumber,curOpenBNumber);
        
        return result;
    }
    
    function getWinners(uint _blockNumber) view public returns(address[],uint[]){
        uint _count=winners[_blockNumber].length;
        
        address[] memory _addresses = new address[](_count);
        uint[] memory _prize = new uint[](_count);
        
        uint _i=0;
        for(_i=0;_i<_count;_i++){
            //_addresses[_i] = winners[_blockNumber][_i].addr;
            _prize[_i] = winners[_blockNumber][_i].prize;
        }
        /*
        uint _start=blockInterval*(block.number/blockInterval - 25);
        uint _end=blockInterval*(predictBlockInterval + block.number/blockInterval);
        */

        return (_addresses,_prize);
    }


    function getWinResults(uint _blockNumber) view public returns(uint){
        return winResult[_blockNumber];
    }
    
    function withdraw(address _to,uint amount) private onlyOwner returns(bool){
        require(address(this).balance.sub(amount) > 0);
        _to.transfer(amount);
        
        emit withdrawEvt(_to,amount);
        return true;
    }
    
    
    function invest() isHuman payable public returns(uint){
        require(msg.value >= 0.01 ether,"Minima amoun:0.01 ether");
        
        Sponsors[msg.sender] = Sponsors[msg.sender].add(msg.value);
        balanceOfSPS = balanceOfSPS.add(msg.value);
        
        if(!utils.inArray(SponsorAddresses,msg.sender)){
            SponsorAddresses.push(msg.sender);
        }

        return Sponsors[msg.sender];
    }
    
    function distribute() public onlyOwner{
        if(address(this).balance < reservefund){
            return;
        }
        
        uint availableProfits=address(this).balance.sub(reservefund);
        uint prft1=availableProfits.mul(3 ether).div(10 ether);
        uint prft2=availableProfits.sub(prft1);
        
        uint _val=0;
        uint _i=0;
        
        for(_i=0;_i<SponsorAddresses.length;_i++){
            _val = (prft1 * Sponsors[SponsorAddresses[_i]]) / (balanceOfSPS);
            SponsorAddresses[_i].transfer(_val);
        }
        
        uint w1p=prft2.mul(3 ether).div(10 ether);
        
        wallet1.transfer(w1p);
        wallet2.transfer(prft2.sub(w1p));
    }
    
    function sharesOfSPS() view public returns(uint,uint){
        return (Sponsors[msg.sender],balanceOfSPS);
    }
    
    function getAllSponsors() view public returns(address[],uint[],uint){
        uint _i=0;
        uint _c=0;
        for(_i=0;_i<SponsorAddresses.length;_i++){
            _c+=1;
        }
        
        address[] memory addrs=new address[](_c);
        uint[] memory amounts=new uint[](_c);

        for(_i=0;_i<SponsorAddresses.length;_i++){
            addrs[_i]=SponsorAddresses[_i];
            amounts[_i]=Sponsors[SponsorAddresses[_i]];
        }
        
        return(addrs,amounts,balanceOfSPS);
    }

    function() payable public {
    }
    
  
}