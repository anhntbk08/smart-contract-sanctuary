pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@chainlink/contracts/src/v0.7/VRFConsumerBase.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IZooFunctions.sol";
import "./ZooGovernance.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title NftBattleArena contract.
/// @notice Contract for staking ZOO-Nft for participate in battle votes.
contract NftBattleArena is Ownable, ERC721
{
	using SafeMath for uint256;
	using SafeMath for int256;
	using Math for uint256;
	using Math for int256;
	
	ERC20 public zoo;                      // Zoo token interface.
	ERC20 public dai;                      // DAI token interface
	VaultAPI public vault;                 // Yearn interface.
	ZooGovernance public zooGovernance;    // zooGovernance contract.
	IZooFunctions public zooFunctions;     // zooFunctions contract.

	/// @notice Struct for stages of vote battle.
	enum Stage
	{
		FirstStage,
		SecondStage,
		ThirdStage,
		FourthStage
	}

	/// @notice Struct with type of positions for staker and voter.
	enum PositionType
	{
		StakerPostion,
		VoterPosition
	}

	/// @notice Struct with info about rewards mechanic.
	struct BattleReward
	{
		int256 yTokensSaldo; // saldo from deposit in yearn in yTokens.
		uint256 votes;       // amount of votes.
		uint256 yTokens;     // amount of yTokens.
		uint256 tokensAtBattleStart; // amount of yTokens at start.
	}

	/// @notice Struct with info about staker positions.
	struct StakerPosition
	{
		address token;      // Token address.
		uint256 id;         // Token id.
		uint256 startEpoch; // Epoch when started to stake.
		uint256 endEpoch;   // Epoch when ended to stake.
		uint256 lastRewardedEpoch;
		mapping (uint256 => BattleReward) rewards; // Records rewards part.
	}

	// /// @notice Struct with info about vote.
	// struct VoteRecord
	// {
	// 	uint256 daiInvested;           // Amount of DAI invested.
	// 	uint256 yTokensNumber;         // amount of yTokens.
	// 	uint256 zooInvested;           // Amount of Zoo invested.
	// 	uint256 votes;                 // Amount of votes.
	// 	bool daiHaveWithdrawed;        // Returns true if Dai were withdrawed.
	// 	bool zooHaveWithdrawed;        // Returns true if Zoo were withdrawed.
	// }

	/// @notice struct with info about voter positions.
	struct VotingPosition
	{
		uint256 stakingPositionId;
		uint256 daiInvested;
		uint256 yTokensNumber;
		uint256 zooInvested;
		uint256 daiVotes;
		uint256 votes;
		uint256 startDate;
		uint256 endDate;
		uint256 startEpoch;
		uint256 endEpoch;
		uint lastRewardedEpoch;
	}

/*	/// @notice Struct for records about staked Nfts.
	struct NftRecord
	{
		address token;                 // Address of Nft contract.
		uint256 id;                    // Id of Nft.
		//uint256 votes;                 // Amount of votes for this Nft.
	}*/

	/// @notice Struct for records about pairs of Nfts for battle.
	struct NftPair
	{
		uint256 token1;
		uint256 token2;
		bool playedInEpoch;
		bool win;                      // Boolean where true is when 1st candidate wins, and false for 2nd.
	}

	/// @notice Event records address of allowed nft contract.
	/// @param token - address of contract.
	event newContractAllowed (address token);

	/// @notice Event records info about staked nft in this pool.
	/// @param staker - address of nft staker.
	/// @param token - address of nft contract.
	/// @param id - id of staked nft.
	event StakedNft(address indexed staker, address indexed token, uint256 indexed id, uint256 positionId);

	/// @notice Event records info about withdrawed nft from this pool.
	/// @param staker - address of nft staker.
	/// @param token - address of nft contract.
	/// @param id - id of staked nft.
	event WithdrawedNft(address staker, address indexed token, uint256 indexed id);

	/// @notice Event records info about vote using Dai.
	/// @param voter - address voter.
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param amount - amount of votes.
	event VotedWithDai(address voter, address indexed token, uint256 indexed id, uint256 amount);

	/// @notice Event records info about vote using Zoo.
	/// @param voter - address voter.
	/// @param positionId - id of nft.
	/// @param amount - amount of votes.
	event VotedWithZoo(address voter, uint256 indexed positionId, uint256 amount);

	/// @notice Event records info about reVote again using Zoo.
	/// @param epoch - epoch number
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param votes - amount of votes.
	event ReVotedWithZoo(uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 votes);

	/// @notice Event records info about reVote again using Dai
	/// @param epoch - epoch number
	/// @param token - address of token contract.
	/// @param id - id of nft.
	/// @param votes - amount of votes.
	event ReVotedWithDai(uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 votes);

	/// @notice Event records info about claimed reward for staker.
	/// @param staker -address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	/// @param income - amount of reward.
	event StakerRewardClaimed(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 income);

	/// @notice Event records info about claimed reward for voter.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	/// @param income - amount of reward.
	event VoterRewardClaimed(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 income);

	/// @notice Event records info about withdrawed dai from votes.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	event WithdrawedDai(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id, uint256 amount);

	/// @notice Event records info about withdrawed Zoo from votes.
	/// @param staker - address staker.
	/// @param epoch - epoch number.
	/// @param token - address token.
	/// @param id - id of nft.
	event WithdrawedZoo(address staker, uint256 indexed epoch, address indexed token, uint256 indexed id);

	/// @notice Event records info about nft paired for vote battle.
	/// @param date - date of function call.
	/// @param participants - amount of participants for vote battles.
	event NftPaired(uint256 currentEpoch, uint256 date, uint256 participants);

	/// @notice Event records info about winners in battles.
	/// @param currentEpoch - number of currentEpoch.
	/// @param i - index of battle.
	/// @param random - random number get for calculating winner.
	event Winner(uint256 currentEpoch, uint256 i, uint256 random);

	
	uint256 public totalNftsInEpoch;               // Amount of Nfts staked.

	uint256 public epochStartDate;                 // Start date of battle contract.
	uint256 public currentEpoch = 0;               // Counter for battle epochs.

	uint256 public firstStageDuration = 7 minutes;		//todo:change time //3 days;    // Duration of first stage.
	uint256 public secondStageDuration = 7 minutes;		//todo:change time//7 days;   // Duration of second stage.
	uint256 public thirdStageDuration = 7 minutes;		//todo:change time//5 days;    // Duration third stage.
	uint256 public fourthStage = 7 minutes;		//todo:change time//2 days;           // Duration of fourth stage.
	uint256 public epochDuration = firstStageDuration + secondStageDuration + thirdStageDuration + fourthStage; // Total duration of battle epoch.

	// Epoch => address of NFT => id => VoteRecord
	// mapping (uint256 => mapping(address => mapping(uint256 => VoteRecord))) public votesForNftInEpoch;

	// Epoch => address of NFT => id => investor => VoteRecord
	// mapping (uint256 => mapping(address => mapping(uint256 => mapping(address => VoteRecord)))) public investedInVoting;

	// Epoch => address of NFT => id => voter => is voter rewarded?
	// mapping (uint256 => mapping(address => mapping(uint256 => mapping(address => bool)))) public isVoterRewarded; // Returns true if reward claimed.

	// Epoch => address of NFT => id => incomeFromInvestment
	// mapping (uint256 => mapping(address => mapping(uint256 => uint256))) public incomeFromInvestments;

	// Epoch => address of NFT => id => is staker rewarded?
	// mapping (uint256 => mapping(address => mapping(uint256 => bool))) public isStakerRewared;   // Returns true if reward claimed.

	// Epoch => dai deposited in epoch.
	// mapping (uint256 => uint256) public daiInEpochDeposited;                // Records amount of dai deposited in epoch.

	// Epoch => zoo deposited in epoch.
	mapping (uint256 => uint256) public zooInEpochDeposited;                // Records amount of Zoo deposited in epoch.

	// Nft contract => allowed or not.
	mapping (address => bool) public allowedForStaking;                     // Records NFT contracts available for staking.

	// nft contract => nft id => address staker.
	// mapping (address => mapping (uint256 => address)) public tokenStakedBy; // Records that nft staked or not.

	// epoch number => amount of nfts.
	mapping (uint256 => uint256[]) public nftsInEpoch;                    // Records amount of nft in battle epoch.

	// epoch number => amount of pairs of nfts.
	mapping (uint256 => NftPair[]) public pairsInEpoch;                     // Records amount of pairs in battle epoch.

	// epoch number => number of played pairs in epoch;
	mapping (uint256 => uint256) public numberOfPlayedPairsInEpoch;

	// epoch number => truncateAndPair called or not.
	mapping (uint256 => bool) public truncateAndPaired;                     // Records if participants were paired.

	mapping (uint256 => PositionType) public positions;

	mapping (uint256 => StakerPosition) public stakingPositions;

	mapping (uint256 => VotingPosition) public votingPositions;

	uint256 public numberOfPositions;

	uint256[] public nfts;

	uint256 public nftsInGame;

	/// @notice Contract constructor.
	/// @param _zoo - address of Zoo token contract.
	/// @param _dai - address of DAI token contract.
	/// @param _vault - address of yearn.
	/// @param _zooGovernance - address of ZooDao Governance contract.
	constructor (address _zoo, address _dai, address _vault, address _zooGovernance) Ownable() ERC721("ZooBattle", "ZooB")
	{
		zoo = ERC20(_zoo);
		dai = ERC20(_dai);
		vault = VaultAPI(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);
		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());

		epochStartDate = block.timestamp;//todo:change time for prod +  14 days;                              // Start date of 1st battle.
	}

	/// @notice Function to get info about nft pair in epoch for index.
	/// @param epoch - epoch number.
	/// @param i - index of nft pair
	function getNftPairInEpoch(uint256 epoch, uint256 i) public view returns (NftPair memory)
	{
		return pairsInEpoch[epoch][i];
	}

	function getNfts(uint256 i) public view returns (uint256 id)
	{
		return nfts[i];
	}

	/// @notice Function to get info about nfts in epoch for index.
	/// @param epoch - epoch number.
	/// @param i - index of nft.
	function getNftsInEpoch(uint256 epoch, uint256 i) public view returns (uint256 id)
	{
		return nftsInEpoch[epoch][i];
	}

	function getNftPairLenght(uint256 epoch) public view returns(uint256 length) {
		return pairsInEpoch[epoch].length;
	}

	function getNftsLenght(uint256 epoch) public view returns(uint256 length) {
		return nftsInEpoch[epoch].length;
	}

	/// @notice Function for updating functions according last governance resolutions.
	function updateZooFunctions() external onlyOwner
	{
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!"); // Requires to be at first stage in battle epoch.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());              // Sets ZooFunctions to contract specified in zooGovernance.
	}

	/// @notice Function to allow new NFT contract available for stacking.
	/// @param token - address of new Nft contract.
	function allowNewContractForStaking(address token) external onlyOwner
	{
		allowedForStaking[token] = true;                                   // Boolean for contract to be allowed for staking.

		emit newContractAllowed(token);
	}

	/// @notice Function for staking NFT in this pool.
	/// @param token - address of Nft token to stake
	/// @param id - id of nft token
	function stakeNft(address token, uint256 id) public
	{
		require(allowedForStaking[token] == true, "Nft not allowed!");             // Requires for nft-token to be from allowed contract.
		// Not need that require, because transferFrom already throws in that case.
		// require(tokenStakedBy[token][id] == address(0), "Already staked!");       // Requires for token to be non-staked before.
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!");  // Requires to be at first stage in battle epoch.

		IERC721(token).transferFrom(msg.sender, address(this), id);               // Sends NFT token to this contract.

		_safeMint(msg.sender, numberOfPositions);                       // Wraps in ZooBattle nft.

		positions[numberOfPositions] = PositionType.StakerPostion;      // Records type of position.
		stakingPositions[numberOfPositions].startEpoch = currentEpoch;  // Records startEpoch.
		stakingPositions[numberOfPositions].lastRewardedEpoch = currentEpoch;
		stakingPositions[numberOfPositions].token = token;              // Records nft contract address.
		stakingPositions[numberOfPositions].id = id;                    // Records id of nft.

		emit StakedNft(msg.sender, token, id, numberOfPositions);                                    // Emits StakedNft event.

		nfts.push(numberOfPositions);
		totalNftsInEpoch++;   // Increments amount of total nft in epoch.
		numberOfPositions++;  // Increments amount of positions.
	}

	function unstakeNft(uint256 positionId) public
	{
		require(positions[positionId] == PositionType.StakerPostion);
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!");  // Requires to be at first stage in battle epoch.
		require(ownerOf(positionId) == msg.sender);
		require(stakingPositions[positionId].endEpoch == 0);

		address token = stakingPositions[positionId].token;
		uint256 id = stakingPositions[positionId].id;

		stakingPositions[positionId].endEpoch = currentEpoch;

		IERC721(token).transferFrom(address(this), msg.sender, id);               // Transfers token back to owner.

		totalNftsInEpoch--;  // Decrements amount of total nft in epoch.

		for(uint i = 0; i < nfts.length; i++)
		{
			if (nfts[i] == positionId)
			{
				nfts[i] == nfts[nfts.length - 1];
				nfts.pop();
				break;
			}
		}

		emit WithdrawedNft(msg.sender, token, id);                                // Emits withdrawedNft event.
	}

	function claimRewardFromStaking(uint256 positionId, address beneficiary) public
	{
		require(positions[positionId] == PositionType.StakerPostion, "error");
		require(getCurrentStage() == Stage.FirstStage, "Must be at 1st stage!");  // Requires to be at first stage in battle epoch.
		require(ownerOf(positionId) == msg.sender, "error");

		uint endEpoch = stakingPositions[positionId].endEpoch;
		uint end = endEpoch == 0 ? currentEpoch : endEpoch;
		
		int256 yTokensReward = 0;

		for (uint256 i = stakingPositions[positionId].lastRewardedEpoch; i < end; i++)
		{
			int256 saldo = stakingPositions[positionId].rewards[i].yTokensSaldo;
			
			if (saldo > 0)
			{
				yTokensReward += saldo * 2 / 100;
			}
		}

		stakingPositions[positionId].lastRewardedEpoch = end;
		vault.withdraw(uint256(yTokensReward), beneficiary);
	}

	/// @notice Function for vote for nft in battle.
	/// @param positionId - id of staker position.
	/// @param amount - amount of dai to vote.
	/// @return votes - computed amount of votes.
	function createNewVotingPosition(uint256 positionId, uint256 amount) public returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.SecondStage, "Must be at 2nd stage!");   // Requires to be at second stage of battle epoch.
		require(stakingPositions[positionId].endEpoch == 0, "Must be staked!");
		dai.transferFrom(msg.sender, address(this), amount);                        // Transfers DAI to this contract for vote.

		votes = zooFunctions.computeVotesByDai(amount);                             // Calculates amount of votes.

		dai.approve(address(vault), amount);                                        // Approves Dai for address of yearn vault for amount
		uint256 yTokensNumber = vault.deposit(amount);                              // deposits to yearn vault and record yTokens.

		_safeMint(msg.sender, numberOfPositions);

		positions[numberOfPositions] = PositionType.StakerPostion;
		votingPositions[numberOfPositions].startEpoch = currentEpoch;
		votingPositions[numberOfPositions].lastRewardedEpoch = currentEpoch;
		votingPositions[numberOfPositions].startDate = block.timestamp;
		votingPositions[numberOfPositions].yTokensNumber = yTokensNumber;
		votingPositions[numberOfPositions].stakingPositionId = positionId;

		votingPositions[numberOfPositions].daiInvested = amount; // Records amount of dai invested.
		votingPositions[numberOfPositions].daiVotes = votes;     // Records amount of votes computed from dai.

		votingPositions[numberOfPositions].votes = votes;        // Records amount of votes.

		stakingPositions[numberOfPositions].rewards[currentEpoch].votes += votes;

		numberOfPositions++;

		return votes;
	}

	function swap(uint i, uint j) internal
	{
		uint x = nfts[j];
		nfts[j] = nfts[i];
		nfts[i] = x;
		nftsInGame++;
	}

	function pairNft(uint stakingPositionId) external
	{
		require(getCurrentStage() == Stage.ThirdStage || getCurrentStage() == Stage.FourthStage, "Must be at 3rd or 4th stage!");          // Requires to be at 3rd stage of battle epoch.
		require(nfts.length / 2 < nftsInGame / 2);
		uint index1;

		for (uint i = 0; i < nfts.length; i++)
		{
			if (nfts[i] == stakingPositionId)
			{
				if (i < nftsInGame)
				{
					return;
				}
				else
				{
					index1 = i;
				}
			}
		}

		swap(nftsInGame, index1);

		uint256 random = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1))))) % (nfts.length - nftsInGame);
		uint index2 = random + nftsInGame;
		uint position = nfts[index2];
		pairsInEpoch[currentEpoch].push(NftPair(stakingPositionId, position, false, false));

		stakingPositions[stakingPositionId].rewards[currentEpoch].tokensAtBattleStart = sharesToTokens(stakingPositions[stakingPositionId].rewards[currentEpoch].yTokens);
		stakingPositions[position].rewards[currentEpoch].tokensAtBattleStart = sharesToTokens(stakingPositions[position].rewards[currentEpoch].yTokens);

		swap(nftsInGame, index2);
	}

	/// @notice Function for boost\multiply votes with Zoo.
	/// @param amount - amount of Zoo.
	function voteWithZoo(uint256 stakingPositionId, uint256 votingPositionId, uint256 amount) public returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.ThirdStage, "Must be at 3rd stage!");      // Requires to be at 3rd stage.
		//require(tokenStakedBy[token][id] != address(0), "Must be staked!");           // Requires to vote for staked nft.
		require(stakingPositions[stakingPositionId].endEpoch == 0, "Must be staked!");
		require(votingPositions[votingPositionId].endEpoch == 0, "error");

		zoo.transferFrom(msg.sender, address(this), amount);                          // Transfers Zoo from sender to this contract.

		votes = zooFunctions.computeVotesByZoo(amount);                               // Calculates amount of votes.

		require(votes <= votingPositions[votingPositionId].daiVotes, "votes amount more than invested!"); // Reverts if votes more than tokens invested.

		stakingPositions[stakingPositionId].rewards[currentEpoch].votes += votes;                   // Adds votes for this epoch, token and id.

		votingPositions[votingPositionId].votes += votes;         // Adds votes for this epoch, token and id for msg.sender.
		votingPositions[votingPositionId].zooInvested += amount;  // Adds amount of Zoo for this epoch, token and id for msg.sender.

		zooInEpochDeposited[currentEpoch] += amount;                                  // Adds amount of zoo deposited in current epoch.

		emit VotedWithZoo(msg.sender, stakingPositionId, amount);                             // Records in VotedWithZoo event.

		return votes;
	}

	function tokensToShares(int256 tokens) public view returns (int256)
	{
		return int256(uint256(tokens).mul(10 ** dai.decimals()).div(vault.pricePerShare()));
	}

	/// @notice Function for chosing winner for exact pair of nft.
	/// @param i - index of nft pair.
	/// @dev random should be changed for chainlink VRF. TODO:
	function chooseWinnerInPair(uint256 i) public
	{
		require(truncateAndPaired[currentEpoch] == true, "Must be paired before choosing!");
		require(pairsInEpoch[currentEpoch][i].playedInEpoch != true, "winner already chosen!"); // Requires to be called only once for pair in epoch.
		require(getCurrentStage() == Stage.FourthStage, "Must be at 4th stage!");    // Requires to be at 4th stage.

		uint256 random = zooFunctions.getRandomNumber(i);                        // Get random number.
		uint256 token1 = pairsInEpoch[currentEpoch][i].token1;                   // Address of 1st candidate.

		uint256 votesForA = stakingPositions[token1].rewards[currentEpoch].votes; // Votes for 1st candidate.
		
		uint256 token2 = pairsInEpoch[currentEpoch][i].token2;                   // Address of 2nd candidate.

		uint256 votesForB = stakingPositions[token2].rewards[currentEpoch].votes; // Votes for 2nd candidate.

		pairsInEpoch[currentEpoch][i].win = zooFunctions.decideWins(votesForA, votesForB, random); // Calculates winner and records it.
		// Вычислить доход за батл.
		// Пересчитать его не в dai, а в yTokens.
		// Записать в сальдо без снятий.
		uint256 tokensAtBattleEnd1 = sharesToTokens(stakingPositions[token1].rewards[currentEpoch].yTokens); // Amount of yTokens for token1 staking Nft position.
		uint256 tokensAtBattleEnd2 = sharesToTokens(stakingPositions[token2].rewards[currentEpoch].yTokens); // Amount of yTokens for token2 staking Nft position.
		
		int256 income = int256((tokensAtBattleEnd1.add(tokensAtBattleEnd2)).sub(stakingPositions[token1].rewards[currentEpoch].tokensAtBattleStart).sub(stakingPositions[token2].rewards[currentEpoch].tokensAtBattleStart)); // Calculates income.
		int256 yTokens = tokensToShares(income);

		if (pairsInEpoch[currentEpoch][i].win)                                     // If 1st candidate wins.
		{
			stakingPositions[token1].rewards[currentEpoch].yTokensSaldo += yTokens; // Records income to token1 saldo.
			stakingPositions[token2].rewards[currentEpoch].yTokensSaldo -= yTokens; // Subtract income from token2 saldo.

			stakingPositions[token1].rewards[currentEpoch + 1].yTokens = stakingPositions[token1].rewards[currentEpoch].yTokens + uint256(yTokens);
			stakingPositions[token2].rewards[currentEpoch + 1].yTokens = stakingPositions[token2].rewards[currentEpoch].yTokens - uint256(yTokens);

		}
		else                                                                       // If 2nd candidate wins.
		{
			stakingPositions[token1].rewards[currentEpoch].yTokensSaldo -= yTokens; // Subtract income from token1 saldo.
			stakingPositions[token2].rewards[currentEpoch].yTokensSaldo += yTokens; // Records income to token2 saldo.
			stakingPositions[token1].rewards[currentEpoch + 1].yTokens = stakingPositions[token1].rewards[currentEpoch].yTokens - uint256(yTokens);
			stakingPositions[token2].rewards[currentEpoch + 1].yTokens = stakingPositions[token2].rewards[currentEpoch].yTokens + uint256(yTokens);
		}

		numberOfPlayedPairsInEpoch[currentEpoch]++;                                // Increments amount of pairs played this epoch.
		pairsInEpoch[currentEpoch][i].playedInEpoch = true;                        // Records that this pair already played this epoch.

		emit Winner(currentEpoch, i, random);                                      // Emits Winner event.

		if (numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length)
		{
			updateEpoch();  // calls updateEpoch if winner determined in every pair.
		}
	}

	/// @notice Function to increment epoch.
	function updateEpoch() public {
		require(getCurrentStage() == Stage.FourthStage, "Must be at 4th stage!"); // Requires fourth stage.
		require(block.timestamp >= epochStartDate + epochDuration || numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length, "error msg"); // Requires fourth stage to end, or determine every pair winner.
		epochStartDate = block.timestamp;                              // Sets start of new epoch.
		currentEpoch++;                                                // Increments currentEpoch.
		nftsInGame = 0;
	}

	/// @notice Function to liquidate voting position and get the reward.
	/// @param positionId - id of position.
	/// @param beneficiary - address recipient.
	function liquidateVotingPosition(uint256 positionId, address beneficiary) public
	{
		require(votingPositions[positionId].endEpoch != 0, "error"); // Requires to be not liquidated yet.
		require(getCurrentStage() == Stage.FirstStage, "Must be at first stage!");// Requires to be at first stage.
		require(ownerOf(positionId) == msg.sender, "You're not an owner"); // Requires to be owner of position.

		zoo.transfer(beneficiary, votingPositions[positionId].zooInvested);// Transfers zoo to beneficiary.

		votingPositions[positionId].endDate = block.timestamp; // Sets endDate to now.
		votingPositions[positionId].endEpoch = currentEpoch;   // Sets endEpoch to currentEpoch.

		numberOfPositions--;
	}

	function claimRewardFromVoting(uint256 positionId, address beneficiary) public
	{
		require(getCurrentStage() == Stage.FirstStage, "Must be at first stage!");// Requires to be at first stage.
		require(ownerOf(positionId) == msg.sender, "You're not an owner"); // Requires to be owner of position.

		uint256 stakingPositionId = votingPositions[positionId].stakingPositionId;
		uint256 lastEpochOfStaking = stakingPositions[stakingPositionId].endEpoch;
		uint256 lastEpochNumber;
		
		if (lastEpochOfStaking != 0 && votingPositions[positionId].endEpoch != 0)
		{
			lastEpochNumber = Math.min(lastEpochOfStaking, votingPositions[positionId].endEpoch);
		}
		else if (lastEpochOfStaking != 0)
		{
			lastEpochNumber = lastEpochOfStaking;
		}
		else if (votingPositions[positionId].endEpoch != 0)
		{
			lastEpochNumber = votingPositions[positionId].endEpoch;
		}
		else
		{
			lastEpochNumber == currentEpoch;
		}

		int256 yTokens = int256(votingPositions[positionId].yTokensNumber); // Get yTokens from position.
		int256 votes = int256(votingPositions[positionId].votes);           // Get votes from position.

		for (uint i = votingPositions[positionId].lastRewardedEpoch; i < lastEpochNumber; i++)
		{
			int256 saldo = stakingPositions[stakingPositionId].rewards[i].yTokensSaldo;
			int256 totalVotes = int256(stakingPositions[stakingPositionId].rewards[i].votes);

			if (saldo > 0)
			{
				saldo * saldo * 98 / 100;
			}

			yTokens += saldo * votes / totalVotes;
		}

		vault.withdraw(uint256(yTokens), beneficiary);
		stakingPositions[stakingPositionId].rewards[currentEpoch].votes -= uint256(votes);     // Subtracts votes for this position.
		stakingPositions[stakingPositionId].rewards[currentEpoch].yTokens -= uint256(yTokens); // Subtracts yTokens for this position.

		votingPositions[positionId].lastRewardedEpoch = lastEpochNumber;
	}

	/// @notice Function calculate amount of shares.
	/// @param _sharesAmount - amount of shares.
	/// @return shares - calculated amount of shares.
	function sharesToTokens(uint256 _sharesAmount) public view returns (uint256 shares) ///todo:make internal // не надо, public для фронта
	{
		return _sharesAmount.mul(vault.pricePerShare()).div(10 ** dai.decimals()); // Calculate amount of shares.
	}

	/// @notice Function to view current stage in battle epoch.
	/// @return stage - current stage.
	function getCurrentStage() public view returns (Stage)
	{
		if (block.timestamp < epochStartDate + firstStageDuration)
		{
			return Stage.FirstStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration)
		{
			return Stage.SecondStage;
		}
		else if (block.timestamp < epochStartDate + firstStageDuration + secondStageDuration + thirdStageDuration)
		{
			return Stage.ThirdStage;
		}
		else
		{
			return Stage.FourthStage;
		}
	}
	/*
	function prepareForParing(uint256 stakingPositionId) external
	{
		uint256 i;
		uint256 length = nftsInEpoch[currentEpoch].length;

		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i] == stakingPositionId)
			{
				return;
			}
		}

		nftsInEpoch[currentEpoch].push(stakingPositionId);
	}

	/// @notice Function for making battle pairs.
	/// @return success - returns true for success.
	function truncateAndPair() public returns (bool success)
	{
		require(getCurrentStage() == Stage.ThirdStage || getCurrentStage() == Stage.FourthStage, "Must be at 3rd or 4th stage!");          // Requires to be at 3rd stage of battle epoch.
		require(nftsInEpoch[currentEpoch].length != 0, "Already paired!");

		emit NftPaired(currentEpoch, block.timestamp, nftsInEpoch[currentEpoch].length);

		truncateAndPaired[currentEpoch] = true;

		if (nftsInEpoch[currentEpoch].length % 2 == 1)                                    // If number of nft participants is odd.
		{
			uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))); // Generate random number.
			uint256 index = random % nftsInEpoch[currentEpoch].length;                    // Pick random participant.
			uint256 length = nftsInEpoch[currentEpoch].length;                            // Get list of participants.
			nftsInEpoch[currentEpoch][index] = nftsInEpoch[currentEpoch][length - 1];     // Truncate list.
			nftsInEpoch[currentEpoch].pop();                                              // Remove random unused participant from list.
		}

		uint256 i = 1;

		while (nftsInEpoch[currentEpoch].length != 0)                                     // Get pairs of nft until where are zero left in list.
		{
			uint256 length = nftsInEpoch[currentEpoch].length;                            // Get list.

			uint256 random1 = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1)) + i++))) % length; // Generate random number.
			uint256 token1 = nftsInEpoch[currentEpoch][random1]; // Pick random nft contract address.

			nftsInEpoch[currentEpoch][random1] = nftsInEpoch[currentEpoch][length - 1];
			nftsInEpoch[currentEpoch].pop();                           // Remove from array.

			length = nftsInEpoch[currentEpoch].length;

			uint256 random2 = uint256(keccak256(abi.encodePacked(uint256(blockhash(block.number - 1)) + i++))) % length; // Generate 2nd random number.
			uint256 token2 = nftsInEpoch[currentEpoch][random2]; // Pick random nft contract address.

			nftsInEpoch[currentEpoch][random2] = nftsInEpoch[currentEpoch][length - 1];
			nftsInEpoch[currentEpoch].pop();                           // Remove from array.
			
			pairsInEpoch[currentEpoch].push(NftPair(token1,token2, false, false));  // Push pair.
		}

		return true;
	}
*/
/*ТЕПЕРЬ НЕ НУЖНО, тк награда реинвестируется и забирается в момент ликвидации позиции.
	/// @notice Function for claiming reward for Nft stakers.
	/// @param epoch - number of epoch.
	/// @param token - address of nft contract.
	/// @param id - Id of nft.
	function claimRewardForStakers(uint256 epoch, address token, uint256 id) public
	{
		require(tokenStakedBy[token][id] == msg.sender, "Must be staked by msg.sender!"); // Requires for token to be staked by msg.sender.
		require(!isStakerRewared[epoch][token][id], "Already rewarded!");           // Requires to be not rewarded before.

		uint256 income = incomeFromInvestments[epoch][token][id];                   // Gets income amount for this epoch, token and id.

		if (income != 0)
		{
			dai.transfer(msg.sender, income.mul(2).div(100));                       // Transfers Dai to msg.sender for 2% from income
		}

		isStakerRewared[epoch][token][id] = true;                                   // Records that staker was rewarded.

		emit StakerRewardClaimed(msg.sender, epoch, token, id, income);             // Records in StakerRewardClaimed event. 
	}

	/// @notice Function for claiming rewards for voter.
	/// @param epoch - number of epoch when voted.
	/// @param token - address of contract nft voted for.
	/// @param id - Id of nft voted for.
	function claimRewardForVoter(uint256 epoch, address token, uint256 id) public
	{
		require(!isVoterRewarded[epoch][token][id][msg.sender], "Already rewarded!");// Requires to be not rewarded before.

		uint256 votes = investedInVoting[epoch][token][id][msg.sender].votes;        // Gets amount of votes for this epoch, nft, id from msg.sender.
		uint256 income = incomeFromInvestments[epoch][token][id];                    // Gets income amount for this epoch, token and id.
		uint256 totalVotes = votesForNftInEpoch[epoch][token][id].votes;             // Gets amount of total votes for this nft in this epoch.

		if (income != 0)
			dai.transfer(msg.sender, (((income.mul(98)).mul(votes)).div(100)).div(totalVotes)); // Transfers reward.

		isVoterRewarded[epoch][token][id][msg.sender] = true;                        // Records what voter has been rewarded.

		emit VoterRewardClaimed(msg.sender, epoch, token, id, income);               // Records in VoterRewardClaimed event. 
	}
	
	/// @notice Function to view pending rewards for voter.
	/// @param epoch - epoch number.
	/// @param token - token address.
	/// @param id - id of token.
	/// @return pendingReward - pending reward from this battle.
	function getPendingVoterRewards(uint256 epoch, address token, uint256 id) public view returns(uint256 pendingReward) {
		uint256 votes = investedInVoting[epoch][token][id][msg.sender].votes;        // Gets amount of votes for this epoch, nft, id from msg.sender.
		uint256 income = incomeFromInvestments[epoch][token][id];                    // Gets income amount for this epoch, token and id.
		uint256 totalVotes = votesForNftInEpoch[epoch][token][id].votes;             // Gets amount of total votes for this nft in this epoch.
		pendingReward = (((income.mul(98)).mul(votes)).div(100)).div(totalVotes);
	}

	/// @notice Function to view pending rewards for staker.
	/// @param epoch - epoch number.
	/// @param token - token address.
	/// @param id - id of token.
	/// @return pendingReward - pending reward from this battle.
	function getPendingStakerReward(uint256 epoch, address token, uint256 id) public view returns(uint256 pendingReward) {
		uint256 income = incomeFromInvestments[epoch][token][id];                   // Gets income amount for this epoch, token and id.
		pendingReward = (income.mul(2)).div(100);
	}

	/// @notice Function for withdraw Dai from votes.
	/// @param epoch - epoch number.
	/// @param token - address of nft contract.
	/// @param id - id of nft.
	function withdrawDai(uint256 epoch, address token, uint256 id) public
	{
		require(epoch < currentEpoch, "Not in current epoch!");                               // Withdraw allowed from previous epochs.
		require(investedInVoting[epoch][token][id][msg.sender].daiHaveWithdrawed != true, "Dai tokens were withdrawed!"); // Requires for tokens to be not withdrawed or reVoted yet.

		dai.transfer(msg.sender, investedInVoting[epoch][token][id][msg.sender].daiInvested); // Transfers dai.

		investedInVoting[epoch][token][id][msg.sender].daiHaveWithdrawed = true;              // Records that tokens were reVoted.

		emit WithdrawedDai(msg.sender, epoch, token, id, investedInVoting[epoch][token][id][msg.sender].daiInvested);                                     // Records in WithdrawedDai event.
	}

	/// @notice Function for withdraw Zoo from votes.
	/// @param epoch - epoch number.
	/// @param token - address of nft contract.
	/// @param id - id of nft.
	function withdrawZoo(uint256 epoch, address token, uint256 id) public
	{
		require(epoch < currentEpoch, "Not in current epoch!");                  // Withdraw allowed from previous epochs.
		require(!investedInVoting[epoch][token][id][msg.sender].zooHaveWithdrawed,"Zoo tokens were withdrawed!");// Requires for tokens to be not withdrawed or reVoted yet.

		zoo.transfer(msg.sender, investedInVoting[epoch][token][id][msg.sender].zooInvested); // Transfers Zoo.

		investedInVoting[epoch][token][id][msg.sender].zooHaveWithdrawed = true; // Records that tokens were reVoted.

		emit WithdrawedZoo(msg.sender, epoch, token, id);                        // Records in WithdrawedZoo event.
	}

	/// @notice Function for voting with DAI in battle epoch.
	/// @param token - address of Nft token voting for.
	/// @param id - id of voter.
	/// @param amount - amount of votes in DAI.
	/// @return votes - calculated amount of votes from dai for nft.
	function voteWithDai(address token, uint256 id, uint256 amount) public returns (uint256 votes)
	{
		require(getCurrentStage() == Stage.SecondStage, "Must be at 2nd stage!");   // Requires to be at second stage of battle epoch.
		require(stakingPositions[positionId].endEpoch == 0, "Must be staked!");
		dai.transferFrom(msg.sender, address(this), amount);                        // Transfers DAI to this contract for vote.

		votes = zooFunctions.computeVotesByDai(amount);                             // Calculates amount of votes.

		dai.approve(address(vault), amount);                                        // Approves Dai for address of yearn vault for amount
		uint256 yTokensNumber = vault.deposit(amount);                              // deposits to yearn vault and record yTokens.

		_safeMint(msg.sender, numberOfPositions);

		positions[numberOfPositions] = PositionType.StakerPostion;
		votingPositions[numberOfPositions].

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;                 // Adds amount of votes for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].daiInvested += amount;          // Adds amount of Dai invested for this epoch, contract and id.
		votesForNftInEpoch[currentEpoch][token][id].yTokensNumber += yTokensNumber; // Adds amount of yTokens invested for this epoch, contract and id.

		//investedInVoting[currentEpoch][token][id][msg.sender].daiInvested += amount;// Adds amount of Dai invested for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][msg.sender].votes += votes;       // Adds amount of votes for this epoch, contract and id for msg.sender.
		//investedInVoting[currentEpoch][token][id][msg.sender].yTokensNumber += yTokensNumber;// Adds amount of yToken invested for this epoch, contract and id for msg.sender.

		uint256 length = nftsInEpoch[currentEpoch].length;                          // Sets amount of Nfts in current epoch.

		//daiInEpochDeposited[currentEpoch] += amount;                                // Adds amount of Dai deposited in current epoch.

		emit VotedWithDai(msg.sender, token, id, amount);                           // Records in VotedWithDai event.
		numberOfPositions++;

		uint256 i;
		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i].token == token && nftsInEpoch[currentEpoch][i].id == id)
			{
				nftsInEpoch[currentEpoch][i].votes += votes;
				break;
			}
		}

		if (i == length)
		{
			nftsInEpoch[currentEpoch].push(NftRecord(token, id, votes));
		}

		return votes;
	}

	/// @notice Function for repeat vote using Dai in next battle epoch.
	/// @param epoch - number of epoch vote was made.
	/// @param token - address of nft contract vote was made for.
	/// @param id - id of nft vote was made for.
	/// @param voter - address of votes owner.
	function reVoteInDai(uint256 epoch, address token, uint256 id, address voter) public
	{
		require(getCurrentStage() == Stage.SecondStage, "Must be at 2nd stage!");   // Requires to be at second stage of battle epoch.
		require(!investedInVoting[epoch - 1][token][id][voter].daiHaveWithdrawed, "dai tokens were withdrawed!"); // Requires for tokens to be not withdrawed or reVoted yet.

		uint256 amount = investedInVoting[epoch - 1][token][id][voter].daiInvested; // Get amount of votes from previous epoch.
		require(amount != 0, "nothing to re-vote!");                                // Requires for amount of votes to be non zero.
		uint256 votes = zooFunctions.computeVotesByDai(amount);                     // Calculates amount of votes.

		dai.approve(address(vault), amount);                                        // Approves Dai for address of yearn vault for amount
		uint256 yTokensNumber = vault.deposit(amount);                              // Records number of Dai transfered to yearn vault.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;                 // Adds amount of votes for this epoch, contract and id.
		//votesForNftInEpoch[currentEpoch][token][id].daiInvested += amount;          // Adds amount of Dai invested for this epoch, contract and id.
		//votesForNftInEpoch[currentEpoch][token][id].yTokensNumber += yTokensNumber; // Adds amount of yTokens invested for this epoch, contract and id.

		investedInVoting[currentEpoch][token][id][voter].daiInvested += amount;     // Adds amount of Dai invested for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].votes += votes;            // Adds amount of votes for this epoch, contract and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].yTokensNumber += yTokensNumber;// Adds amount of yToken invested for this epoch, contract and id for msg.sender.

		uint256 length = nftsInEpoch[currentEpoch].length;                          // Sets amount of Nfts in current epoch.

		//daiInEpochDeposited[currentEpoch] += amount;                                // Adds amount of Dai deposited in current epoch.

		uint256 i;
		for (i = 0; i < length; i++)
		{
			if (nftsInEpoch[currentEpoch][i].token == token && nftsInEpoch[currentEpoch][i].id == id)
			{
				nftsInEpoch[currentEpoch][i].votes += votes;
				break;
			}
		}

		if (i == length)
		{
			nftsInEpoch[currentEpoch].push(NftRecord(token, id, votes));
		}

		investedInVoting[epoch - 1][token][id][msg.sender].daiHaveWithdrawed = true;

		emit ReVotedWithDai(epoch, token, id, votes);                               // Records in ReVotedWithDai event.
	}

	/// @notice Function for repeat vote using Zoo in next battle epoch.
	/// @param epoch - number of epoch vote was made.
	/// @param token - address of nft contract vote was made for.
	/// @param id - id of nft vote was made for.
	/// @param voter - address of votes owner.
	function reVoteInZoo(uint256 epoch, address token, uint256 id, address voter) public
	{
		require(getCurrentStage() == Stage.ThirdStage, "Must be at 3rd stage!");
		require(!investedInVoting[epoch - 1][token][id][voter].zooHaveWithdrawed, "Zoo tokens were withdrawed!");
		uint256 amount = investedInVoting[epoch - 1][token][id][voter].zooInvested;
		require(amount != 0, "nothing to re-vote!");

		uint256 votes = zooFunctions.computeVotesByZoo(amount);                 // Calculates amount of votes.

		require(votes <= investedInVoting[currentEpoch][token][id][voter].votes, "votes amount more than invested!"); // Reverts if votes more than tokens invested.

		votesForNftInEpoch[currentEpoch][token][id].votes += votes;             // Adds votes for this epoch, token and id.
		votesForNftInEpoch[currentEpoch][token][id].zooInvested += amount;      // Adds amount of Zoo for this epoch, token and id.

		investedInVoting[currentEpoch][token][id][voter].votes += votes;        // Adds votes for this epoch, token and id for msg.sender.
		investedInVoting[currentEpoch][token][id][voter].zooInvested += amount; // Adds amount of Zoo for this epoch, token and id for msg.sender.

		investedInVoting[epoch - 1][token][id][voter].zooHaveWithdrawed = true; // Records that tokens were reVoted.

		emit ReVotedWithZoo(epoch, token, id, votes);                           // Records in ReVotedWithZoo event.
	}
*/
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {
	
	/// @notice Function for choosing winner in battle.
	/// @param votesForA - amount of votes for 1st candidate.
	/// @param votesForB - amount of votes for 2nd candidate.
	/// @param random - generated random number.
	/// @return bool - returns true if 1st candidate wins.
	function decideWins(uint votesForA, uint votesForB, uint random) external view returns (bool);

	/// @notice Function for generating random number.
	/// @param seed - multiplier for random number.
	/// @return random - generated random number.
	function getRandomNumber(uint256 seed) external view returns (uint random);

	/// @notice Function for calculating voting with Dai in vote battles.
	/// @param amount - amount of dai used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByDai(uint amount) external view returns (uint);

	/// @notice Function for calculating voting with Zoo in vote battles.
	/// @param amount - amount of Zoo used for vote.
	/// @return votes - final amount of votes after calculating.
	function computeVotesByZoo(uint amount) external view returns (uint);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface VaultAPI {
    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function pricePerShare() external view returns (uint256);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT

import "./interfaces/IZooFunctions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	using SafeMath for uint;

	address public zooFunctions;                    // Address of contract with Zoo functions.
	IERC20 public zooToken;

	/// @notice Contract constructor.
	/// @param baseZooFunctions - address of baseZooFunctions contract.
	/// @param aragon - address of aragon zoo dao agent.
	constructor(address baseZooFunctions, address aragon) {

		zooFunctions = baseZooFunctions;

		transferOwnership(aragon);            // Sets owner to aragon.
	}

    /// @notice Function for vote for changing Zoo fuctions.
	/// @param newZooFunctions - address of new zoo functions contract.
	function changeZooFunctionsContract(address newZooFunctions) external onlyOwner
	{
		zooFunctions = newZooFunctions;
	}
   
}