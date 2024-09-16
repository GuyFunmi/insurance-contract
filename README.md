# Decentralized Insurance Contract

This project implements a basic decentralized insurance smart contract using Clarity, the smart contract language for the Stacks blockchain. The contract allows users to purchase insurance policies and file claims in a trustless, decentralized manner.

## Features

- Purchase insurance policies
- File claims after a waiting period
- Check policy validity and claim status
- View contract balance

## Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): A Clarity runtime packaged as a command line tool

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/decentralized-insurance.git
   cd decentralized-insurance
   ```

2. Install Clarinet by following the [official installation guide](https://github.com/hirosystems/clarinet#installation).

3. Initialize the Clarinet project (if not already done):
   ```
   clarinet new decentralized-insurance
   ```

4. Replace the contents of `contracts/decentralized-insurance.clar` with the provided smart contract code.

5. Update `Clarinet.toml` to include your contract.

## Usage

### Testing the Contract

1. Run the Clarinet console:
   ```
   clarinet console
   ```

2. In the Clarinet console, you can interact with your contract using Clarity commands. Here are some example interactions:

   - Buy insurance:
     ```clarity
     (contract-call? .decentralized-insurance buy-insurance)
     ```

   - File a claim (note: this will only work after the waiting period):
     ```clarity
     (contract-call? .decentralized-insurance file-claim)
     ```

   - Check if an address has a valid policy:
     ```clarity
     (contract-call? .decentralized-insurance has-valid-policy tx-sender)
     ```

   - Check if an address has filed a claim:
     ```clarity
     (contract-call? .decentralized-insurance has-filed-claim tx-sender)
     ```

   - Get the contract balance:
     ```clarity
     (contract-call? .decentralized-insurance get-contract-balance)
     ```

### Deploying the Contract

To deploy this contract to the Stacks blockchain:

1. Set up a Stacks wallet and obtain some STX for the testnet or mainnet.

2. Use the Clarinet CLI or a Stacks wallet interface to deploy the contract.

3. Interact with the deployed contract using a Stacks wallet or by making direct API calls to the Stacks blockchain.

## Contract Details

- Insurance Fee: 0.1 STX
- Claim Amount: 1 STX
- Waiting Period: 144 blocks (approximately 24 hours, assuming 10-minute block times)

## Security Considerations

This is a basic implementation for educational purposes. In a production environment, consider:

- Implementing more robust access controls
- Adding additional checks and balances
- Conducting a thorough security audit
- Implementing a more sophisticated pricing model

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.