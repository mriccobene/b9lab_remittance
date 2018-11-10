pragma solidity ^0.4.24;

contract Remittance {
    event Deposit(address indexed sender, address indexed remitter, bytes32 indexed dossierId, uint amount);
    event Withdraw(address indexed sender, address indexed remitter, bytes32 indexed dossierId, uint amount);
    event Abort(address indexed sender, address indexed remitter, bytes32 indexed dossierId, uint amount);

    struct Dossier {
        address sender;
        address remitter;
        uint256 amount;
        uint256 deadline;   // seconds since the epoch
    }

    mapping(bytes32 => Dossier) public dossiers;

    function computeSecretHash(string secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret));
    }

    function computeDossierId(address sender, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, receiverSecretHash, remitter, remitterSecretHash));
    }

    function isDeadlineAcceptable(uint256 deadline) public view returns (bool) {
        return deadline > block.timestamp &&
               deadline - block.timestamp >=  3 days &&
               deadline - block.timestamp <= 30 days;
    }

    // opening a remittance dossier and collecting funds
    function open(address remitter, bytes32 receiverSecretHash, bytes32 remitterSecretHash, uint256 deadline) public payable {
        // here: address sender = msg.sender;

        require(remitter != address(0), "invalid remitter");
        require(msg.value != 0, "zero amount");
        require(isDeadlineAcceptable(deadline), "deadline is not acceptable");

        bytes32 dossierId = computeDossierId(msg.sender, receiverSecretHash, remitter, remitterSecretHash);
        Dossier storage dossier = dossiers[dossierId];

        require(dossier.amount == 0, "duplicate exchange");

        dossier.sender = msg.sender;
        dossier.remitter = remitter;
        dossier.amount = msg.value;

        emit Deposit(dossier.sender, dossier.remitter, dossierId, dossier.amount);
    }

    // closing a remittance dossier and sending funds to remitter
    function close(address sender, string receiverSecret, string remitterSecret) public {
        address remitter = msg.sender;

        bytes32 receiverSecretHash = computeSecretHash(receiverSecret);
        bytes32 remitterSecretHash = computeSecretHash(remitterSecret);

        bytes32 dossierId = computeDossierId(sender, receiverSecretHash, remitter, remitterSecretHash);
        Dossier storage dossier = dossiers[dossierId];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");

        delete dossiers[dossierId];

        emit Withdraw(sender, remitter, dossierId, amount);

        remitter.transfer(amount);
    }

    // revoking funds (sender can revoke funds if deadline is reached)
    function abort(address remitter, bytes32 receiverSecretHash, bytes32 remitterSecretHash) public {
        // here: address sender = msg.sender;

        bytes32 dossierId = computeDossierId(msg.sender, receiverSecretHash, remitter, remitterSecretHash);
        Dossier storage dossier = dossiers[dossierId];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");
        require(dossier.deadline <= block.timestamp, "deadline not reached");

        delete dossiers[dossierId];

        emit Abort(msg.sender, remitter, dossierId, amount);

        msg.sender.transfer(amount);
    }
}

