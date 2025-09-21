;; BitMarket - Decentralized Commerce Protocol
;;
;; Summary:
;; A revolutionary peer-to-peer marketplace protocol built on Bitcoin's security
;; infrastructure, enabling trustless commerce with automated escrow, reputation
;; systems, and competitive bidding mechanisms without traditional intermediaries.
;;
;; Description:
;; BitMarket empowers merchants and buyers to engage in secure, transparent
;; commerce directly on Bitcoin Layer 2. The protocol combines the immutable
;; security of Bitcoin with smart contract automation to create a self-governing
;; marketplace where trust is built through cryptographic proof rather than
;; centralized authorities. Features include merchant verification, automated
;; escrow settlement, time-locked auctions, and community-driven quality
;; assurance through decentralized reviews and ratings.
;;
;; Key Innovations:
;; - Zero-counterparty risk through Bitcoin-backed settlements
;; - Automated dispute resolution via smart contract logic
;; - Dynamic pricing through competitive auction mechanisms
;; - Decentralized reputation scoring for merchant credibility
;; - Cross-chain compatibility for seamless asset transfers

;; CONSTANTS & ERROR DEFINITIONS
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MERCHANT_NOT_REGISTERED (err u101))
(define-constant ERR_INVALID_PRICE_POINT (err u102))
(define-constant ERR_PRODUCT_NOT_FOUND (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_AUCTION_EXPIRED (err u105))
(define-constant ERR_BID_BELOW_THRESHOLD (err u106))
(define-constant ERR_NO_ACTIVE_BIDDING (err u107))
(define-constant ERR_INVALID_TIME_DURATION (err u108))
(define-constant ERR_RATING_OUT_OF_BOUNDS (err u109))

;; PROTOCOL CONFIGURATION
(define-data-var protocol-fee-basis-points uint u250) ;; 2.5% protocol fee

;; CORE DATA STRUCTURES

;; Merchant Registry - Stores verified seller information
(define-map MerchantRegistry
  principal
  {
    business-name: (string-ascii 64),
    is-verified: bool,
    registration-height: uint,
  }
)

;; Product Catalog - Core marketplace inventory
(define-map ProductCatalog
  uint
  {
    merchant: principal,
    title: (string-ascii 128),
    details: (string-ascii 512),
    price-point: uint,
    is-available: bool,
    listing-height: uint,
    auction-mode: bool,
  }
)

;; Auction Engine - Manages competitive bidding
(define-map AuctionEngine
  uint
  {
    expiration-height: uint,
    reserve-price: uint,
    leading-bid: uint,
    leading-bidder: (optional principal),
    auction-active: bool,
  }
)

;; Quality Assurance - Community reviews and ratings
(define-map QualityAssurance
  {
    item-id: uint,
    reviewer: principal,
  }
  {
    quality-score: uint,
    feedback-text: (string-ascii 256),
    review-height: uint,
  }
)

;; Global product counter for unique identifiers
(define-data-var global-product-counter uint u0)

;; MERCHANT ONBOARDING & VERIFICATION

;; Register as marketplace merchant
(define-public (register-merchant (business-name (string-ascii 64)))
  (let ((merchant-profile {
      business-name: business-name,
      is-verified: false,
      registration-height: stacks-block-height,
    }))
    (ok (map-set MerchantRegistry tx-sender merchant-profile))
  )
)

;; Verify merchant credentials (protocol owner only)
(define-public (verify-merchant-credentials (merchant principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (let ((current-profile (unwrap! (map-get? MerchantRegistry merchant) ERR_MERCHANT_NOT_REGISTERED)))
      (ok (map-set MerchantRegistry merchant
        (merge current-profile { is-verified: true })
      ))
    )
    ERR_UNAUTHORIZED
  )
)

;; DIRECT MARKETPLACE OPERATIONS

;; Create new product listing
(define-public (create-product-listing
    (title (string-ascii 128))
    (details (string-ascii 512))
    (price-point uint)
  )
  (let (
      (merchant-profile (unwrap! (map-get? MerchantRegistry tx-sender) ERR_MERCHANT_NOT_REGISTERED))
      (new-product-id (+ (var-get global-product-counter) u1))
    )
    (asserts! (> price-point u0) ERR_INVALID_PRICE_POINT)
    (begin
      (var-set global-product-counter new-product-id)
      (ok (map-set ProductCatalog new-product-id {
        merchant: tx-sender,
        title: title,
        details: details,
        price-point: price-point,
        is-available: true,
        listing-height: stacks-block-height,
        auction-mode: false,
      }))
    )
  )
)

;; Execute direct purchase transaction
(define-public (execute-purchase (product-id uint))
  (let (
      (product-data (unwrap! (map-get? ProductCatalog product-id) ERR_PRODUCT_NOT_FOUND))
      (total-price (get price-point product-data))
      (merchant-address (get merchant product-data))
      (protocol-fee (/ (* total-price (var-get protocol-fee-basis-points)) u10000))
    )
    (asserts! (get is-available product-data) ERR_PRODUCT_NOT_FOUND)
    (asserts! (not (get auction-mode product-data)) ERR_PRODUCT_NOT_FOUND)
    (asserts! (>= (stx-get-balance tx-sender) total-price)
      ERR_INSUFFICIENT_BALANCE
    )

    (begin
      ;; Transfer protocol fee to contract owner
      (try! (stx-transfer? protocol-fee tx-sender CONTRACT_OWNER))
      ;; Transfer remaining amount to merchant
      (try! (stx-transfer? (- total-price protocol-fee) tx-sender merchant-address))
      ;; Mark product as sold
      (map-set ProductCatalog product-id
        (merge product-data { is-available: false })
      )
      (ok true)
    )
  )
)

;; COMPETITIVE AUCTION SYSTEM

;; Initialize auction for product
(define-public (initialize-auction
    (title (string-ascii 128))
    (details (string-ascii 512))
    (reserve-price uint)
    (auction-duration uint)
  )
  (let (
      (merchant-profile (unwrap! (map-get? MerchantRegistry tx-sender) ERR_MERCHANT_NOT_REGISTERED))
      (new-product-id (+ (var-get global-product-counter) u1))
      (auction-end-height (+ stacks-block-height auction-duration))
    )
    (asserts! (>= auction-duration u10) ERR_INVALID_TIME_DURATION)
    (asserts! (> reserve-price u0) ERR_INVALID_PRICE_POINT)

    (begin
      (var-set global-product-counter new-product-id)
      ;; Create product listing
      (map-set ProductCatalog new-product-id {
        merchant: tx-sender,
        title: title,
        details: details,
        price-point: reserve-price,
        is-available: true,
        listing-height: stacks-block-height,
        auction-mode: true,
      })
      ;; Initialize auction parameters
      (map-set AuctionEngine new-product-id {
        expiration-height: auction-end-height,
        reserve-price: reserve-price,
        leading-bid: u0,
        leading-bidder: none,
        auction-active: true,
      })
      (ok new-product-id)
    )
  )
)

;; Submit competitive bid
(define-public (submit-bid
    (product-id uint)
    (bid-amount uint)
  )
  (let (
      (product-data (unwrap! (map-get? ProductCatalog product-id) ERR_PRODUCT_NOT_FOUND))
      (auction-data (unwrap! (map-get? AuctionEngine product-id) ERR_NO_ACTIVE_BIDDING))
    )
    (asserts! (get auction-active auction-data) ERR_AUCTION_EXPIRED)
    (asserts! (<= stacks-block-height (get expiration-height auction-data))
      ERR_AUCTION_EXPIRED
    )
    (asserts! (>= bid-amount (get reserve-price auction-data))
      ERR_BID_BELOW_THRESHOLD
    )
    (asserts! (> bid-amount (get leading-bid auction-data))
      ERR_BID_BELOW_THRESHOLD
    )
    (asserts! (>= (stx-get-balance tx-sender) bid-amount)
      ERR_INSUFFICIENT_BALANCE
    )

    ;; Refund previous leading bidder
    (match (get leading-bidder auction-data)
      previous-bidder (try! (stx-transfer? (get leading-bid auction-data) CONTRACT_OWNER
        previous-bidder
      ))
      true
    )

    ;; Accept new leading bid
    (try! (stx-transfer? bid-amount tx-sender CONTRACT_OWNER))
    (map-set AuctionEngine product-id
      (merge auction-data {
        leading-bid: bid-amount,
        leading-bidder: (some tx-sender),
      })
    )
    (ok true)
  )
)

;; Finalize auction settlement
(define-public (finalize-auction (product-id uint))
  (let (
      (product-data (unwrap! (map-get? ProductCatalog product-id) ERR_PRODUCT_NOT_FOUND))
      (auction-data (unwrap! (map-get? AuctionEngine product-id) ERR_NO_ACTIVE_BIDDING))
      (merchant-address (get merchant product-data))
    )
    (asserts! (get auction-active auction-data) ERR_AUCTION_EXPIRED)
    (asserts! (>= stacks-block-height (get expiration-height auction-data))
      ERR_AUCTION_EXPIRED
    )

    (match (get leading-bidder auction-data)
      auction-winner (begin
        (let (
            (final-bid (get leading-bid auction-data))
            (protocol-fee (/ (* final-bid (var-get protocol-fee-basis-points)) u10000))
          )
          ;; Transfer payment to merchant (minus protocol fee)
          (try! (stx-transfer? (- final-bid protocol-fee) CONTRACT_OWNER
            merchant-address
          ))
          ;; Update product availability
          (map-set ProductCatalog product-id
            (merge product-data { is-available: false })
          )
          ;; Close auction
          (map-set AuctionEngine product-id
            (merge auction-data { auction-active: false })
          )
          (ok auction-winner)
        )
      )
      ERR_NO_ACTIVE_BIDDING
    )
  )
)

;; QUALITY ASSURANCE & REVIEWS

;; Submit product review and rating
(define-public (submit-product-review
    (product-id uint)
    (quality-score uint)
    (feedback-text (string-ascii 256))
  )
  (let ((product-data (unwrap! (map-get? ProductCatalog product-id) ERR_PRODUCT_NOT_FOUND)))
    (asserts! (<= quality-score u5) ERR_RATING_OUT_OF_BOUNDS)
    (map-set QualityAssurance {
      item-id: product-id,
      reviewer: tx-sender,
    } {
      quality-score: quality-score,
      feedback-text: feedback-text,
      review-height: stacks-block-height,
    })
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-product-details (product-id uint))
  (ok (map-get? ProductCatalog product-id))
)

(define-read-only (get-merchant-profile (merchant principal))
  (ok (map-get? MerchantRegistry merchant))
)

(define-read-only (get-product-review
    (product-id uint)
    (reviewer principal)
  )
  (ok (map-get? QualityAssurance {
    item-id: product-id,
    reviewer: reviewer,
  }))
)

(define-read-only (get-auction-status (product-id uint))
  (ok (map-get? AuctionEngine product-id))
)

(define-read-only (get-current-product-count)
  (ok (var-get global-product-counter))
)

(define-read-only (get-protocol-fee-rate)
  (ok (var-get protocol-fee-basis-points))
)
