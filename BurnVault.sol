pragma solidity ^0.8.4;

contract BurnVault{


    // DEFINE VARIABLES

    address public admin;
    uint public supplyBurntOnThisContract;
    XMAS private xmas;

    constructor(XMAS _xmas){
        admin = msg.sender;
        supplyBurntOnThisContract = 0;
        xmas = _xmas;
        
    }

    // THE ONLY FUNCTION FOR THE ADMIN TO BURN XMAS ON THE CONTRACT
    function burn(uint amount) public{
        require(msg.sender == admin, "You are not admin and cannot burn anything.");
        xmas.burnMyTokens(amount);
        supplyBurntOnThisContract = supplyBurntOnThisContract + amount;

    }

    // NO MORE FUNCTION SO ADMIN CANNOT WITHDRAW XMAS


}