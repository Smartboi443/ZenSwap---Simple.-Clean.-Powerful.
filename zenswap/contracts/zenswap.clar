;; ZenSwap - Simple. Clean. Powerful.
;; A minimalist AMM platform for effortless token swapping
;; Features: Zen-like simplicity, automated pricing, seamless liquidity

;; ===================================
;; CONSTANTS AND ERROR CODES
;; ===================================

(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-POOL-NOT-FOUND (err u301))
(define-constant ERR-INSUFFICIENT-LIQUIDITY (err u302))
(define-constant ERR-INVALID-AMOUNT (err u303))
(define-constant ERR-SLIPPAGE-TOO-HIGH (err u304))
(define-constant ERR-POOL-EXISTS (err u305))
(define-constant ERR-ZERO-LIQUIDITY (err u306))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-LIQUIDITY u1000)
(define-constant SWAP-FEE u30) ;; 0.3% swap fee
(define-constant FEE-DENOMINATOR u10000)

;; ===================================
;; DATA VARIABLES
;; ===================================

(define-data-var platform-active bool true)
(define-data-var pool-counter uint u0)
(define-data-var total-volume uint u0)
(define-data-var total-fees uint u0)

;; ===================================
;; TOKEN DEFINITIONS
;; ===================================

;; Custom trading tokens
(define-fungible-token token-a)
(define-fungible-token token-b)
(define-fungible-token lp-token)

;; ===================================
;; DATA MAPS
;; ===================================

;; Liquidity pools
(define-map liquidity-pools
  uint
  {
    name: (string-ascii 32),
    token-a-reserve: uint,
    token-b-reserve: uint,
    total-lp-tokens: uint,
    active: bool,
    created-at: uint
  }
)

;; User LP positions
(define-map user-positions
  { pool-id: uint, user: principal }
  {
    lp-tokens: uint,
    token-a-deposited: uint,
    token-b-deposited: uint,
    last-activity: uint
  }
)

;; ===================================
;; PRIVATE HELPER FUNCTIONS
;; ===================================

(define-private (is-contract-owner (user principal))
  (is-eq user CONTRACT-OWNER)
)

(define-private (min (a uint) (b uint))
  (if (<= a b) a b)
)

(define-private (calculate-swap-amount (amount-in uint) (reserve-in uint) (reserve-out uint))
  (if (or (is-eq reserve-in u0) (is-eq reserve-out u0))
    u0
    (let (
      (amount-in-with-fee (- amount-in (/ (* amount-in SWAP-FEE) FEE-DENOMINATOR)))
      (numerator (* amount-in-with-fee reserve-out))
      (denominator (+ reserve-in amount-in-with-fee))
    )
      (/ numerator denominator)
    )
  )
)

;; Simple geometric mean for initial liquidity (avoiding complex sqrt)
(define-private (calculate-initial-lp-tokens (amount-a uint) (amount-b uint))
  (if (and (> amount-a u0) (> amount-b u0))
    (+ (/ amount-a u2) (/ amount-b u2))
    u0
  )
)

;; Calculate LP tokens for existing pools
(define-private (calculate-additional-lp-tokens (amount-a uint) (amount-b uint) (reserve-a uint) (reserve-b uint) (total-supply uint))
  (if (and (> reserve-a u0) (> reserve-b u0) (> total-supply u0))
    (min 
      (/ (* amount-a total-supply) reserve-a)
      (/ (* amount-b total-supply) reserve-b)
    )
    u0
  )
)

;; ===================================
;; READ-ONLY FUNCTIONS
;; ===================================

(define-read-only (get-platform-info)
  {
    active: (var-get platform-active),
    total-pools: (var-get pool-counter),
    total-volume: (var-get total-volume),
    total-fees: (var-get total-fees)
  }
)

(define-read-only (get-pool (pool-id uint))
  (map-get? liquidity-pools pool-id)
)

(define-read-only (get-user-position (pool-id uint) (user principal))
  (map-get? user-positions { pool-id: pool-id, user: user })
)

(define-read-only (get-swap-a-for-b-quote (pool-id uint) (amount-in uint))
  (match (map-get? liquidity-pools pool-id)
    pool-data
    (some (calculate-swap-amount amount-in (get token-a-reserve pool-data) (get token-b-reserve pool-data)))
    none
  )
)

(define-read-only (get-swap-b-for-a-quote (pool-id uint) (amount-in uint))
  (match (map-get? liquidity-pools pool-id)
    pool-data
    (some (calculate-swap-amount amount-in (get token-b-reserve pool-data) (get token-a-reserve pool-data)))
    none
  )
)

(define-read-only (get-pool-ratio (pool-id uint))
  (match (map-get? liquidity-pools pool-id)
    pool-data
    (if (> (get token-b-reserve pool-data) u0)
      (some (/ (* (get token-a-reserve pool-data) u1000000) (get token-b-reserve pool-data)))
      none
    )
    none
  )
)

;; ===================================
;; ADMIN FUNCTIONS
;; ===================================

(define-public (toggle-platform (active bool))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (var-set platform-active active)
    (print { action: "platform-toggled", active: active })
    (ok true)
  )
)

(define-public (mint-token-a (amount uint) (recipient principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (ft-mint? token-a amount recipient))
    (print { action: "token-a-minted", amount: amount, recipient: recipient })
    (ok true)
  )
)

(define-public (mint-token-b (amount uint) (recipient principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (ft-mint? token-b amount recipient))
    (print { action: "token-b-minted", amount: amount, recipient: recipient })
    (ok true)
  )
)

;; ===================================
;; POOL MANAGEMENT FUNCTIONS
;; ===================================

(define-public (create-pool (name (string-ascii 32)))
  (let (
    (pool-id (+ (var-get pool-counter) u1))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (is-contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Create new pool
    (map-set liquidity-pools pool-id {
      name: name,
      token-a-reserve: u0,
      token-b-reserve: u0,
      total-lp-tokens: u0,
      active: true,
      created-at: burn-block-height
    })
    
    (var-set pool-counter pool-id)
    (print { action: "pool-created", pool-id: pool-id, name: name })
    (ok pool-id)
  )
)

;; ===================================
;; LIQUIDITY FUNCTIONS
;; ===================================

(define-public (add-liquidity (pool-id uint) (amount-a uint) (amount-b uint))
  (let (
    (pool-data (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
    (existing-position (map-get? user-positions { pool-id: pool-id, user: tx-sender }))
    (current-total-supply (get total-lp-tokens pool-data))
    (lp-tokens-to-mint 
      (if (is-eq current-total-supply u0)
        (calculate-initial-lp-tokens amount-a amount-b)
        (calculate-additional-lp-tokens 
          amount-a amount-b 
          (get token-a-reserve pool-data) 
          (get token-b-reserve pool-data)
          current-total-supply
        )
      )
    )
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (get active pool-data) ERR-POOL-NOT-FOUND)
    (asserts! (and (> amount-a u0) (> amount-b u0)) ERR-INVALID-AMOUNT)
    (asserts! (> lp-tokens-to-mint u0) ERR-ZERO-LIQUIDITY)
    (asserts! (>= lp-tokens-to-mint MIN-LIQUIDITY) ERR-ZERO-LIQUIDITY)
    
    ;; Transfer tokens to contract
    (try! (ft-transfer? token-a amount-a tx-sender (as-contract tx-sender)))
    (try! (ft-transfer? token-b amount-b tx-sender (as-contract tx-sender)))
    
    ;; Update pool reserves
    (map-set liquidity-pools pool-id (merge pool-data {
      token-a-reserve: (+ (get token-a-reserve pool-data) amount-a),
      token-b-reserve: (+ (get token-b-reserve pool-data) amount-b),
      total-lp-tokens: (+ current-total-supply lp-tokens-to-mint)
    }))
    
    ;; Mint LP tokens to user
    (try! (ft-mint? lp-token lp-tokens-to-mint tx-sender))
    
    ;; Update user position
    (match existing-position
      current-position
      (map-set user-positions { pool-id: pool-id, user: tx-sender } (merge current-position {
        lp-tokens: (+ (get lp-tokens current-position) lp-tokens-to-mint),
        token-a-deposited: (+ (get token-a-deposited current-position) amount-a),
        token-b-deposited: (+ (get token-b-deposited current-position) amount-b),
        last-activity: burn-block-height
      }))
      (map-set user-positions { pool-id: pool-id, user: tx-sender } {
        lp-tokens: lp-tokens-to-mint,
        token-a-deposited: amount-a,
        token-b-deposited: amount-b,
        last-activity: burn-block-height
      })
    )
    
    (print { action: "liquidity-added", pool-id: pool-id, amount-a: amount-a, amount-b: amount-b, lp-tokens: lp-tokens-to-mint })
    (ok lp-tokens-to-mint)
  )
)

(define-public (remove-liquidity (pool-id uint) (lp-tokens uint))
  (let (
    (pool-data (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
    (user-position (unwrap! (map-get? user-positions { pool-id: pool-id, user: tx-sender }) ERR-NOT-AUTHORIZED))
    (total-supply (get total-lp-tokens pool-data))
    (amount-a-out (if (> total-supply u0) (/ (* lp-tokens (get token-a-reserve pool-data)) total-supply) u0))
    (amount-b-out (if (> total-supply u0) (/ (* lp-tokens (get token-b-reserve pool-data)) total-supply) u0))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (<= lp-tokens (get lp-tokens user-position)) ERR-INSUFFICIENT-LIQUIDITY)
    (asserts! (> lp-tokens u0) ERR-INVALID-AMOUNT)
    (asserts! (> total-supply u0) ERR-INSUFFICIENT-LIQUIDITY)
    
    ;; Burn LP tokens
    (try! (ft-burn? lp-token lp-tokens tx-sender))
    
    ;; Update pool reserves
    (map-set liquidity-pools pool-id (merge pool-data {
      token-a-reserve: (- (get token-a-reserve pool-data) amount-a-out),
      token-b-reserve: (- (get token-b-reserve pool-data) amount-b-out),
      total-lp-tokens: (- total-supply lp-tokens)
    }))
    
    ;; Update user position
    (map-set user-positions { pool-id: pool-id, user: tx-sender } (merge user-position {
      lp-tokens: (- (get lp-tokens user-position) lp-tokens),
      last-activity: burn-block-height
    }))
    
    ;; Transfer tokens back to user
    (try! (as-contract (ft-transfer? token-a amount-a-out tx-sender tx-sender)))
    (try! (as-contract (ft-transfer? token-b amount-b-out tx-sender tx-sender)))
    
    (print { action: "liquidity-removed", pool-id: pool-id, lp-tokens: lp-tokens, amount-a: amount-a-out, amount-b: amount-b-out })
    (ok { amount-a: amount-a-out, amount-b: amount-b-out })
  )
)

;; ===================================
;; SWAP FUNCTIONS
;; ===================================

(define-public (swap-a-for-b (pool-id uint) (amount-in uint) (min-amount-out uint))
  (let (
    (pool-data (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
    (amount-out (calculate-swap-amount amount-in (get token-a-reserve pool-data) (get token-b-reserve pool-data)))
    (swap-fee (/ (* amount-in SWAP-FEE) FEE-DENOMINATOR))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (get active pool-data) ERR-POOL-NOT-FOUND)
    (asserts! (> amount-in u0) ERR-INVALID-AMOUNT)
    (asserts! (> amount-out u0) ERR-INSUFFICIENT-LIQUIDITY)
    (asserts! (>= amount-out min-amount-out) ERR-SLIPPAGE-TOO-HIGH)
    
    ;; Transfer token-a to contract, send token-b to user
    (try! (ft-transfer? token-a amount-in tx-sender (as-contract tx-sender)))
    (try! (as-contract (ft-transfer? token-b amount-out tx-sender tx-sender)))
    
    ;; Update pool reserves
    (map-set liquidity-pools pool-id (merge pool-data {
      token-a-reserve: (+ (get token-a-reserve pool-data) amount-in),
      token-b-reserve: (- (get token-b-reserve pool-data) amount-out)
    }))
    
    ;; Update global stats
    (var-set total-volume (+ (var-get total-volume) amount-in))
    (var-set total-fees (+ (var-get total-fees) swap-fee))
    
    (print { action: "swapped-a-for-b", pool-id: pool-id, amount-in: amount-in, amount-out: amount-out })
    (ok amount-out)
  )
)

(define-public (swap-b-for-a (pool-id uint) (amount-in uint) (min-amount-out uint))
  (let (
    (pool-data (unwrap! (map-get? liquidity-pools pool-id) ERR-POOL-NOT-FOUND))
    (amount-out (calculate-swap-amount amount-in (get token-b-reserve pool-data) (get token-a-reserve pool-data)))
    (swap-fee (/ (* amount-in SWAP-FEE) FEE-DENOMINATOR))
  )
    (asserts! (var-get platform-active) ERR-NOT-AUTHORIZED)
    (asserts! (get active pool-data) ERR-POOL-NOT-FOUND)
    (asserts! (> amount-in u0) ERR-INVALID-AMOUNT)
    (asserts! (> amount-out u0) ERR-INSUFFICIENT-LIQUIDITY)
    (asserts! (>= amount-out min-amount-out) ERR-SLIPPAGE-TOO-HIGH)
    
    ;; Transfer token-b to contract, send token-a to user
    (try! (ft-transfer? token-b amount-in tx-sender (as-contract tx-sender)))
    (try! (as-contract (ft-transfer? token-a amount-out tx-sender tx-sender)))
    
    ;; Update pool reserves
    (map-set liquidity-pools pool-id (merge pool-data {
      token-b-reserve: (+ (get token-b-reserve pool-data) amount-in),
      token-a-reserve: (- (get token-a-reserve pool-data) amount-out)
    }))
    
    ;; Update global stats
    (var-set total-volume (+ (var-get total-volume) amount-in))
    (var-set total-fees (+ (var-get total-fees) swap-fee))
    
    (print { action: "swapped-b-for-a", pool-id: pool-id, amount-in: amount-in, amount-out: amount-out })
    (ok amount-out)
  )
)

;; ===================================
;; INITIALIZATION
;; ===================================

(begin
  (print { action: "zenswap-initialized", owner: CONTRACT-OWNER })
)