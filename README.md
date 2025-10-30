# 🏭⚡ Community Energy Royalties

A Stacks blockchain smart contract that enables local communities to receive on-chain royalty payments from nearby oil and gas fields.

## 🎯 Overview

This smart contract creates a transparent, automated system for distributing energy royalties to local communities based on their proximity to oil and gas production facilities. Field operators can deposit royalties on-chain, and communities can claim their fair share based on predefined proximity rules.

## ✨ Key Features

- 🏗️ **Field Registration**: Energy companies can register their oil/gas fields with location and production data
- 🏘️ **Community Registration**: Local communities can register to become eligible for royalty payments  
- 📍 **Proximity-Based Distribution**: Royalties are distributed based on distance from production sites
- 💰 **Automated Payments**: Smart contract handles royalty calculations and distributions
- 🔒 **Secure Claims**: Only verified community representatives can claim royalties
- 📊 **Transparent Tracking**: All payments and balances are recorded on-chain

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd Community-Energy-Royalties
clarinet check
```

## 📋 Contract Functions

### 🏭 Field Management

#### `register-energy-field`
Register a new oil/gas field
```clarity
(contract-call? .Community-Energy-Royalties register-energy-field 
  "North Field Alpha" 
  45000000    ;; latitude (45.0 degrees * 1e6)
  -122000000  ;; longitude (-122.0 degrees * 1e6)
  u1000       ;; production rate
  u500)       ;; royalty rate (5% = 500/10000)
```

#### `deposit-royalties`
Deposit STX tokens as royalty payments
```clarity
(contract-call? .Community-Energy-Royalties deposit-royalties u1)
```

#### `deactivate-field`
Deactivate a field (operators only)
```clarity
(contract-call? .Community-Energy-Royalties deactivate-field u1)
```

### 🏘️ Community Management

#### `register-community`
Register a community for royalty eligibility
```clarity
(contract-call? .Community-Energy-Royalties register-community 
  "Riverside Community"
  45100000    ;; latitude
  -121900000  ;; longitude
  u2500)      ;; population
```

#### `verify-community`
Verify a community (contract owner only)
```clarity
(contract-call? .Community-Energy-Royalties verify-community u1)
```

#### `claim-royalties`
Claim accumulated royalties (community representatives only)
```clarity
(contract-call? .Community-Energy-Royalties claim-royalties u1)
```

### 🔗 Proximity & Distribution

#### `set-proximity-eligibility`
Set royalty sharing rules for field-community pairs
```clarity
(contract-call? .Community-Energy-Royalties set-proximity-eligibility 
  u1          ;; field-id
  u1          ;; community-id
  u5000       ;; distance (5km)
  u3000)      ;; royalty share (30% = 3000/10000)
```

#### `distribute-royalties`
Distribute royalties to eligible communities
```clarity
(contract-call? .Community-Energy-Royalties distribute-royalties 
  u1 
  (list u1 u2 u3))  ;; community IDs
```

## 📖 Read-Only Functions

- `get-field-info` - Get field details
- `get-community-info` - Get community details  
- `get-operator-fields` - Get fields owned by an operator
- `get-representative-communities` - Get communities represented by a principal
- `get-payment-history` - Get payment history between field and community
- `get-proximity-info` - Get proximity eligibility rules
- `get-contract-stats` - Get overall contract statistics

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 💡 Usage Examples

### Basic Workflow

1. **Field Operator** registers their oil/gas field
2. **Community Representative** registers their community
3. **Contract Owner** verifies the community
4. **Field Operator** sets proximity eligibility rules
5. **Field Operator** deposits royalty funds
6. **Field Operator** distributes royalties to eligible communities
7. **Community Representative** claims their community's royalties

### Example Scenario

```bash
# Register field
clarinet console
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
::contract_call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM Community-Energy-Royalties register-energy-field "Eagle Ford Shale" 28500000 -97800000 u1500 u750

# Register community  
::set_tx_sender ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
::contract_call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM Community-Energy-Royalties register-community "Karnes County Community" 28600000 -97700000 u15000
```

## 🔐 Security Features

- Owner-only community verification
- Operator-only field management
- Representative-only royalty claims
- Input validation for coordinates and amounts
- Protection against unauthorized distributions

## 📊 Contract State

The contract tracks:
- Energy fields with location and production data
- Registered communities with population info
- Proximity-based eligibility rules
- Payment histories and balances
- Operator and representative mappings

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with `clarinet check` and `clarinet test`
4. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.
