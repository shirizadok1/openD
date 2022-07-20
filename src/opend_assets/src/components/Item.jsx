import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "../../../declarations/nft";
import { idlFactory as tokenIdlFactory } from "../../../declarations/token";
import { Principal } from "@dfinity/principal";
import { opend } from "../../../declarations/opend";
import Button from "./Button";
import CURRENT_USER_ID from "../index";
import PriceLabel from "./PriceLabel";



function Item() {

  const [name, setName] = useState();
  const [owner, setOwner] = useState();
  const [image, setImage] = useState();
  const [button, setButton] = useState();
  const [priceInput, setPriceInput] = useState();
  const [loaderHidden, setLoaderHidden] = useState(true);
  const [blur, setBlur] = useState();
  const [sellStatus, setSellStatus] = useState("");
  const [priceLabel, setPriceLabel] = useState();
  const [shouldDisplay, setShouldDisplay] = useState(true);


  const id = props.id;

  const localHost = "http://localhost:8080/";
  const agent =  new HttpAgent({host: localHost});
  //TODO: whe deploy live remove the following line
  agent.fetchRootKey();
  let NFTActor;

  async function loadNFT() {
     NFTActor = await Actor.createActor(idlFactory, {
      agent,
      canisterId: id,
    });

    const name = await NFTActor.getName();
    const owner = await NFTActor.getOwner();
    const imageData = await NFTActor.getAsset();
    const imageContent = new Uint8Array(imageData);
    const image = URL.createObjectURL(new Blob([imageContent.buffer], { type: "image/png" }) //converting the images array 
    );

    setName(name);
    setOwner(owner.toText());
    setImage(image);

    if(props.role == "collection"){
    const nftIsListed = await opend.isListed(props.id);

    if(nftIsListed){
        setOwner("openD");
        setBlur({filter: "blur(4px)"});
        setSellStatus("Listed");
    } else {
        setButton(<Button handleClick={handleSell} text={"Sell"}/>);
    }
  } else if(props.role == "discover") {
    const originalOwner = await opend.getOriginalOwner(props.id);
    if(originalOwner.toText() != CURRENT_USER_ID.toText()) {
      setButton(<Button handleClick={handleBuy} text={"Buy"}/>);
    }

    const price = await opend.getListedNFTPrice(props.id);
    setPriceLabel(<PriceLabel sellPrice={price.toString()} />); //rendering the priceLabel component with the price that got back 
  }
}

  useEffect(() => {
    loadNFT();
  }, []);

  let price;
  function handleSell() {

    console.log("Sell clicked");
    setPriceInput(<input
      placeholder="Price in DANG"
      type="number"
      className="price-input"
      value={price}
      onChange={(e) => price=e.target.value}
    />
    );
    setButton(<Button handleClick={sellItem} text={"Confirm"}/>);

  }

  async function sellItem() {

    setBlur({filter: "blur(4px)"}); //turning the item';s style to blur so the user knows the item does not belong to him anymore and is sold
    setLoaderHidden(false);
    console.log("set price = " + price);
    const listingResult = await opend.listItem(props.id, Number(price));    //calling the listItem id with props.id as the id input, and price as price input
    console.log(listingResult);
    if(listingResult == "Success") {
      const openDId = await opend.getOpenDCanisterID();
      const transferResult = await NFTActor.transferOwnership(openDId); //sending the openDId as an input which contains the id of the new owner type principal
      console.log(transferResult);
      if(transferResult == "Success") {
        setLoaderHidden(true);
        setButton();
        setPriceInput();  //setting it and the button to empty so that it disappears once the user clicked confirm to sell the item
        setOwner("openD"); //once the sell is confirmed, the owner is openD 
        setSellStatus("Listed");
      }
    }
  }

  async function handleBuy() {
    console.log("buy was triggered");
    setLoaderHidden(false);
    const tokenActor = await Actor.createActor(tokenIdlFactory, {
      agent,
      canisterId: Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"),
    });

    const sellerId = await opend.getOriginalOwner(props.id);
    const itemPrice = await opend.getListedNFTPrice(props.id);

    const result = await tokenActor.transfer(sellerId, itemPrice);  //transfering the amount of tokens needed to pay to buy the NFT using the transfer method from the token project
    if (result == "Success"){
      //Transfer the ownership of the NFT
      const transferResult = await opend.completePurchase(props.id, sellerId, CURRENT_USER_ID);
      console.log(transferResult);
      setLoaderHidden(true);
      setShouldDisplay(false);  //make the item disapear once it has been purchased

    }
  }


  return (
    <div style={{ display: shouldDisplay ? "inline" : "none" }} className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={image}
          style={blur}
        />
        <div className="lds-ellipsis" hidden={loaderHidden}>
        <div></div>
        <div></div>
        <div></div>
        <div></div>
      </div>
        <div className="disCardContent-root">
          {priceLabel}
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {name}
            <span className="purple-text"> {sellStatus}</span>
          </h2>
          <p className="disTypography-root makeStyles-bodyText-24 disTypography-body2 disTypography-colorTextSecondary">
            Owner: {owner}
          </p>
          {priceInput}
          {button}
        </div>
      </div>
    </div>
  );
}

export default Item;
