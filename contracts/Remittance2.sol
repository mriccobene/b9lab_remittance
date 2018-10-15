pragma solidity ^0.4.24;

import "./Remittance2_DossierLib.sol";

contract Remittance2 {
    using DossierLib for DossierLib.Dossier;

    mapping(bytes32 => DossierLib.Dossier) dossiers;

    function open(address receiver, bytes32 receiverSecretHash, address remitter, bytes32 remitterSecretHash) public payable returns (bytes32 dossierId){
        address sender = msg.sender;
        uint256 amount = msg.value;

        require(receiver != address(0));
        require(remitter != address(0));
        require(amount != 0);

        bytes32 hash = DossierLib.dossierId(sender, receiver, receiverSecretHash, remitter, remitterSecretHash);
        DossierLib.Dossier storage dossier = dossiers[hash];

        require(dossier.amount == 0, "duplicate exchange");

        return dossier.open(sender, receiver, receiverSecretHash, remitter, remitterSecretHash, amount);
    }

    function close(bytes32 dossierId, string receiverSecret, string remitterSecret) public {
        //address remitter = msg.sender;

        DossierLib.Dossier storage dossier = dossiers[dossierId];

        uint256 amount = dossier.amount;

        require(amount != 0, "no exchange");

        delete dossiers[dossierId];

        dossier.close(receiverSecret, remitterSecret);
    }


}