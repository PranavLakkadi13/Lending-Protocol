# Core Concept:
    -> 2 differnet chains (Dojima & Hermes), Dojima is the L1 EVM compatible and Hermes is Used for the communication with different chains 



# Core DApp Logic Or MindMap
--> Factory to keep track of deifferent asset pools (similar to uniswap);
--> The core logic logic -> 
    i) User can deposit the asset 
    ii) user can withdraw the asset (with interest)
    iii) take flashloan 
    iv) user can borrow asset with a fee and compulsory collateral 
    v) user can liquidate the user who collateral value is less than the limit 

--> Token1 :- has 18 decimal places
    Token2 :- has 8 decimal places

--> PriceFeed 1 :- has 8 decimal places 
    PriceFeed 2 :- has 6 decimal places


# Questions:
1) Is Dojima completely independent of Hermes? or does heremes manage the validators of dojima as well? ✅
2) Hermes is like the communication layer and the main middleware where the interchain funds are stored and managed? ✅



# Missing links or issues in docs or networks:
1) The link to the contract state Sender in the dojima network/contracts/InboundStateSender/ link isnt working 
2) need more clarity on the liquidity part of the dojima like is it 


