State Variables
    address public owner;
    uint256 public totalFunds;
    uint256 public proposalCount;
    uint256 public constant PROPOSAL_DURATION = 7 days;
    uint256 public constant QUORUM_PERCENTAGE = 51;
    
    Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public approvers;
    
    address[] public memberList;
    uint256 public totalVotingPower;
    uint256 public approverCount;
    
    Modifiers
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
    
    Receive function to accept ETH
    receive() external payable {
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value, block.timestamp);
    }
    
    Add new owner as member if not already
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
// 
End
// 
