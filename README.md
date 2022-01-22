# Bitcoin Final Project: Stock Certificate System

A rudimentary stock certificate system that basically turn stock into NFT, but with milti-signature system (i.e. board). This is so that every transaction is traceable and solve the problems of over-issuing, etc.

Every company's NFT can be viewed on Opensea and each company will have its own Opensea collection.

## How to use?
Just put it on Remix and compile `StockSystem.sol`, and use Remix as the interface to this contract.

You can first `createCompany` and it will give you its `token_id`.
You can attempt to issue stocks by `issueStock`, but this can only be done by board members, and it will need some fixed amount of board members' confirmation. After calling `issueStock`, you will get a `tx_id`. Give `tx_id` to other board members and let them do `confirmTransaction`. Once enough board members had confirmed, the stock will be issued to the original caller of `issueStock`.

You can now freely transfer your stock via Opensea, the contract that made the NFT, or `StockSystem`'s `transferStock`. You can also see that all the stock issued by the same company will be under one Opensea collection, with the company's name as its name.

You can do `stockRedemption` to redempt your stock, but the actual money transaction isn't covered by this system. Contact the company directly after you redempt your stock.

