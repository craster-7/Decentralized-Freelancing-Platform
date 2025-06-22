// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Enums
    enum ProjectStatus { Open, InProgress, Completed, Disputed, Cancelled }
    enum DisputeStatus { None, Raised, Resolved }
    
    // Structs
    struct FreelanceProject {
        uint256 id;
        address client;
        address freelancer;
        string title;
        string description;
        uint256 budget;
        uint256 deadline;
        ProjectStatus status;
        DisputeStatus disputeStatus;
        uint256 createdAt;
        bool fundsReleased;
    }
    
    struct Freelancer {
        address freelancerAddress;
        string name;
        string skills;
        uint256 rating;
        uint256 completedProjects;
        bool isRegistered;
    }
    
    struct Client {
        address clientAddress;
        string name;
        uint256 projectsPosted;
        bool isRegistered;
    }
    
    // State variables
    mapping(uint256 => FreelanceProject) public projects;
    mapping(address => Freelancer) public freelancers;
    mapping(address => Client) public clients;
    mapping(uint256 => address[]) public projectApplicants;
    
    uint256 public projectCounter;
    uint256 public platformFeePercent = 5; // 5% platform fee
    address public owner;
    
    // Events
    event ProjectCreated(uint256 indexed projectId, address indexed client, uint256 budget);
    event FreelancerApplied(uint256 indexed projectId, address indexed freelancer);
    event FreelancerHired(uint256 indexed projectId, address indexed freelancer);
    event ProjectCompleted(uint256 indexed projectId, address indexed freelancer);
    event FundsReleased(uint256 indexed projectId, uint256 amount);
    event DisputeRaised(uint256 indexed projectId);
    event FreelancerRegistered(address indexed freelancer, string name);
    event ClientRegistered(address indexed client, string name);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyClient(uint256 _projectId) {
        require(msg.sender == projects[_projectId].client, "Only client can call this function");
        _;
    }
    
    modifier onlyFreelancer(uint256 _projectId) {
        require(msg.sender == projects[_projectId].freelancer, "Only assigned freelancer can call this function");
        _;
    }
    
    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCounter, "Project does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        projectCounter = 0;
    }
    
    // Core Function 1: Create Project
    function createProject(
        string memory _title,
        string memory _description,
        uint256 _deadline
    ) external payable {
        require(msg.value > 0, "Budget must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(clients[msg.sender].isRegistered, "Client must be registered");
        
        projectCounter++;
        
        projects[projectCounter] = FreelanceProject({
            id: projectCounter,
            client: msg.sender,
            freelancer: address(0),
            title: _title,
            description: _description,
            budget: msg.value,
            deadline: _deadline,
            status: ProjectStatus.Open,
            disputeStatus: DisputeStatus.None,
            createdAt: block.timestamp,
            fundsReleased: false
        });
        
        clients[msg.sender].projectsPosted++;
        
        emit ProjectCreated(projectCounter, msg.sender, msg.value);
    }
    
    // Core Function 2: Hire Freelancer and Manage Project Workflow
    function hireFreelancer(uint256 _projectId, address _freelancer) 
        external 
        onlyClient(_projectId) 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open, "Project is not open for hiring");
        require(freelancers[_freelancer].isRegistered, "Freelancer must be registered");
        require(block.timestamp < project.deadline, "Project deadline has passed");
        
        project.freelancer = _freelancer;
        project.status = ProjectStatus.InProgress;
        
        emit FreelancerHired(_projectId, _freelancer);
    }
    
    function submitWork(uint256 _projectId) 
        external 
        onlyFreelancer(_projectId) 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "Project is not in progress");
        require(block.timestamp <= project.deadline, "Project deadline has passed");
        
        project.status = ProjectStatus.Completed;
        
        emit ProjectCompleted(_projectId, msg.sender);
    }
    
    // Core Function 3: Release Funds with Escrow Management
    function releaseFunds(uint256 _projectId) 
        external 
        onlyClient(_projectId) 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "Project must be completed");
        require(!project.fundsReleased, "Funds already released");
        require(project.disputeStatus == DisputeStatus.None, "Cannot release funds during dispute");
        
        uint256 platformFee = (project.budget * platformFeePercent) / 100;
        uint256 freelancerPayment = project.budget - platformFee;
        
        project.fundsReleased = true;
        freelancers[project.freelancer].completedProjects++;
        
        // Transfer funds to freelancer
        payable(project.freelancer).transfer(freelancerPayment);
        
        // Transfer platform fee to owner
        payable(owner).transfer(platformFee);
        
        emit FundsReleased(_projectId, freelancerPayment);
    }
    
    // Additional Functions
    function registerFreelancer(string memory _name, string memory _skills) external {
        require(!freelancers[msg.sender].isRegistered, "Freelancer already registered");
        
        freelancers[msg.sender] = Freelancer({
            freelancerAddress: msg.sender,
            name: _name,
            skills: _skills,
            rating: 0,
            completedProjects: 0,
            isRegistered: true
        });
        
        emit FreelancerRegistered(msg.sender, _name);
    }
    
    function registerClient(string memory _name) external {
        require(!clients[msg.sender].isRegistered, "Client already registered");
        
        clients[msg.sender] = Client({
            clientAddress: msg.sender,
            name: _name,
            projectsPosted: 0,
            isRegistered: true
        });
        
        emit ClientRegistered(msg.sender, _name);
    }
    
    function applyForProject(uint256 _projectId) 
        external 
        projectExists(_projectId) 
    {
        require(freelancers[msg.sender].isRegistered, "Freelancer must be registered");
        require(projects[_projectId].status == ProjectStatus.Open, "Project is not open for applications");
        require(projects[_projectId].client != msg.sender, "Client cannot apply for own project");
        
        projectApplicants[_projectId].push(msg.sender);
        
        emit FreelancerApplied(_projectId, msg.sender);
    }
    
    function raiseDispute(uint256 _projectId) 
        external 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(
            msg.sender == project.client || msg.sender == project.freelancer,
            "Only client or freelancer can raise dispute"
        );
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.Completed, 
                "Invalid project status for dispute");
        require(project.disputeStatus == DisputeStatus.None, "Dispute already raised");
        
        project.disputeStatus = DisputeStatus.Raised;
        project.status = ProjectStatus.Disputed;
        
        emit DisputeRaised(_projectId);
    }
    
    function cancelProject(uint256 _projectId) 
        external 
        onlyClient(_projectId) 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open, "Can only cancel open projects");
        require(!project.fundsReleased, "Cannot cancel after funds released");
        
        project.status = ProjectStatus.Cancelled;
        
        // Refund the client
        payable(project.client).transfer(project.budget);
    }
    
    // View Functions
    function getProject(uint256 _projectId) 
        external 
        view 
        projectExists(_projectId) 
        returns (FreelanceProject memory) 
    {
        return projects[_projectId];
    }
    
    function getProjectApplicants(uint256 _projectId) 
        external 
        view 
        projectExists(_projectId) 
        returns (address[] memory) 
    {
        return projectApplicants[_projectId];
    }
    
    function getFreelancer(address _freelancer) 
        external 
        view 
        returns (Freelancer memory) 
    {
        return freelancers[_freelancer];
    }
    
    function getClient(address _client) 
        external 
        view 
        returns (Client memory) 
    {
        return clients[_client];
    }
    
    // Admin Functions
    function updatePlatformFee(uint256 _newFeePercent) external onlyOwner {
        require(_newFeePercent <= 10, "Platform fee cannot exceed 10%");
        platformFeePercent = _newFeePercent;
    }
    
    function resolveDispute(uint256 _projectId, bool _favorClient) 
        external 
        onlyOwner 
        projectExists(_projectId) 
    {
        FreelanceProject storage project = projects[_projectId];
        require(project.disputeStatus == DisputeStatus.Raised, "No active dispute");
        require(!project.fundsReleased, "Funds already released");
        
        project.disputeStatus = DisputeStatus.Resolved;
        project.fundsReleased = true;
        
        if (_favorClient) {
            // Refund client (minus platform fee for processing)
            uint256 platformFee = (project.budget * platformFeePercent) / 100;
            uint256 refundAmount = project.budget - platformFee;
            payable(project.client).transfer(refundAmount);
            payable(owner).transfer(platformFee);
        } else {
            // Pay freelancer (minus platform fee)
            uint256 platformFee = (project.budget * platformFeePercent) / 100;
            uint256 freelancerPayment = project.budget - platformFee;
            payable(project.freelancer).transfer(freelancerPayment);
            payable(owner).transfer(platformFee);
            freelancers[project.freelancer].completedProjects++;
        }
        
        project.status = ProjectStatus.Completed;
    }
    
    // Emergency function to withdraw contract balance (only owner)
    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Get contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
