import Cycles "mo:base/ExperimentalCycles";//in order to deploy the app to the icp internet computer
import Debug "mo:base/Debug";
import NFTActorClass "../NFT/nft";
import Principal "mo:base/Principal";
import HashMap  "mo:base/HashMap";
import List "mo:base/List";
import Iter "mo:base/Iter";

actor OpenD {

    private type Listing = {
        itemOwner: Principal;
        itemPrice: Nat;
    };
    
    var mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    var mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash); //List for the list of items the owner has
    var mapOfListing = HashMap.HashMap<Principal, Listing >(1, Principal.equal, Principal.hash);//The principal daya type is to represnt the id of the item, and creating hash map with the listing data type as well


    public shared(msg) func mint(imgData: [Nat8], name: Text) : async Principal {
       let owner : Principal = msg.caller; // this way we can identity the user who called this method

        Cycles.add(100_500_000_000);
        let newNFT = await NFTActorClass.NFT(name, owner, imgData);// create canister

        let newNFTPrincipal = await newNFT.getCanisterId();//get hold of the id of the new canister

        mapOfNFTs.put(newNFTPrincipal, newNFT);// put new item into the hash map
        addToOwnershipMap(owner, newNFTPrincipal);

        return newNFTPrincipal;
    };

    private func addToOwnershipMap(owner: Principal, nftId: Principal) {
        var ownedNFTs : List.List<Principal> = switch (mapOfOwners.get(owner)) {
            case null List.nil<Principal>(); //if its null, we are setting an empty list of data type Principal
            case (?result) result; //set the ownedNfts to the result 
        };

        ownedNFTs := List.push(nftId, ownedNFTs); //push the nftId to the ownedNFTs list
        mapOfOwners.put(owner, ownedNFTs); //adding the owner to the maps of owners

    };

    public query func getOwnedNFTs(user: Principal) : async [Principal] {
        var userNFTs : List.List<Principal> = switch (mapOfOwners.get(user)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        return List.toArray(userNFTs); //converting a list to an array and returning the array of principal as defined after the async word
    };

    public query func getListedNFTs() : async [Principal] {
        let ids = Iter.toArray(mapOfListing.keys());
        return ids;
    };


    public shared(msg) func listItem(id: Principal, price: Nat) : async Text { //asyncying return a piece of text
        var item : NFTActorClass.NFT = switch (mapOfNFTs.get(id)) {     //setting a new var item as data type of NFT and setting it to be the result of the id dayatype Principal that is found
            case null return "NFT does not exist.";
            case (?result) result;
        };

        let owner =  await item.getOwner();
        if(Principal.equal(owner, msg.caller)) {       // Checking if the owner of the item and the msg.caller who triggered the func is the same user
            let newListing : Listing = {
                itemOwner = owner;
                itemPrice = price;
            };
            mapOfListing.put(id, newListing);       //adding the newListing of data type listing to the mapOfListing array
            return "Success";
         } else {
            return "You don't own this NFT.";
        }
     };

     public query func getOpenDCanisterID() : async Principal {
        return Principal.fromActor(OpenD);      //converting the openD from Actor type to Principal type
     };

     public query func isListed(id: Principal) : async Bool {   //this func gets an id as an input and searching in the mapOfListing for this item
        if(mapOfListing.get(id) == null) {
            return false;
        } else {
            return true;
        }
     };

     public query func getOriginalOwner(id: Principal) : async Principal {
        var listing : Listing = switch (mapOfListing.get(id)) {
            case null return Principal.fromText("");
            case (?result) result;
        };
        return listing.itemOwner;
     };

     public query func getListedNFTPrice(id: Principal) : async Nat {
        var listing : Listing = switch (mapOfListing.get(id)) {
            case null return 0;
            case (?result) result;
        };

        return listing.itemPrice;
     };

     public shared(msg) func completePurchase(id: Principal, ownerId: Principal, newOwnerId: Principal) : async Text {
        var purchasedNFT : NFTActorClass.NFT = switch (mapOfNFTs.get(id)) {
            case null return "NFT does not exist.";
            case (?result) result;
        };
        
        let transferResult = await purchasedNFT.transferOwnership(newOwnerId);
        if(transferResult == "Success") {
            mapOfListing.delete(id);
            var ownedNFTs : List.List<Principal> = switch (mapOfOwners.get(ownerId)) {
                case null List.nil<Principal>();
                case (?result) result;
            };
            ownedNFTs := List.filter(ownedNFTs, func (listItemId: Principal) : Bool {   //all the list items get checked, and if the item that gets chacked does not equal the id of the NFT that was purchased, then we will return true, otherwise false.
                return listItemId != id;
            });
            addToOwnershipMap(newOwnerId, id);
            return "Success";
        }  else {
            return transferResult;

        }
     };

};
