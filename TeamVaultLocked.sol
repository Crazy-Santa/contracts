// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "https://github.com/Crazy-Santa/contracts/blob/main/XMAS.sol";

contract teamVaultLocked{
    
    // DEFINE VARIABLES

    uint public unlockdate;
    address public admin;
    XMAS private xmas;

    constructor(XMAS _xmas){
        admin = msg.sender;
        unlockdate = 1619222400;
        
    }

    // THE ONLY FUNCTION IS AVAILABLE FOR THE ADMIN AFTER April 04th 2022

    function withdrawFunds(uint quantity) public{
        require(block.timestamp < unlockdate, "You cannot withdraw funds now, it is locked until April 04th 2022."); // TEST IF CURRENT DATE IS AFTER April 04th 2022
        require(msg.sender == admin, "You are not admin and cannot withdraw funds."); // TEST IF RESQUEST IS FROM ADMIN ADDRESS
        xmas.transfer(msg.sender, quantity);

    } 


    // NO MORE FUNCTION SO ADMIN CANNOT WITHDRAW XMAS

    
}