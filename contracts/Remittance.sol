pragma solidity ^0.4.24;

contract Remittance {
    event Deposit(address indexed sender , address indexed receiver, address indexed remitter, uint amount);
    event Withdraw(address indexed sender , address indexed receiver, address indexed remitter, uint amount);

    struct Dossier {
        address sender;
        address receiver;
        address remitter;
        uint256 amount;
        bytes32 receiverSecretHash;
        bytes32 remitterSecretHash;
    }

    mapping(bytes32 => Dossier) dossiers;

    function secretHash(string secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret));
    }

    function dossierId(address sender, address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, receiver, receiverSecretHash, remitter, remitterSecretHash));
    }

    function open(address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public payable {
        address sender = msg.sender;
        uint256 amount = msg.value;

        require(receiver != address(0));
        require(remitter != address(0));
        require(amount != 0);

        bytes32 hash = dossierId(sender, receiver, receiverSecretHash, remitter, remitterSecretHash);
        Dossier storage dossier = dossiers[hash];

        require(dossier.amount == 0, "duplicate exchange");

        dossier.sender = sender;
        dossier.receiver = receiver;
        dossier.remitter = remitter;
        dossier.amount = amount;
        dossier.receiverSecretHash = receiverSecretHash;
        dossier.remitterSecretHash = remitterSecretHash;

        emit Deposit(sender, receiver, remitter, amount);
    }

    function close(address sender, address receiver, string receiverSecret, string remitterSecret) public {
        address remitter = msg.sender;

        bytes32 receiverSecretHash = secretHash(receiverSecret);
        bytes32 remitterSecretHash = secretHash(remitterSecret);

        bytes32 hash = dossierId(sender, receiver, receiverSecretHash, remitter, remitterSecretHash);
        Dossier storage dossier = dossiers[hash];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");

        delete dossiers[hash];

        emit Withdraw(sender , receiver, remitter, amount);

        remitter.transfer(amount);
    }

    //function abort(address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public {
    //    // todo: if not closed, at a deadline sender can revoke funds
    //}
}

