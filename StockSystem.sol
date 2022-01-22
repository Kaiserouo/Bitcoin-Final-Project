// contracts/System.sol
// SPDX-License-identifier: MIT
pragma solidity ^0.6.0;

import "./Stock.sol";

contract StockSystem {

    // for opensea contract name
    string public name = "Stock Certificate System";
    
    mapping (string => Stock) private stocks_s;
    mapping (uint => Stock) private stocks_u;

    mapping (string => bool) private valid_company;
    mapping (uint => bool) private valid_token_id;

    mapping (uint => Stock) private transactions_stock;
    mapping (uint => bool) private valid_transactions;

    uint private next_token_id;
    uint private next_tx_id;

    event CompanyCreation(address indexed creator, uint indexed token_id);
    event StockIssuing(address indexed creator, uint indexed token_id, uint count, uint indexed tx_id);
    event StockRedemption(address indexed sender, uint indexed token_id, uint count);

    constructor() public {
        next_token_id = 1;  // no reason, just to be safe
        next_tx_id = 1;
    }

    modifier existCompany(string memory company_name) {
        require(valid_company[company_name]);
        _;
    }
    modifier existTokenid(uint token_id) {
        require(valid_token_id[token_id]);
        _;
    }
    modifier notExistCompany(string memory company_name) {
        require(!valid_company[company_name]);
        _;
    }
    modifier validTransaction(uint tx_id) {
        require(valid_transactions[tx_id]);
        _;
    }

    function createCompany(
        string memory company_name, address [] memory board_members, 
        uint min_required_board_confirm, string memory url, string memory founding_date) public 
        notExistCompany(company_name) {
        
        Stock new_stock = new Stock(company_name, board_members, min_required_board_confirm, 
                                    url, next_token_id, founding_date);

        stocks_s[company_name] = new_stock;
        stocks_u[next_token_id] = new_stock;
        valid_company[company_name] = true;
        valid_token_id[next_token_id] = true;

        emit CompanyCreation(msg.sender, next_token_id);
        next_token_id++;
    }

    function queryCompanyTokenIdByName(string memory company_name) public view
        existCompany(company_name) returns(uint token_id) {

        return stocks_s[company_name].token_id();
    }

    function queryCompanyNameByTokenId(uint token_id) public view 
        existTokenid(token_id) returns(string memory company_name) {
        
        return stocks_u[token_id].company_name();
    }

    function queryTransactionid(uint tx_id) public view
        validTransaction(tx_id)
        returns(address target, string memory op, uint value, uint confirm_count, bool has_executed) {
        
        return transactions_stock[tx_id].getTranasctionInfo(tx_id);
    }

    function issueStock(string memory company_name, uint issue_count) public 
        existCompany(company_name) {
        
        stocks_s[company_name].issueStock(msg.sender, issue_count, next_tx_id);
        transactions_stock[next_tx_id] = stocks_s[company_name];
        valid_transactions[next_tx_id] = true;

        emit StockIssuing(msg.sender, stocks_s[company_name].token_id(), issue_count, next_tx_id);
        next_tx_id++;
    }

    function changeURL(string memory company_name, string memory url) public 
        existCompany(company_name) {
        
        stocks_s[company_name].changeURL(msg.sender, url);
    }

    function confirmTransaction(uint tx_id) public 
        validTransaction(tx_id) {

        transactions_stock[tx_id].confirmTransaction(msg.sender, tx_id);
    }

    function redemptStock(string memory company_name, uint count) public
        existCompany(company_name) {

        stocks_s[company_name].redemptStock(msg.sender, count);
        emit StockRedemption(msg.sender, stocks_s[company_name].token_id(), count);
    }

    function balanceOfStock(address addr, string memory company_name) public view
        existCompany(company_name) returns(uint) {
        
        return stocks_s[company_name].balanceOfStock(addr);
    }

    // only accepts msg.sender send out stock
    // i.e. cannot just allow someone to transfer stocks
    function transferStock(address target, string memory company_name, uint count) public 
        existCompany(company_name) {
        
        stocks_s[company_name].transferStock(msg.sender, target, count);
    }
}