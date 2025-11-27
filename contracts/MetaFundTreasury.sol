// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MetaFund Treasury
 * @dev A decentralized treasury management system for community funds
 * @notice This contract enables secure fund management with multi-signature support,
 * proposal voting, and transparent fund allocation
 */

contract Project {
    // State Variables
    address public owner;
    uint256 public totalFunds;
    uint256 public proposalCount;
    uint256 public constant PROPOSAL_DURATION = 7 days;
    uint256 public constant QUORUM_PERCENTAGE = 51;
    
    // Structs
    struct Proposal {
        uint256 id;
        address proposer;
        address payable recipient;
        uint256 amount;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        bool exists;
    }
    
    struct Member {
        bool isActive;
        uint256 votingPower;
        uint256 joinedAt;
    }
    
    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public approvers;
    
    address[] public memberList;
    uint256 public totalVotingPower;
    uint256 public approverCount;
    
    // Events
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 timestamp);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, address recipient, uint256 amount);
    event MemberAdded(address indexed member, uint256 votingPower);
    event MemberRemoved(address indexed member);
    event ApproverAdded(address indexed approver);
    event ApproverRemoved(address indexed approver);
    event EmergencyWithdrawal(address indexed recipient, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function");
        _;
    }
    
    modifier onlyApprover() {
        require(approvers[msg.sender], "Only approvers can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        _;
    }
    
    modifier notExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }
    
    // Constructor
    constructor() {
        owner = msg.sender;
        members[msg.sender] = Member({
            isActive: true,
            votingPower: 100,
            joinedAt: block.timestamp
        });
        memberList.push(msg.sender);
        totalVotingPower = 100;
        approvers[msg.sender] = true;
        approverCount = 1;
    }
    
    // Receive function to accept ETH
    receive() external payable {
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value, block.timestamp);
    }
    
    // Fallback function
    fallback() external payable {
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Deposit funds into the treasury
     */
    function depositFunds() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Add a new member to the treasury
     * @param _member Address of the new member
     * @param _votingPower Voting power assigned to the member
     */
    function addMember(address _member, uint256 _votingPower) external onlyOwner {
        require(_member != address(0), "Invalid address");
        require(!members[_member].isActive, "Member already exists");
        require(_votingPower > 0, "Voting power must be greater than 0");
        
        members[_member] = Member({
            isActive: true,
            votingPower: _votingPower,
            joinedAt: block.timestamp
        });
        
        memberList.push(_member);
        totalVotingPower += _votingPower;
        
        emit MemberAdded(_member, _votingPower);
    }
    
    /**
     * @dev Remove a member from the treasury
     * @param _member Address of the member to remove
     */
    function removeMember(address _member) external onlyOwner {
        require(members[_member].isActive, "Member does not exist");
        require(_member != owner, "Cannot remove owner");
        
        totalVotingPower -= members[_member].votingPower;
        members[_member].isActive = false;
        members[_member].votingPower = 0;
        
        emit MemberRemoved(_member);
    }
    
    /**
     * @dev Add an approver who can execute proposals
     * @param _approver Address of the approver
     */
    function addApprover(address _approver) external onlyOwner {
        require(_approver != address(0), "Invalid address");
        require(!approvers[_approver], "Already an approver");
        
        approvers[_approver] = true;
        approverCount++;
        
        emit ApproverAdded(_approver);
    }
    
    /**
     * @dev Remove an approver
     * @param _approver Address of the approver to remove
     */
    function removeApprover(address _approver) external onlyOwner {
        require(approvers[_approver], "Not an approver");
        require(_approver != owner, "Cannot remove owner as approver");
        require(approverCount > 1, "Must have at least one approver");
        
        approvers[_approver] = false;
        approverCount--;
        
        emit ApproverRemoved(_approver);
    }
    
    /**
     * @dev Create a new funding proposal
     * @param _recipient Address to receive funds
     * @param _amount Amount to be sent
     * @param _description Description of the proposal
     */
    function createProposal(
        address payable _recipient,
        uint256 _amount,
        string memory _description
    ) external onlyMember returns (uint256) {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= totalFunds, "Insufficient treasury funds");
        require(bytes(_description).length > 0, "Description required");
        
        proposalCount++;
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + PROPOSAL_DURATION,
            executed: false,
            exists: true
        });
        
        emit ProposalCreated(proposalCount, msg.sender, _recipient, _amount);
        
        return proposalCount;
    }
    
    /**
     * @dev Vote on a proposal
     * @param _proposalId ID of the proposal
     * @param _support True for yes, false for no
     */
    function vote(uint256 _proposalId, bool _support) 
        external 
        onlyMember 
        proposalExists(_proposalId) 
        notExecuted(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        
        uint256 voterPower = members[msg.sender].votingPower;
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }
    
    /**
     * @dev Execute a proposal if it has reached quorum and passed
     * @param _proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) 
        external 
        onlyApprover 
        proposalExists(_proposalId) 
        notExecuted(_proposalId) 
    {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotingPower * QUORUM_PERCENTAGE) / 100;
        
        require(totalVotes >= quorum, "Quorum not reached");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");
        require(proposal.amount <= address(this).balance, "Insufficient contract balance");
        
        proposal.executed = true;
        totalFunds -= proposal.amount;
        
        (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
        require(success, "Transfer failed");
        
        emit ProposalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }
    
    /**
     * @dev Get proposal details
     * @param _proposalId ID of the proposal
     */
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (
            address proposer,
            address recipient,
            uint256 amount,
            string memory description,
            uint256 votesFor,
            uint256 votesAgainst,
            uint256 deadline,
            bool executed
        ) 
    {
        Proposal memory p = proposals[_proposalId];
        return (
            p.proposer,
            p.recipient,
            p.amount,
            p.description,
            p.votesFor,
            p.votesAgainst,
            p.deadline,
            p.executed
        );
    }
    
    /**
     * @dev Check if a proposal has passed
     * @param _proposalId ID of the proposal
     */
    function hasProposalPassed(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId)
        returns (bool) 
    {
        Proposal memory p = proposals[_proposalId];
        uint256 totalVotes = p.votesFor + p.votesAgainst;
        uint256 quorum = (totalVotingPower * QUORUM_PERCENTAGE) / 100;
        
        return (
            block.timestamp >= p.deadline &&
            totalVotes >= quorum &&
            p.votesFor > p.votesAgainst &&
            !p.executed
        );
    }
    
    /**
     * @dev Get all members
     */
    function getAllMembers() external view returns (address[] memory) {
        return memberList;
    }
    
    /**
     * @dev Get member details
     * @param _member Address of the member
     */
    function getMemberInfo(address _member) 
        external 
        view 
        returns (
            bool isActive,
            uint256 votingPower,
            uint256 joinedAt
        ) 
    {
        Member memory m = members[_member];
        return (m.isActive, m.votingPower, m.joinedAt);
    }
    
    /**
     * @dev Get treasury balance
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Emergency withdrawal function (only owner, with restrictions)
     * @param _recipient Address to receive funds
     * @param _amount Amount to withdraw
     */
    function emergencyWithdraw(address payable _recipient, uint256 _amount) 
        external 
        onlyOwner 
    {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount <= address(this).balance, "Insufficient balance");
        
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed");
        
        totalFunds -= _amount;
        
        emit EmergencyWithdrawal(_recipient, _amount);
    }
    
    /**
     * @dev Transfer ownership
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        require(_newOwner != owner, "Already the owner");
        
        // Add new owner as member if not already
        if (!members[_newOwner].isActive) {
            members[_newOwner] = Member({
                isActive: true,
                votingPower: 100,
                joinedAt: block.timestamp
            });
            memberList.push(_newOwner);
            totalVotingPower += 100;
        }
        
        // Add new owner as approver if not already
        if (!approvers[_newOwner]) {
            approvers[_newOwner] = true;
            approverCount++;
        }
        
        owner = _newOwner;
    }
}
