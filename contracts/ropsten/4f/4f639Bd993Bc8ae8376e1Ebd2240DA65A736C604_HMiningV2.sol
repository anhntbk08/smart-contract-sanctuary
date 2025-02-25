/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;

contract TransferableToken{
    function balanceOf(address _owner) public returns (uint256 balance) ;
    function transfer(address _to, uint256 _amount) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) ;
}


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        TransferableToken token = TransferableToken(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/erc20/ERC20Impl.sol

pragma solidity >=0.4.21 <0.6.0;


contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes memory _data
    ) public;
}
contract TransferEventCallBack{
  function onTransfer(address _from, address _to, uint256 _amount) public;
}

contract ERC20Base {
    string public name;                //The Token's name: e.g. GTToken
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "GTT_0.1"; //An arbitrary versioning scheme

    using AddressArray for address[];
    address[] public transferListeners;

////////////////
// Events
////////////////
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

    event NewTransferListener(address _addr);
    event RemoveTransferListener(address _addr);

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {
        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;
        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    ERC20Base public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a ERC20Base
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    constructor(
        ERC20Base _parentToken,
        uint _parentSnapShotBlock,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // The standard ERC 20 transferFrom functionality
        if (allowed[_from][msg.sender] < _amount)
            return false;
        allowed[_from][msg.sender] -= _amount;
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != address(0)) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
        // Then update the balance array with the new value for the address
        //  receiving the tokens
        uint256 previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        // An event to make the transfer easy to find on the blockchain
        
        emit Transfer(_from, _to, _amount);
        onTransferDone(_from, _to, _amount);
        return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes memory _extraData) public returns (bool success) {
        require(approve(address(_spender), _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public view returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function _generateTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(address(0), _owner, _amount);
        onTransferDone(address(0), _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function _destroyTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, address(0), _amount);
        onTransferDone(_owner, address(0), _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function _enableTransfers(bool _transfersEnabled) internal {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function onTransferDone(address _from, address _to, uint256 _amount) internal {
      for(uint i = 0; i < transferListeners.length; i++){
        TransferEventCallBack t = TransferEventCallBack(transferListeners[i]);
        t.onTransfer(_from, _to, _amount);
      }
    }

    function _addTransferListener(address _addr) internal {
      transferListeners.push(_addr);
      emit NewTransferListener(_addr);
    }
    function _removeTransferListener(address _addr) internal{
      transferListeners.remove(_addr);
      emit RemoveTransferListener(_addr);
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    //function () external payable {
        //require(false, "cannot transfer ether to this contract");
    //}
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: contracts/MiningV2.sol

pragma solidity >=0.4.21 <0.6.0;








contract TokenBankInterfaceM2{
  function issue(address payable _to, uint _amount) public returns (bool success);
}

contract HTokenInterfaceM{
  mapping (bytes32 => uint256) public extra;
}

contract DispatcherInterface{
  uint256 public weight_sum;
  uint256 public total_reward_per_block;
  uint256 public total_profit_per_block;
  function update_sum(uint256 _old, uint256 _new) public;
}

contract HMiningV2 is Ownable, TrustListTools{
  using SafeMath for uint256;
  using Address for address;


  struct state_info{
    uint256 inout_round;//round that in/out token comes    
    uint256 last_round;//the latest unsettled round
    uint256 in_balance;
    uint256 out_balance;
    uint256 last_balance;//balance in terms of longterm token
    uint256 rewards;
    uint256 claimed;
    uint256 reward_integral;//∫_0^{last_round - 1} (1 / weighted_total_balance(t) * DELTA(t) dt)
    uint256 profit_integral;
  }

  uint256 public gk_weight;
  address public gk_addr;

  mapping (bytes32 => uint256) public floating_total_supply;//in target token

  mapping (uint256 => mapping (address => state_info)) user_state;
  mapping (uint256 => mapping (uint256 => uint256)) in_token_ratio_to;//[ratio][round]

  uint256 current_round;
  uint256 start_round;

  TokenBankInterfaceM2 public bank;
  DispatcherInterface public dispatcher;

  uint256 public fix_ratio;
  uint256 public float_ratio;
   
  bool public paused;

  mapping (uint256 => mapping (address => uint256)) public balance_of;
  mapping (uint256 => uint256) public total_balance;
  //mapping (uint256 => mapping (address => uint256)) public rewards_for; //∫_0^T (balance_of(t) / weighted_total_balance(t) * DELTA(t) dt)
  //mapping (uint256 => mapping (address => uint256)) public rewards_integral_for; //∫_0^{user_checkpoint} (1 / weighted_total_balance(t) * DELTA(t) dt)

  mapping (uint256 => uint256) public reward_integral;//∫_0^{global_checkpoint} (1 / weighted_total_balance(t) * DELTA(t) dt)
  mapping (uint256 => mapping (uint256 => uint256)) reward_segment;//maps round to 1 / weighted_total_balance(t) * DELTA(t)

  mapping (uint256 => uint256) public profit_integral;//∫_0^{global_checkpoint} (1 / weighted_total_profit(t) * DELTA(t) dt)
  mapping (uint256 => mapping (uint256 => uint256)) profit_segment;//maps round to 1 / weighted_total_profit(t) * DELTA(t)
  constructor(address _pool, uint256 _start_round, address _tlist, address _dispatcher) TrustListTools(_tlist) public{
    bank = TokenBankInterfaceM2(_pool);
    fix_ratio = 100;
    float_ratio = 300;
    start_round = _start_round;
    current_round = 1;
    dispatcher = DispatcherInterface(_dispatcher);
  }

  modifier only_gatekeeper{
    require(msg.sender == gk_addr, "only gatekeeper can call this");
    _;
  }
  event SetFloatingAndFixRatio(uint256 fix, uint256 float);
  function set_floating_and_fix_ratio(uint fix, uint float) public onlyOwner{
    fix_ratio = fix;
    float_ratio = float;
    emit SetFloatingAndFixRatio(fix, float);
  }

  event NewGateKeeper(address addr, uint256 _weight);
  function set_gatekeeper_factor(address _gatekeeper, uint _weight) public onlyOwner{
    gk_addr = _gatekeeper;
    dispatcher.update_sum(gk_weight, _weight);
    gk_weight = _weight;
    emit NewGateKeeper(_gatekeeper, _weight);
  }

  function _user_checkpoint(uint256 ratio, address addr) internal{
    //handle cache
    state_info storage user = user_state[ratio][addr];
  
    if (current_round > user.last_round){
      user.rewards = user.rewards.safeAdd(user.last_balance.safeMul(reward_segment[ratio][user.last_round]).safeDiv(1e18));
      user.reward_integral = user.reward_integral.safeAdd(reward_segment[ratio][user.last_round]);

      user.rewards = user.rewards.safeAdd(user.last_balance.safeMul(profit_segment[ratio][user.last_round]).safeDiv(1e18));
      user.profit_integral = user.profit_integral.safeAdd(profit_segment[ratio][user.last_round]);

      user.last_round = user.last_round.safeAdd(1);
    }
    //update user balance in last round
    //inout_round always equal to last_round + 1 (if exists)
    if (user.last_round == user.inout_round){
      user.last_balance = user.last_balance.safeAdd(user.in_balance.safeMul(in_token_ratio_to[ratio][user.inout_round]).safeDiv(1e18));
      user.in_balance = 0;
      user.last_balance = user.last_balance.safeSub(user.out_balance);
      user.out_balance = 0;
    }
    if (current_round > user.last_round){
      //update balance
      //It is ok for user.last_round = 0
      user.rewards = user.rewards.safeAdd(reward_integral[ratio].safeSub(user.reward_integral).safeMul(user.last_balance).safeDiv(1e18));
      user.reward_integral = reward_integral[ratio];
  
      user.rewards = user.rewards.safeAdd(profit_integral[ratio].safeSub(user.profit_integral).safeMul(user.last_balance).safeDiv(1e18));
      user.profit_integral = profit_integral[ratio];

      user.last_round = current_round;
    }

  }
  function user_checkpoint(uint256 ratio, address addr) public{
    _user_checkpoint(ratio, addr);
  } 
  function handle_bid_ratio(address addr, uint256 amount, uint256 ratio, uint256 round) public only_gatekeeper{
    _user_checkpoint(ratio, addr);
    state_info storage user = user_state[ratio][addr];
    user.inout_round = round;
    user.in_balance = user.in_balance.safeAdd(amount);
  }
  function handle_cancel_bid(address addr, uint256 amount, uint256 ratio, uint256 round) public only_gatekeeper{
    _user_checkpoint(ratio, addr);
    state_info storage user = user_state[ratio][addr];
    user.inout_round = round;
    user.in_balance = user.in_balance.safeSub(amount);
  }

  function handle_withdraw(address addr, uint256 amount, uint256 ratio, uint256 round) public only_gatekeeper{
    _user_checkpoint(ratio, addr);
    state_info storage user = user_state[ratio][addr];
    user.inout_round = round;
    user.out_balance = user.out_balance.safeAdd(amount);
  }

  function handle_cancel_withdraw(address addr, uint256 amount, uint256 ratio, uint256 round) public only_gatekeeper{
    _user_checkpoint(ratio, addr);
    state_info storage user = user_state[ratio][addr];
    user.inout_round = round;
    user.out_balance = user.out_balance.safeSub(amount);
  }
  uint256 loop_reward_n;
  uint256 loop_reward_d;
  uint256 loop_profit_n;
  uint256 loop_profit_d;
  function loop_prepare(uint256 fix_supply, uint256 float_supply, uint256 length, uint256 start_price, uint256 end_price) public only_gatekeeper{
    uint256 total_reward_per_block = dispatcher.total_reward_per_block();
    uint256 total_profit_per_block = dispatcher.total_profit_per_block();
    uint256 weight_sum = dispatcher.weight_sum();
    //because the decimals of the two values are simimlar, we can not put them together
    loop_reward_n = length.safeMul(gk_weight).safeMul(total_reward_per_block);
    loop_reward_d = fix_ratio.safeMul(fix_supply).safeAdd(float_ratio.safeMul(float_supply)).safeMul(weight_sum);
    loop_profit_n = length.safeMul(gk_weight).safeMul(1e18).safeMul(total_profit_per_block);
    loop_profit_d = end_price.safeSub(start_price).safeMul(fix_supply.safeAdd(float_supply)).safeMul(weight_sum);
    current_round = current_round.safeAdd(1);
  }
  //event Log1(uint256 nt, uint256 loop_profit_n, uint256 loop_profit_d, uint256 lt_amount_in_ratio);
  /// @param ratio_to longterm to target, already in 1e18
  /// @param nt the the actual received interest (in price) for this ratio.
  /// @param intoken_ratio value of intoken after round settled. 
  function _handle_settle_round(uint256 round, uint256 ratio, uint256 ratio_to, uint256 intoken_ratio, uint256 lt_amount_in_ratio, uint256 nt) internal{
    in_token_ratio_to[ratio][round + 1] = intoken_ratio;
    if (round < start_round || paused) {return;}
    if (loop_reward_d > 0){
      if (ratio == 0){
        reward_segment[ratio][round] = float_ratio.safeMul(ratio_to).safeMul(loop_reward_n).safeDiv(loop_reward_d);
      }
      else{
        reward_segment[ratio][round] = fix_ratio.safeMul(ratio_to).safeMul(loop_reward_n).safeDiv(loop_reward_d);
      } 
    }
    reward_integral[ratio] = reward_integral[ratio].safeAdd(reward_segment[ratio][round]);
    //profit part
    if (lt_amount_in_ratio != 0 && loop_profit_d != 0){
      profit_segment[ratio][round] = 
      nt.safeMul(loop_profit_n).safeDiv(loop_profit_d.safeMul(lt_amount_in_ratio));
    }
    profit_integral[ratio] = profit_integral[ratio].safeAdd(profit_segment[ratio][round]);

    //if (current_round == 8 && ratio == 0) require(false, "come in");
    // emit Log1(nt, loop_profit_n, loop_profit_d, lt_amount_in_ratio);
  }
  function handle_settle_round(uint256 ratio, uint256 ratio_to, uint256 intoken_ratio, uint256 lt_amount_in_ratio, uint256 nt) public only_gatekeeper{
    _handle_settle_round(current_round.safeSub(1), ratio, ratio_to, intoken_ratio, lt_amount_in_ratio, nt);
  }

  function onTransfer(address _from, address _to, uint256 _amount) public is_trusted(msg.sender){
    if (_from == address(0) || _to == address(0)) return;
    uint256 ratio = HTokenInterfaceM(msg.sender).extra(keccak256("ratio"));
    _user_checkpoint(ratio, _from);
    _user_checkpoint(ratio, _to);
    user_state[ratio][_from].last_balance = user_state[ratio][_from].last_balance.safeSub(_amount);
    user_state[ratio][_to].last_balance = user_state[ratio][_to].last_balance.safeAdd(_amount);
  }


  event ClaimedReward(address addr, uint amount);
  function claim_reward(uint256 ratio) public{
    _user_checkpoint(ratio, msg.sender);
    state_info storage user = user_state[ratio][msg.sender];
    uint amount = user.rewards.safeSub(user.claimed);
    user.claimed = user.rewards;
    bank.issue(msg.sender, amount);
    emit ClaimedReward(msg.sender, amount);
  }

  function pause_it() public onlyOwner{
    paused = true;
  }
  function unpause_it() public onlyOwner{
    paused = false;
  }

}

contract HMiningV2Factory {
  event NewHMiningV2(address addr);
  function createHMiningV2(address _pool, uint256 _start_round, address tlist, address _dispatcher) public returns(address){
    HMiningV2 h = new HMiningV2(_pool, _start_round, tlist, _dispatcher);
    h.transferOwnership(msg.sender);
    emit NewHMiningV2(address(h));
    return address(h);
  }
}