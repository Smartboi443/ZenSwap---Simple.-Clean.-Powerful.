# 🧘 ZenSwap - Simple. Clean. Powerful.

A minimalist decentralized AMM platform built on Stacks blockchain for effortless token swapping with zen-like simplicity.

## 📋 Overview

ZenSwap provides automated market-making functionality with zen-like simplicity, allowing users to trade between Token A and Token B through intuitive liquidity pools. Experience the calm of effortless trading.

## ✨ Key Features

### 🏊‍♂️ Automated Market Maker
- Constant product formula (x * y = k)
- 0.3% swap fee for liquidity providers
- Real-time price discovery through trading
- Slippage protection for all trades

### 💧 Liquidity Provision
- Add/remove liquidity to earn trading fees
- LP tokens represent pool ownership
- Proportional fee distribution
- Minimum liquidity requirements

### 🎯 Simple Trading
- Instant token swaps with price quotes
- Two custom tokens (Token A & Token B)
- Transparent fee structure
- Trade history tracking

## 🏗️ Architecture

### Core Components
```clarity
liquidity-pools -> Pool reserves and metadata
user-positions  -> LP token holdings per user
recent-swaps    -> Trading history and analytics
```

### Token System
- **Token A & B**: Trading pair tokens
- **LP Tokens**: Liquidity provider shares
- **Fee Collection**: 0.3% on all swaps

## 🚀 Getting Started

### For Traders

1. **Get Quotes**: Check swap rates before trading
   ```clarity
   (get-swap-a-for-b-quote pool-id amount-in)
   (get-swap-b-for-a-quote pool-id amount-in)
   ```

2. **Execute Swaps**: Trade tokens with slippage protection
   ```clarity
   (swap-a-for-b pool-id amount-in min-amount-out)
   (swap-b-for-a pool-id amount-in min-amount-out)
   ```

### For Liquidity Providers

1. **Add Liquidity**: Deposit both tokens to earn fees
   ```clarity
   (add-liquidity pool-id amount-a amount-b)
   ```

2. **Remove Liquidity**: Withdraw your share anytime
   ```clarity
   (remove-liquidity pool-id lp-tokens)
   ```

## 📊 Economics

### Trading Fees
- **Swap Fee**: 0.3% on all trades
- **Fee Distribution**: Proportional to LP token holdings
- **No Platform Fees**: All fees go to liquidity providers

### Pricing Model
- **AMM Formula**: Constant product (x * y = k)
- **Price Impact**: Larger trades have higher slippage
- **Arbitrage**: Price balances through market forces

## 📈 Example Usage

### Basic Swap
```
1. User wants 100 Token B
2. Gets quote: needs ~102 Token A
3. Executes swap with 5% slippage tolerance
4. Receives 100 Token B, pays 102.3 Token A (including 0.3% fee)
```

### Liquidity Provision
```
1. User deposits 1000 Token A + 2000 Token B
2. Receives LP tokens representing pool share
3. Earns fees from all subsequent trades
4. Can withdraw proportional amounts anytime
```

## ⚙️ Configuration

### Platform Settings
- **Minimum Liquidity**: 1,000 units
- **Swap Fee**: 30 basis points (0.3%)
- **No Lock-up Periods**: Instant liquidity withdrawal

### Pool Parameters
- **Token Pair**: Token A ↔ Token B
- **Fee Structure**: Fixed 0.3% on all swaps
- **Reserves**: Dynamic based on trading activity

## 🔒 Security Features

### Access Control
- Contract owner can mint tokens and create pools
- Users control their own LP positions
- No admin control over user funds

### Validation
- Slippage protection prevents MEV attacks
- Minimum liquidity prevents dust attacks
- Reserve calculations prevent drain attacks

### Error Codes
```clarity
ERR-NOT-AUTHORIZED (u300)        -> Insufficient permissions
ERR-POOL-NOT-FOUND (u301)        -> Invalid pool ID
ERR-INSUFFICIENT-LIQUIDITY (u302) -> Not enough pool liquidity
ERR-INVALID-AMOUNT (u303)        -> Invalid token amount
ERR-SLIPPAGE-TOO-HIGH (u304)     -> Price moved beyond tolerance
ERR-POOL-EXISTS (u305)           -> Pool already created
ERR-ZERO-LIQUIDITY (u306)        -> No liquidity provided
```

## 📊 Analytics

### Platform Metrics
- Total trading volume
- Total fees collected
- Number of active pools
- Platform activity status

### Pool Analytics
- Current token reserves
- Price ratios and trends
- Total LP tokens outstanding
- Pool creation timestamps

### User Data
- LP token balances per pool
- Historical deposit amounts
- Last activity timestamps
- Trading and LP history

## 🛠️ Development

### Local Testing
```bash
# Validate contract
clarinet check

# Run test suite
clarinet test

# Deploy locally
clarinet deploy --local
```

### Integration Examples
```clarity
;; Check trading quotes with zen-like clarity
(contract-call? .zenswap get-swap-a-for-b-quote u1 u1000000)
(contract-call? .zenswap get-swap-b-for-a-quote u1 u2000000)

;; Execute trades with peaceful confidence
(contract-call? .zenswap swap-a-for-b u1 u1000000 u1900000)
(contract-call? .zenswap swap-b-for-a u1 u2000000 u950000)

;; Add liquidity with harmonious balance
(contract-call? .zenswap add-liquidity u1 u1000000 u2000000)

;; Mint tokens for testing (admin only)
(contract-call? .zenswap mint-token-a u1000000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(contract-call? .zenswap mint-token-b u2000000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🎯 Use Cases

### DeFi Trading
- Token portfolio rebalancing
- Arbitrage opportunities
- Price discovery for new tokens

### Liquidity Mining
- Earn fees from trading volume
- Bootstrap liquidity for new tokens
- Passive income from LP positions

### Market Making
- Provide consistent liquidity
- Reduce price volatility
- Enable efficient price discovery

## 🚦 Deployment Guide

### Prerequisites
- Clarinet CLI installed
- Test tokens minted
- Pool creation permissions

### Setup Steps
1. Deploy contract to testnet
2. Create initial liquidity pool
3. Mint test tokens for users
4. Add initial liquidity
5. Enable trading

## 📄 Contract Interface

### Core Functions
```clarity
;; Trading
swap-a-for-b(pool-id, amount-in, min-out) -> amount-out
swap-b-for-a(pool-id, amount-in, min-out) -> amount-out

;; Liquidity
add-liquidity(pool-id, amount-a, amount-b) -> lp-tokens
remove-liquidity(pool-id, lp-tokens) -> {amount-a, amount-b}

;; Quotes
get-swap-a-for-b-quote(pool-id, amount-in) -> amount-out
get-swap-b-for-a-quote(pool-id, amount-in) -> amount-out
get-pool-ratio(pool-id) -> price-ratio
```

## 🤝 Contributing

We welcome contributions! Please check our GitHub repository for:
- Bug reports and feature requests
- Code improvements and optimizations
- Documentation and example updates

---

**⚠️ Disclaimer**: Trade with zen-like awareness. This is experimental DeFi software. Find your balance and understand the risks before providing liquidity.
