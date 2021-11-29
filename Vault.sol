// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "https://github.com/Crazy-Santa/contracts/blob/main/XMAS.sol";

contract Vault{

    // DECLARING VARIABLES

    uint public TVL;
    uint public quantityAddress;
    uint public lastDistribution;
    uint private lastPointDistribution;
    uint public totalPoints;
    uint public decimalsDepositNWithdraw;
    uint public supplyAddedToDistribute;
    uint public apr;
    address public vault;

    // USE XMAS CONTRACT FUNCTIONS

    XMAS private xmas;

    struct info {
        uint Id;
        uint Quantity;
        bool Used;
        uint Points;
    }

    address private admin; // THE ADMIN ADDRESS

    // LISTING OF ALL THE ADDRESS THAT ARE USING OU USED THE VAULT

    mapping(uint=>address) public addressListing;

    // DATA ABOUT EVERY ADDRESSES

    mapping(address=>info) public existingAddress;
    

    constructor(XMAS _xmas){
        admin = msg.sender;
        xmas = _xmas;
        vault = address(this);
        quantityAddress = 0;
        lastDistribution = 0;
        lastPointDistribution = block.timestamp;
        totalPoints = 0;
        supplyAddedToDistribute = 0;
        apr = 100;
        decimalsDepositNWithdraw = 18;
    }

    // FUNCTIONS LOCK AND WITHDRAW TOKENS ON THE VAULT
    function lockTOKEN(uint quantity) public{
        quantity = quantity *(10**decimalsDepositNWithdraw);
        require(xmas.balanceOf(msg.sender) >= quantity, "You do not have enough XMAS.");
        addAddressToArray();
        xmas.transferFromContract(msg.sender, vault, quantity);
        uint quantityAfterTaxes;
        if (xmas.refferalEntered(msg.sender)){ // IF REFFERRAL ENTERED REDUCTION ON FEES TO BE COUNTED ON QUANTITY AFTER TAXES
            quantityAfterTaxes = quantity/100*(100-(xmas.globalTax()*(100-xmas.affiliatorDiscountFee())/100));
        }   else    {
            quantityAfterTaxes = quantity/100*(100-xmas.globalTax());
        }
        TVL += quantityAfterTaxes;
        existingAddress[msg.sender].Quantity += quantityAfterTaxes;
        distribute();
    }

    function withdrawTOKEN(uint quantity) public{
        quantity = quantity *(10**decimalsDepositNWithdraw);
        require(existingAddress[msg.sender].Quantity >= quantity, "You do not have enough XMAS locked.");
        xmas.transferFromContract(vault, msg.sender, quantity);
        TVL -= quantity;
        existingAddress[msg.sender].Quantity -= quantity;
        distribute();
    }

    // END OF LOCK AND WITHDRAW XMAS FUNCTIONS

    // WHEN A NEW ADDRESS CALL THE CONTRACT, ADD IT TO MAPPING VARIABLES
    function addAddressToArray() private{
        if (existingAddress[msg.sender].Used == false){
            existingAddress[msg.sender].Used = true;
            existingAddress[msg.sender].Id = quantityAddress;
            addressListing[quantityAddress] = msg.sender;
            quantityAddress = quantityAddress + 1;
        }
    }
    
    
    // DISTRIBUTE XMAS GIFT TO VAULT HOLDERS
    function distribute() private{
        
        if (block.timestamp >= lastDistribution + 3600 && TVL > 0){
        uint toAdd;
        uint quantityToDistribute = xmas.quantityToDistribute();
        uint hourlyAPR = quantityToDistribute * 100 * 24 / TVL;
        xmas.resetQuantityToDistribute();
            
            for (uint i = 0; i < quantityAddress; i++){
                toAdd = quantityToDistribute * existingAddress[addressListing[i]].Quantity / TVL;
                existingAddress[addressListing[i]].Quantity = existingAddress[addressListing[i]].Quantity + toAdd;
            }
            TVL += quantityToDistribute;
           
            lastDistribution = block.timestamp;

        // UPDATE APR VALUE

        apr = (hourlyAPR * 5 + apr * 95)/100;




        }

        // DISTRIBUTE POINTS TO AFFILIATORS

        if (block.timestamp >= lastPointDistribution + 86000 && block.timestamp % 86400 >= 0){
            distributePoints();
        }
    }

    // POINT DISTRBUTION POINT FUNCTIONS

    function distributePoints() private{
        uint toAdd;
        for (uint i = 0; i < quantityAddress; i++){
            toAdd = xmas.TVLaffiliates(addressListing[i]);
            existingAddress[addressListing[i]].Points += toAdd;
            totalPoints += toAdd;
        }
    }

    function forcePointDistribution() public{
        require(msg.sender == admin, "You cannot do that.");
        distributePoints();
    }

    // END OF DISTRBUTION POINT FUNCTION

    function setDecimals(uint _quantity) public{
        require(msg.sender == admin, "You cannot do that.");
         decimalsDepositNWithdraw = _quantity;
    }
    
    // GET THE LOCKED VALUE OF AN ADDRESS
    function lockedValue(address _address) public view returns(uint){
        return existingAddress[_address].Quantity;
    }

    // GET THE AMOUNT OF POINT OF AN ADDRESS
    function returnPoints(address _address) public view returns(uint){
        return existingAddress[_address].Points;
    }

    
    


}