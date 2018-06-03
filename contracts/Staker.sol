pragma solidity ^0.4.24;

// Borrowed heavily from Numeraire

contract Staker {

    mapping (uint256 => Project) projects;  // projectID -> Projects
    uint256[] projectIDs; // list of all projects

    struct Stake {
        uint256 amount;
        uint256 confidence;
        bool successful;
        bool resolved;
    }

    struct Project {
        string name;
        bool successful;
        bool resolved;
        mapping (address => Stake) stakes; // staker -> their Stake
        address[] stakers; // full list of stakers
    }

    event ProjectCreated(uint256 pid, string name);
    event StakeCreated(address indexed staker, uint256 indexed projectID, uint256 amount, uint256 confidence);
    // event StakeDestroyed(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress);
    // event StakeReleased(uint256 indexed tournamentID, uint256 indexed roundID, address indexed stakerAddress, uint256 etherReward);

    // initialize with seed values, right now just for development convenience
    constructor(uint256 _initialProjectID, string _initialProjectName, uint256 _initialStakeAmount, uint256 _initialStakeConfidence) public {
        createProject(_initialProjectID, _initialProjectName);
        createStake(_initialProjectID, _initialStakeAmount, _initialStakeConfidence);
    }

    function createProject(uint256 _projectID, string _name) public returns (bool ok) {
        require(_projectID > 0);

        Project storage project = projects[_projectID];
        project.name = _name;
        project.successful = false;
        project.resolved = false;

        projectIDs.push(_projectID);

        emit ProjectCreated(_projectID, _name);

        return true;
    }

    function getProjectIDs() public view returns (uint256[]) {
        return projectIDs;
    }

    function getProject(uint256 _projectID) public view returns (string name, bool successful, bool resolved) {
        Project memory project = projects[_projectID];
        return (project.name, project.successful, project.resolved);
    }

    function getStakers(uint256 _projectID) public view returns (address[]) {
        return projects[_projectID].stakers;
    }

    function stakersCount(uint256 _projectID) public view returns (uint256 count) {
        return projects[_projectID].stakers.length;
    }

    function getStake(uint256 _projectID) public view returns (uint256 value, uint256 confidence) {
        return _getStake(_projectID, msg.sender);
    }

    function getStakeFor(uint256 _projectID, address _address) public view returns (uint256 value, uint256 confidence) {
        return _getStake(_projectID, _address);
    }

    function _getStake(uint256 _projectID, address _address) internal view returns (uint256 value, uint256 confidence) {
        Project storage project = projects[_projectID];
        Stake memory stake = project.stakes[_address];
        return (stake.amount, stake.confidence);
    }

    function createStake(uint256 _projectID, uint256 _value, uint256 _confidence) /*stopInEmergency*/ public returns (bool ok) {
        Project storage project = projects[_projectID];
        Stake memory stake = project.stakes[msg.sender];

        // require(balanceOf[msg.sender] >= _value); // Check for sufficient funds
        require(_value > 0 || stake.amount > 0); // Can't stake zero
        require(stake.confidence == 0 || stake.confidence <= _confidence);

        // Keep these two lines together so that the Solidity optimizer can
        // merge them into a single SSTORE.
        // stake.amount = shrink128(safeAdd(stake.amount, _value));
        stake.amount = _value;
        // stake.confidence = shrink128(_confidence);
        stake.confidence = _confidence;

        // balanceOf[msg.sender] = safeSubtract(balanceOf[msg.sender], _value);

        project.stakers.push(msg.sender);

        emit StakeCreated(msg.sender, _projectID, stake.amount, stake.confidence);

        return true;
    }


}
