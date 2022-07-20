import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";



actor Token {

    let owner : Principal = Principal.fromText("llyrz-uzkhr-nkjdk-msxls-tzbot-jas4q-ix4pb-gqnxr-27loo-tscvw-jqe");
    let totalSupply : Nat = 1000000000;
    let symbol : Text = "DCOIN";

    private var balanceEntries ([Principal, Nat]) =[];//this format is expenssive as far as times so we only use it as a temporary array

    private var balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
    if(balances.size() < 1 ){
        balances.put(owner, totalSupply); //owenr is the pricipal key for this method and the totalsupply as an inital setup.
    };

    public query func balanceOf(who: Principal) : async Nat {

        let balance : Nat = switch (balances.get(who)) {
            case null 0;
            case (?result) result;
        };

        return balance;
    };

    public query func getSymbol() : async Text {
        return symbol;
    };

    public shared(msg) func payOut() : async Text {

        if(balances.get(msg.caller) == null){ // if its equal null means the user does not exist and we can give him tokens for the first time 
            let amount = 10000;
            let result = await transer(msg.caller, amount) //adding to the user's wallet 10000 coins and identifying him by his id
            return result;
        } else {
            return "Already claimed"
        }
        //Debug.print(debug_show(msg.caller));//msg.caller returns the user's id 
    };

    public shared(msg) func transfer(to: Principal, amount: Nat) : async Text {
        
        let fromBalance = await balanceOf(msg.caller) //getting the amount of coins the user who wants to transer has
        
        if( fromBalance > amount){
            let newFromBalance : Nat = fromBalance - amount;
            balances.put(msg.caller, newFromBalance); //updating the amount of the user to be the amount he has after the transfer
            
            let toBalance = await balanceOf(to); //getting the amount of the user who we want to give coins to has
            let newToBalance = toBalance + amount;
            balances.put(to, newToBalance );

            return "Success"

        } else {
            return "Insufficient funds"
        }

        system func preupgrade() {
            balanceEntries := Iter.toArray(balances.entries())//will iterate the hash map and convery to array, it will reset the balances hash map ad save it's data inside balancesEntries 
            // balances.entries method will allow balances to be itertable
        };

        system func postupgrade() {
            balances := HashMap.fromIter<Principal, Nat>(balanceEntries.val(), 1, Principal.equal, Principal.hash)
            if(balances.size() < 1 ){
                balances.put(owner, totalSupply); //owenr is the pricipal key for this method and the totalsupply as an inital setup.

            };
        };


    }

};

