// SPDX-License-Identifier: GPL-3.0
//Author: iknevece@gmail.com

pragma solidity ^0.8.0;

/*

DESCRIPTION
-----------------

Central Bank and other government banks face issues in tracking money laundering activities that are used for terrorism and other crimes. It is a threat to national security and is also adversely affecting the economy.

===================================

Background of the problem statement:
-----------------

KYC (Know Your Customer) is a service provided by financial institutions such as banks. There are both public and private sector banks managed by a central bank. These banks are banned by the central bank from adding any new customer and do any more customer KYCs as they see suspicious activities that need to be sorted out first. Despite this, the banks add new customers and do the KYC in the background.

An immutable solution is needed where the central bank maintains a list of all the banks and tracks which banks are allowed to add new customers and perform KYC. It can also track which customer KYC is completed or pending along with customer details.

banks can also add the new customer if allowed and do the KYC of the customers.

*/

contract kycBank{

    address public admin;
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin allowed");
        _;
    }

    struct Bank{
        string bankName; //The name of the bank
        address bankAddress; //The unique Ethereum address of the bank
        bool isAllowedToAddCust; //Allowed to add new customer. True or False
        bool isAllowedToDoKYC; //Allowed to do KYC for the customer. True or False
        uint256 kycCount; //Total KYC count
    }

    struct Customer{
        string custName; //The name of the customer
        string custData; //Customer supporting data such as address and mobile number
        bool custKYCStatus; //KYC status of customer. True or False
        address custBankAddress; //The unique Ethereum address of the bank
    }

    mapping (address => Bank) public banks;
    mapping (string => Customer) public customerDetails;

    /*
    1. Add new bank to Blockchain ledger:

    This function is used by the admin to add a new bank to the KYC Contract. This function can be called by admin only. This function takes the below input parameters:

    bankName of string type: The name of the bank
    address of address type: The unique Ethereum address of the bank
    */

    function addNewBank(string memory _bankName, address _address) public onlyAdmin {
        require(!(keccak256(bytes(banks[_address].bankName)) == keccak256(bytes(_bankName))), "Bank name already exists");
        banks[_address] = Bank(_bankName, _address, true, true, 0);
    }

    /*
    2. Add New customer to the bank:

    This function will add a customer to the customer list. 
    This function takes the below input parameters:

    custName of string type:  The name of the customer
    custData of string type: Customer supporting data such as address and mobile number
    */

    function addNewCustToBank(string memory _custName, string memory _custData) public {
        require(banks[msg.sender].isAllowedToAddCust, "Bank is already blocked to add new customer");
        require(customerDetails[_custName].custBankAddress == address(0), "Customer already exists");
        customerDetails[_custName] = Customer(_custName, _custData, false, msg.sender);
    }

    /*
    3. Check KYC status of existing bank customers:

    This function is used to fetch customer KYC status from the smart contract. 
    If true, then the customer is verified. 
    This function takes the below input parameter:

    custName of string type: The name of the customer for whom KYC is to be done
    
    Output: Return the KYC status, either true or false.
    */

    function fetchCustKYCStatus(string memory _custName) public view returns (bool) {
        require(customerDetails[_custName].custBankAddress != address(0), "Customer details not found in the bank");
        //require(customerDetails[_custName].custKYCStatus, "Customer KYC is done");
        return customerDetails[_custName].custKYCStatus;
    }

    /*
    4. Perform the KYC of the customer and update the status:

    This function is used to add the KYC request to the requests list. 
    If a bank is in banned status then the bank won’t be allowed to add requests for any customer. 
    
    This function takes the below input parameter:
    custName of string type: The name of the customer for whom KYC is to be done
    */
    function addCustomerKYC(string memory _custName) public onlyAdmin {
        require(customerDetails[_custName].custBankAddress != address(0), "Customer details not found in the bank");
        require(banks[msg.sender].isAllowedToDoKYC, "Bank is not allowed to to KYC");
        customerDetails[_custName].custKYCStatus = true;
        banks[msg.sender].kycCount++;
    }

    /*
    5. Block bank to add any new customer:

    This function can only be used by the admin to block any bank from adding any new customer. 
    
    This function takes the below input parameter:
    add of address type: The unique Ethereum address of the bank
    */
    function blockBankToAddNewCustomer(address _add) public onlyAdmin {
        require(banks[_add].bankAddress != address(0), "Bank not found");
        require(banks[_add].isAllowedToAddCust, "Bank is already blocked to add new customer");
        banks[_add].isAllowedToAddCust = false;     
    }

    /*
    6. Block bank to do KYC of the customers:

    This function can only be used by the admin to change the status of KYC permission of any of the banks at any point of time. 
    
    This function takes the below input parameter:
    add of address type: The unique Ethereum address of the bank
    */
    function blockBankToDoKYC(address _add) public onlyAdmin {
        require(banks[_add].bankAddress != address(0), "Bank not found");
        require(banks[_add].isAllowedToDoKYC, "Bank is already blocked to do KYC for the customer");
        banks[_add].isAllowedToDoKYC = false;
    }

    /*
    7. Allow the bank to add new customers which was banned earlier:

    This function can only be used by the admin to allow any bank to add any new customer. 
    
    This function takes the below input parameter:
    add of address type: The unique Ethereum address of the bank
    */ 
    function allowBankToAddNewCustomer(address _add) public onlyAdmin {
        require(banks[_add].bankAddress != address(0), "Bank not found");
        require(!banks[_add].isAllowedToAddCust, "Bank is already allowed to add new customer");
        banks[_add].isAllowedToAddCust = true;
    }

    /*
    8. Allow the bank to perform customer KYC which was banned earlier:

    This function can only be used by the admin to change the status of KYC Permission of any of the banks at any point of time. 
    
    This function takes the below input parameter:
    add of address type: Unique Ethereum address of the bank
    */
    function allowBankToDoKYC(address _add) public onlyAdmin {
        require(banks[_add].bankAddress != address(0), "Bank not found");
        require(!banks[_add].isAllowedToDoKYC, "Bank is already allowed to do KYC for the customer");
        banks[_add].isAllowedToDoKYC = true;
    }

    /*
    9. View customer data:

    This function allows a bank to view details of a customer. 
    
    This function takes the below input parameter:
    custName of string type: The name of the customer
    */

    function getCustData(string memory _custName) public view returns (string memory custName, string memory custData){
        require(customerDetails[_custName].custBankAddress != address(0), "Customer not found");
        return (customerDetails[_custName].custName, customerDetails[_custName].custData);
    }
}