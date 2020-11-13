pragma solidity ^0.5.0;

interface IERC20 
{
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath 
{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    if (a == 0) 
	{
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
  {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 
{

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public 
  {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) 
  {
    return _name;
  }

  function symbol() public view returns(string memory) 
  {
    return _symbol;
  }

  function decimals() public view returns(uint8) 
  {
    return _decimals;
  }
}

contract GetLuckyFinance is ERC20Detailed 
{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    address rewardsWallet = 0xf7db36F723180058eE1a19dFE07a9c4Eb8bCc4b5;
    address deployerWallet = 0xf7db36F723180058eE1a19dFE07a9c4Eb8bCc4b5;
    
    string constant tokenName = "GetLucky";
    string constant tokenSymbol = "GLUCKY";
    uint8  constant tokenDecimals = 18;
    uint256 _totalSupply = 168 * (10 ** 18);
    uint256 public basePercent = 168;
    uint256 public taxPercent = 832;
    
    constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) 
    {
    _mint(msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint256) 
    {
    return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) 
    {
    return _balances[owner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256)
    {
    return _allowed[owner][spender];
    }
    
    function getPercent(uint256 value) public view returns (uint256) 
    {
    uint256 roundValue = value.ceil(basePercent);
    uint256 fivePercent = roundValue.mul(basePercent).div(10000);
    return fivePercent;
    }
    
    function getRewardsPercent(uint256 value) public view returns (uint256)  
    {
    uint256 roundValue = value.ceil(taxPercent);
    uint256 rewardsPercent = roundValue.mul(taxPercent).div(10000);
    return rewardsPercent;
    }
    
    function transfer(address to, uint256 value) public returns (bool) 
    {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    
    if (msg.sender == deployerWallet)
    {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
    	_balances[to] = _balances[to].add(value);
    	
        emit Transfer(msg.sender, to, value);
    }
    
    else
    {
        uint256 tokensToBurn = getPercent(value);
        uint256 tokensForRewards = getRewardsPercent(value);
        uint256 tokensToTransfer = value.sub(tokensToBurn).sub(tokensForRewards);
        
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(tokensToTransfer);
        _balances[rewardsWallet] = _balances[rewardsWallet].add(tokensForRewards);
        _totalSupply = _totalSupply.sub(tokensToBurn);
        
        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Transfer(msg.sender, rewardsWallet, tokensForRewards);
        emit Transfer(msg.sender, address(0), tokensToBurn);
    }
    
    return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));
        
        if (from == deployerWallet)
        {
            _balances[from] = _balances[from].sub(value);
        	_balances[to] = _balances[to].add(value);
        	
            emit Transfer(from, to, value);
        }
        
        else
        {
            uint256 tokensToBurn = getPercent(value);
            uint256 tokensForRewards = getRewardsPercent(value);
            uint256 tokensToTransfer = value.sub(tokensToBurn).sub(tokensForRewards);
            
             _balances[from] = _balances[from].sub(value);
            _balances[to] = _balances[to].add(tokensToTransfer);
            _balances[rewardsWallet] = _balances[rewardsWallet].add(tokensForRewards);
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
            _totalSupply = _totalSupply.sub(tokensToBurn);
            
            emit Transfer(from, to, value);
            emit Transfer(from, to, tokensToTransfer);
            emit Transfer(from, rewardsWallet, tokensForRewards);
            emit Transfer(from, address(0), tokensToBurn);
        }

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
    }
    
    // Internal Mint Function Only
    function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
    }
    
    function burn(uint256 amount) external {
    _burn(msg.sender, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
    }
    
    function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
    }
}