# BitMarket - Decentralized Commerce Protocol

## Overview

BitMarket is a decentralized marketplace protocol built atop Bitcoin's security infrastructure, leveraging Bitcoin's Layer 2 for trustless peer-to-peer commerce. By integrating Bitcoin-backed settlements, smart contracts, and community-driven reputation systems, BitMarket enables secure, transparent, and efficient transactions without the need for traditional intermediaries.

The protocol facilitates a marketplace for merchants and buyers to transact in a decentralized manner, including features such as automated escrow, dispute resolution, dynamic pricing through auctions, and community ratings.

## Key Features

* **Zero Counterparty Risk**: Settlements secured by Bitcoin, minimizing the risk of fraud.
* **Automated Dispute Resolution**: Smart contracts handle conflicts without intermediaries.
* **Dynamic Pricing**: Auctions provide competitive pricing for products.
* **Decentralized Reputation System**: Merchant credibility is maintained through community-driven reviews.
* **Cross-chain Compatibility**: Assets can be transferred seamlessly between chains.

## Table of Contents

1. [System Overview](#system-overview)
2. [Contract Architecture](#contract-architecture)
3. [Core Data Structures](#core-data-structures)
4. [Functions](#functions)

   * [Merchant Onboarding & Verification](#merchant-onboarding--verification)
   * [Direct Marketplace Operations](#direct-marketplace-operations)
   * [Competitive Auction System](#competitive-auction-system)
   * [Quality Assurance & Reviews](#quality-assurance--reviews)
   * [Read-Only Queries](#read-only-queries)
5. [Security Considerations](#security-considerations)
6. [Limitations & Future Enhancements](#limitations--future-enhancements)

---

## System Overview

The BitMarket protocol is designed to create a fully decentralized marketplace leveraging Bitcoin's security model with Stacks smart contracts. It offers two main transaction models: direct purchase transactions and competitive auctions.

* **Direct Transactions**: Merchants list products, and buyers purchase products through direct, secure transactions. Smart contracts handle payment processing and escrow.
* **Auctions**: Products can be auctioned, with users bidding against each other. The auction ends when the time expires, and the highest bidder wins the product.

Additionally, BitMarket incorporates a quality assurance system where buyers can review products and merchants, establishing trust within the community.

---

## Contract Architecture

The contract is organized into several key components:

1. **Merchant Registry**: Stores information about verified merchants.
2. **Product Catalog**: Holds the inventory of products, including details like price, availability, and auction status.
3. **Auction Engine**: Manages active auctions, including bids, reserve prices, and auction durations.
4. **Quality Assurance**: Enables buyers to rate products and leave reviews, helping future buyers assess merchant credibility.
5. **Global Product Counter**: Ensures unique product identifiers for each listing.

---

## Core Data Structures

1. **MerchantRegistry**
   The `MerchantRegistry` stores verified merchants' information:

   * `business-name`: Name of the business.
   * `is-verified`: Boolean indicating if the merchant is verified.
   * `registration-height`: The block height when the merchant was registered.

2. **ProductCatalog**
   The `ProductCatalog` contains all the product listings:

   * `merchant`: Principal of the merchant who listed the product.
   * `title`: Product title.
   * `details`: Detailed description of the product.
   * `price-point`: Product price in satoshis.
   * `is-available`: Availability of the product.
   * `listing-height`: The block height at which the product was listed.
   * `auction-mode`: Boolean indicating if the product is part of an auction.

3. **AuctionEngine**
   The `AuctionEngine` keeps track of auction details for products:

   * `expiration-height`: The block height at which the auction ends.
   * `reserve-price`: Minimum price for the auction.
   * `leading-bid`: The highest bid placed in the auction.
   * `leading-bidder`: Principal of the current highest bidder.
   * `auction-active`: Boolean indicating whether the auction is still ongoing.

4. **QualityAssurance**
   The `QualityAssurance` map stores community reviews for products:

   * `item-id`: The ID of the product being reviewed.
   * `reviewer`: The principal of the buyer submitting the review.
   * `quality-score`: A numerical score representing the product's quality (0-5).
   * `feedback-text`: A textual review.
   * `review-height`: The block height when the review was submitted.

---

## Functions

### Merchant Onboarding & Verification

#### `register-merchant`

Registers a new merchant on the platform by submitting their business name. This creates an unverified entry in the `MerchantRegistry`.

#### `verify-merchant-credentials`

Allows the protocol owner to verify a merchant's credentials. This function updates the merchant’s profile to mark them as verified.

### Direct Marketplace Operations

#### `create-product-listing`

Enables verified merchants to list products for sale. Each product is assigned a unique ID, and the listing includes product details such as title, description, and price.

#### `execute-purchase`

Allows buyers to purchase a product directly. The protocol fee is deducted and transferred to the contract owner, while the remaining funds are transferred to the merchant.

### Competitive Auction System

#### `initialize-auction`

Allows merchants to list products in auction mode with a reserve price and a specified duration. The auction parameters are set, and bidding begins.

#### `submit-bid`

Allows users to place bids on products listed for auction. The new bid must exceed the current leading bid and the reserve price.

#### `finalize-auction`

After the auction expires, the highest bidder is selected, and the payment is transferred to the merchant (minus protocol fees). The product is marked as sold, and the auction is closed.

### Quality Assurance & Reviews

#### `submit-product-review`

Allows buyers to submit reviews for products they've purchased. Reviews include a quality score (0-5) and optional feedback text.

### Read-Only Queries

#### `get-product-details`

Retrieves details for a specific product by its ID.

#### `get-merchant-profile`

Fetches a merchant's profile, including verification status and business name.

#### `get-product-review`

Fetches a specific review for a product by a specific reviewer.

#### `get-auction-status`

Retrieves the status of an auction for a given product.

#### `get-current-product-count`

Returns the total number of products listed on the marketplace.

#### `get-protocol-fee-rate`

Retrieves the protocol fee rate (in basis points).

---

## Security Considerations

The BitMarket protocol has been designed with security in mind. However, smart contract-based systems are susceptible to various risks, including but not limited to:

* **Reentrancy Attacks**: Care should be taken to validate transactions thoroughly before making state changes (such as transfers).
* **Overflow/Underflow**: All numerical values are subject to overflow/underflow risks. The protocol implements safety checks where necessary.
* **Trusted Entities**: The protocol owner has the power to verify merchants and handle disputes. This centralization of control could be a potential risk if the owner’s account is compromised.

Future updates to the protocol may consider decentralized dispute resolution systems and other advanced features to further reduce trust in any single entity.

---

## Limitations & Future Enhancements

### Limitations

* **Auction Duration**: Currently, auctions have a fixed time limit, which may not be suitable for all use cases.
* **Protocol Fee**: The protocol fee is set statically, and future versions may allow merchants to choose their fee structure.
* **Smart Contract Gas Limitations**: Certain complex operations may be subject to block size and gas constraints, limiting scalability.

### Future Enhancements

* **Decentralized Identity and Verification**: Using more robust decentralized identity solutions to verify merchant credentials.
* **Multi-Asset Support**: Enabling cross-chain support to facilitate payments in assets other than Bitcoin.
* **Advanced Reputation Systems**: Implementing more advanced reputation systems, possibly incorporating staking to prevent fraud and incentivize honest behavior.

---

## Conclusion

BitMarket is a powerful, decentralized commerce protocol that enables secure, peer-to-peer transactions on Bitcoin's Layer 2. By combining automated escrow, competitive auctions, and decentralized reputation systems, it offers a robust alternative to traditional e-commerce platforms. The protocol's design emphasizes security, trust, and transparency, providing a foundation for the future of decentralized commerce.
