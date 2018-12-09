pragma solidity ^0.4.24;

contract Remittance {
    event Creation(address indexed sender);
    event Deposit(address indexed sender, bytes32 indexed dossierId, uint amount, uint deadline);
    event Withdrawal(address indexed sender, address indexed remitter, bytes32 indexed dossierId, uint amount);
    event Abortion(address indexed sender, address indexed remitter, bytes32 indexed dossierId, uint amount);

    uint256 MIN_DURATION = 3 days;
    uint256 MAX_DURATION = 30 days;

    struct Dossier {
        uint256 amount;
        uint256 deadline;   // seconds since the epoch
    }

    mapping(bytes32 => Dossier) public dossiers;

    constructor() public {
        emit Creation(msg.sender);
    }

    function computeDossierId(address sender, string receiverSecret, address remitter, string remitterSecret) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), sender, receiverSecret, remitter, remitterSecret));
    }

    function isDeadlineAcceptable(uint256 deadline) public view returns (bool) {
        return deadline > block.timestamp &&
               deadline - block.timestamp >=  MIN_DURATION &&
               deadline - block.timestamp <= MAX_DURATION;
    }

    // opening a remittance dossier and collecting funds
    function open(bytes32 dossierId, uint256 deadline) public payable {
        require(msg.value != 0, "zero amount");
        require(isDeadlineAcceptable(deadline), "deadline is not acceptable");

        Dossier storage dossier = dossiers[dossierId];

        require(dossier.amount == 0, "duplicate exchange");

        dossier.amount = msg.value;
        dossier.deadline = deadline;

        emit Deposit(msg.sender, dossierId, msg.value, deadline);
    }

    // closing a remittance dossier and sending funds to remitter
    function close(address sender, string receiverSecret, string remitterSecret) public {
        address remitter = msg.sender;

        bytes32 dossierId = computeDossierId(sender, receiverSecret, remitter, remitterSecret);
        Dossier storage dossier = dossiers[dossierId];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");
        require(block.timestamp <= dossier.deadline, "deadline exceeded");

        //delete dossiers[dossierId];     // this allow reuse of the same dossierId in the future, we want to prevent this
        dossier.amount = 0;

        emit Withdrawal(sender, remitter, dossierId, amount);

        remitter.transfer(amount);
    }


    // revoking funds (sender can revoke funds if deadline is reached)
    function abort(address remitter, string receiverSecret, string remitterSecret) public {
        // here: address sender = msg.sender;

        bytes32 dossierId = computeDossierId(msg.sender, receiverSecret, remitter, remitterSecret);
        Dossier storage dossier = dossiers[dossierId];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");
        require(dossier.deadline < block.timestamp, "deadline not reached");

        //delete dossiers[dossierId];   // this allow reuse of the same dossierId in the future, we want to prevent this
        dossier.amount = 0;

        emit Abortion(msg.sender, remitter, dossierId, amount);

        msg.sender.transfer(amount);
    }
}

