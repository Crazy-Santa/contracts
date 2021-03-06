// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "https://github.com/Crazy-Santa/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";





contract XMAS is ERC20{


    // DECLARING ALL THE VARIABLES

    uint public globalTax; 
    uint public burnTax;
    uint public vaultTax;
    uint public marketingTax;
    uint public xmasGiftVaultTax;
    uint public charityTax;

    // YOUR DISCOUNT WHEN YOU HAVE AN AFFILIATOR

    uint public affiliatorDiscountFee; 

    // DATA ABOUT SUPPLY

    uint public supply;
    uint public supplyBurnt;

    // QUANTITY WAITING TO BE DISTRIBUTED TO VAULT HODLERS EVERY HOUR

    uint public quantityToDistribute;

    // ADDRESSES OF EVERY TAX

    address public vault;
    address private charity;
    address private xmasGiftVault;
    address private marketing;
    Vault private vaultContract;

    // IS AN ADDRESS ADMIN OR NOT ?

    mapping(address=>uint) private admin; 

    // MAPPING FOR AFFILIATION
    
    mapping(address=>affiliate) public Affiliation;


    struct affiliate {
        address Affiliator;
        mapping(uint=>address) Affiliates;
        uint numberOfAffiliates;
        
    }
    
    
    constructor() ERC20("Crazy Santa", "XMAS"){
        supply = 20000000000;
        _mint(msg.sender, supply * 10 **18);
        admin[msg.sender] = 2;
        globalTax = 10;
        affiliatorDiscountFee = 20;
        burnTax = 30;
        vaultTax = 30;
        charityTax = 5;
        marketingTax = 10;
        xmasGiftVaultTax = 25;
        supplyBurnt = 0;
        vault = msg.sender;
        charity = 0x7e7BEA09C8031F86036dCF07de827b0D57349364;
        xmasGiftVault = 0x42D33A699Ad7376d193629a482D9D0401f502AE2;
        marketing = 0x48997547C4C24F889E5c5b89df91229f43C8e497;
        quantityToDistribute = 0;

    }
    
    // AFFILIATION FUNCTIONS
    
    
    function setAffiliator(address _address) public{ // TO SET THE ADMINISTRATOR FOR A USER
        Affiliation[msg.sender].Affiliator = _address;
        Affiliation[_address].Affiliates[Affiliation[_address].numberOfAffiliates] = msg.sender;
        Affiliation[_address].numberOfAffiliates = Affiliation[_address].numberOfAffiliates + 1;
    }
    
    function TVLaffiliates(address _address) public view returns(uint){ // GET THE TVL OF ALL AFFILIATES OF AN ADDRESS
        uint TVL2return = 0;
        for (uint i = 0; i < Affiliation[_address].numberOfAffiliates; i++){
            TVL2return += vaultContract.lockedValue(Affiliation[_address].Affiliates[i]);
        }
        return TVL2return;
    }
    
    function refferalEntered(address _address) public view returns(bool){ // GET THE REFFERAL OF AN ADDRESS
        bool isRefferalEntered = true;
        if (Affiliation[_address].Affiliator == 0x0000000000000000000000000000000000000000){
            isRefferalEntered = false;
        }
        return isRefferalEntered;
    }

    function numberOfAffiliates(address _address) public view returns(uint){ // GET THE NUMBER OF AFFILIATES OF AN ADDRESS
        return Affiliation[_address].numberOfAffiliates;
    }
    
    
    // END OF AFFILIATION FUNCTIONS
    
    // START OF BURN FUNCTIONS
    function burn(address _address, uint amount) private { // BURN FUNCTION FOR BURN TAX, PRIVATE ONLY ACCESS IN THE CONTRACT
        supplyBurnt = supplyBurnt + amount;
        _burn(_address, amount);
    }
    

    function burnMyTokens(uint amount) public virtual { // BURN FUNCTION FOR USERS THAT WANT TO BURN THEIR OWN TOKENS
        supplyBurnt = supplyBurnt + amount;
        _burn(msg.sender, amount);
    }

    // END OF BURN FUNCTIONS


    // OVVERIDES OF FUNCTIONS TO ADD TAXS


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (admin[msg.sender] == 0){
        if (Affiliation[msg.sender].Affiliator == 0x0000000000000000000000000000000000000000)
            _transfer(msg.sender, recipient, amount*(100-globalTax)/100);
        else
            _transfer(msg.sender, recipient, amount*(100-(globalTax*(100-affiliatorDiscountFee)/100))/100);
        taxesDistribution(amount*globalTax/100, msg.sender);
        } else  { // IF ADMIN
            _transfer(msg.sender, recipient, amount);
        }

        return true;



    }

    function transferFrom( 
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        
        if (refferalEntered(sender)){
            amount = amount*(100-globalTax)/100;
        }   else    {
            amount = amount*(100-(globalTax*(100-affiliatorDiscountFee)/100))/100;
        }


        _transfer(sender, recipient, amount);

        taxesDistribution(amount*globalTax/100, sender);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    
    }
    

    // END OF OVERRIDED FUNCTIONS




    function transferFromContract( // FUNCTION FOR THE SMART CONTRACTS OF THE XMAS ECOSYSTEM.
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        if(admin[msg.sender] >= 1){
        if (refferalEntered(sender)){
            _transfer(sender, recipient, amount*(100-globalTax)/100);
        }   else    {
            _transfer(sender, recipient, amount*(100-(globalTax*(100-affiliatorDiscountFee)/100))/100);
        }

        taxesDistribution(amount*globalTax/100, sender);
        

        unchecked {
            emit Approval(sender, _msgSender(), amount);
        }

        return true;
        }
    }
    

    // FUNCTION TO DISTRIBUTE GLOBAL TAX TO EVERY SUBTAXES
    function taxesDistribution(uint amount, address toBeTaxed) private{
        
        if (Affiliation[toBeTaxed].Affiliator != 0x0000000000000000000000000000000000000000)
            amount = amount * (100-affiliatorDiscountFee)/100;

        
        // BURN
        uint toBurn = amount*burnTax/100;
        burn(toBeTaxed, toBurn);


        // VAULT
        uint toLockInVault = amount*vaultTax/100;
        _transfer(toBeTaxed, vault, toLockInVault);
        quantityToDistribute += toLockInVault;


        // CHARITY
        uint charityAmount = amount*charityTax/100;
        _transfer(toBeTaxed, charity, charityAmount);


        // XMAS GIFT VAULT
        uint xmasGiftVaultAmount = amount*xmasGiftVaultTax/100;
        _transfer(toBeTaxed, xmasGiftVault, xmasGiftVaultAmount);


        // MARKETING
        uint marketingAmount = amount*marketingTax/100;
        _transfer(toBeTaxed, marketing, marketingAmount);
    }
    
    
    // FUNCTION FOR VAULT SMART CONTRACT TO RESET QUANTITY TO DISTRIBUTE WHEN QUANTITY IS JUST DISTRIBUTED
    function resetQuantityToDistribute() public{
        require(admin[msg.sender] >= 1, "You cannot do that.");
        quantityToDistribute = 0;
        
    }

    // ADMIN FUNCTION CHANGE STATE OF TAXES AND ADDRESSES OF VAULTS

    function setAdmin(address _address, uint _rank) public{ // SET AN ADMIN ADDRESS
        require(admin[msg.sender] == 2, "You cannot do that.");
        admin[_address] = _rank;
    }


    function setGlobalTax(uint _percentage) public{ // SET GLOBAL TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        globalTax = _percentage;

    }
    function setBurnTax(uint _percentage) public{ // SET BURN TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        burnTax = _percentage;

    }
    function setVaultTax(uint _percentage) public{ // SET VAULT TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        vaultTax = _percentage;

    }
    function setCharityTax(uint _percentage) public{ // SET CHARITY TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        charityTax = _percentage;

    }

    function setMarketingTax(uint _percentage) public{ // SET MARKETING TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        marketingTax = _percentage;

    }
    function setXmasGiftVaultTax(uint _percentage) public{ // SET XMASGIFTVAULT TAX
        require(admin[msg.sender] >= 1, "You cannot do that.");
        xmasGiftVaultTax = _percentage;

    }
    function setCharityAddress(address _address) public{ // SET CHARITY ADDRESS
        require(admin[msg.sender] >= 1, "You cannot do that.");
        charity = _address;
    }
    
    function setMarketing(address _address) public{ // SET MARKETING ADDRESS
        require(admin[msg.sender] >= 1, "You cannot do that.");
        marketing = _address;
    }
     
    function setVaultAddress(Vault _vault) public{ // SET VAULT ADDRESS
        require(admin[msg.sender] >= 1, "You cannot do that.");
        vault = _vault.vault();
        admin[vault] = 1;
        vaultContract = _vault;
        
    }
    function setXmasGiftVault(address _address) public{ // SET XMASGIFTVAULT ADDRESS
        require(admin[msg.sender] >= 1, "You cannot do that.");
        xmasGiftVault = _address;
    }

    function setAffiliatorDiscountFee(uint _percentage) public{ // SET DISCOUNT FEES IF AFFILIATOR ENTERED
        require(admin[msg.sender] >= 1, "You cannot do that.");
        affiliatorDiscountFee = _percentage;

    }


}


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