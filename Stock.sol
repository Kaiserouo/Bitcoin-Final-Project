// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// ref. https://github.com/ConsenSysMesh/MultiSigWallet/blob/master/MultiSigWalletWithDailyLimit.sol
// for multisignature

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC1155/ERC1155.sol";


contract Stock is ERC1155 {

    // For yet-to-confirm transactions
    struct Transaction {
        uint tx_id;
        address target;
        string op;
        uint value;
        uint confirm_count;
        bool has_executed;
        bool isValid;   // ...since mapping does not throw on any key error,
                        // need something to know that is a valid key
    }

    string public name;     // for opensea
    string public company_name;
    address[] public board_members;
    mapping (address => bool) private is_board_mem;

    uint public min_required_board_confirm;
    string public url;
    uint public token_id;
    string public founding_date;


    mapping (uint => Transaction) private transactions;
    mapping (uint => mapping (address => bool)) member_has_confirmed;

    address creator;

    constructor(
        string memory _company_name, address [] memory _board_members, 
        uint _min_required_board_confirm, string memory _url,
        uint _token_id, string memory _founding_date) public ERC1155(_url) {
        
        name = _company_name;
        company_name = _company_name;
        board_members = _board_members;
        min_required_board_confirm = _min_required_board_confirm;
        url = _url;
        token_id = _token_id;
        founding_date = _founding_date;

        for (uint i = 0; i != board_members.length; ++i) {
            is_board_mem[board_members[i]] = true;
        }

        creator = msg.sender;
    }

    modifier isBoardMember(address addr) {
        require(is_board_mem[addr]);
        _;
    }
    modifier isValidTransaction(uint tx_id) {
        require(transactions[tx_id].isValid);
        _;
    }
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }
        

    // https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity/103807
    // Definitely not the safest way to compare a string but whatever
    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function issueStock(address receiver, uint count, uint tx_id) public 
        isBoardMember(receiver) onlyCreator {

        transactions[tx_id] = Transaction({
            tx_id: tx_id,
            target: receiver,
            op: "issue",
            value: count,
            confirm_count: uint(0),
            has_executed: false,
            isValid: true
        });
        
        tryTransaction(tx_id);
    }

    function changeURL(address sender, string memory _url) public 
        isBoardMember(sender) onlyCreator {
        
        url = _url;
    }

    // for board members to confirm a transaction
    function confirmTransaction(address sender, uint tx_id) public 
        isBoardMember(sender) isValidTransaction(tx_id) onlyCreator {
        
        if (!member_has_confirmed[tx_id][sender]) {
            member_has_confirmed[tx_id][sender] = true;
            transactions[tx_id].confirm_count += 1;
        }

        tryTransaction(tx_id);
    }

    // just burn it, the company shall do all real-money transactions
    // thenselves with their client
    function redemptStock(address sender, uint count) public onlyCreator {
        _burn(sender, token_id, count);
    }

    // try the transaction everytime someone confirms something
    function tryTransaction(uint tx_id) private 
        isValidTransaction(tx_id) {

        if (!transactions[tx_id].has_executed && transactions[tx_id].confirm_count >= min_required_board_confirm) {
            // actually do the transactions
            // uh I don't wanna do the function pointer way

            if (compareStrings(transactions[tx_id].op, "issue")) {
                _mint(transactions[tx_id].target, token_id, transactions[tx_id].value, "");
            }

            transactions[tx_id].has_executed = true;
        }
    }

    function getTranasctionInfo(uint tx_id) public view 
        isValidTransaction(tx_id)
        returns(address target, string memory op, uint value, uint confirm_count, bool has_executed){
        
        Transaction memory cur_tx = transactions[tx_id];
        return (cur_tx.target, cur_tx.op, cur_tx.value, cur_tx.confirm_count, cur_tx.has_executed);
    }

    // actually a wrapper of balanceOf, since token_id will be in Stock
    function balanceOfStock(address addr) public view returns(uint) {
        return balanceOf(addr, token_id);
    }

    function transferStock(address from, address to, uint count) public onlyCreator {
        safeTransferFrom(from, to, token_id, count, "");
    }
}
