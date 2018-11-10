pragma solidity ^0.4.24;

library DossierLib {
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

    function secretHash(string secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(secret));
    }

    function open(Dossier storage self, address sender, address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash, uint256 amount) public returns (bytes32 _id) {
        require(sender != address(0));
        require(receiver != address(0));
        require(remitter != address(0));
        require(amount != 0);

        self.sender = sender;
        self.receiver = receiver;
        self.remitter = remitter;
        self.amount = amount;
        self.receiverSecretHash = receiverSecretHash;
        self.remitterSecretHash = remitterSecretHash;

        emit Deposit(self.sender, self.receiver, self.remitter, self.amount);

        return id(self);
    }

    function close(Dossier storage self, string receiverSecret, string remitterSecret) public {
        bytes32 receiverSecretHash = secretHash(receiverSecret);
        bytes32 remitterSecretHash = secretHash(remitterSecret);

        bytes32 hash = dossierId(self.sender, self.receiver, receiverSecretHash, self.remitter, remitterSecretHash);

        require(id(self) == hash);

        emit Withdraw(self.sender, self.receiver, self.remitter, self.amount);

        self.remitter.transfer(self.amount);
    }

    function id(Dossier storage self) public view returns (bytes32) {
        return dossierId(self.sender, self.receiver, self.receiverSecretHash, self.remitter, self.remitterSecretHash);
    }

    function dossierId(address sender, address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, receiver, receiverSecretHash, remitter, remitterSecretHash));
    }
}