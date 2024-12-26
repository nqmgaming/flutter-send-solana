# Web3 Login

A Flutter project for managing a Solana wallet, including functionalities for generating and
inputting recovery phrases, setting up passwords, and performing transactions.

## Features

- Generate a new wallet with a recovery phrase
- Input an existing recovery phrase
- Set up a password for wallet security
- View wallet address and balance
- Send transactions to other Solana addresses
- Secure storage of mnemonic and password

## Getting Started

### Prerequisites

- Flutter SDK: `>=3.0.2 <4.0.0`
- Dart SDK
- A Solana RPC URL and WebSocket URL (configured in the `.env` file)

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/yourusername/web3_login.git
   cd web3_login
   ```

2. **Install dependencies:**

   ```sh
   flutter pub get
   ```

3. **Set up the `.env` file:**

   Create a `.env` file in the root directory with the following content:

   ```dotenv
   QUICKNODE_RPC_URL=https://your-quicknode-rpc-url
   QUICKNODE_RPC_WSS=wss://your-quicknode-wss-url
   ```

4. **Run the app:**

   ```sh
   flutter run
   ```

## Project Structure

- `lib/main.dart`: Entry point of the application.
- `lib/pages/`: Contains the different screens of the application.
    - `generate_phrase_page.dart`: Screen for generating a new recovery phrase.
    - `home_page.dart`: Home screen displaying wallet information and transaction functionalities.
    - `input_phrase_page.dart`: Screen for inputting an existing recovery phrase.
    - `login_page.dart`: Login screen for entering the password.
    - `setup_account_page.dart`: Screen for setting up a new account.
    - `setup_password_page.dart`: Screen for setting up a password.
- `lib/.env`: Environment variables for RPC URLs.

## Usage

### Generate a New Wallet

1. On the setup screen, select "Generate new wallet".
2. Copy and securely store the recovery phrase.
3. Set up a password for the wallet.

### Input an Existing Recovery Phrase

1. On the setup screen, select "I have a recovery Phrase".
2. Enter the 12-word recovery phrase.
3. Set up a password for the wallet.

### Send a Transaction

1. On the home screen, enter the recipient's address and the amount to send.
2. Click "Send" and verify the password.
3. The transaction will be processed and a confirmation message will be displayed.

## Dependencies

- `flutter`
- `cupertino_icons`
- `go_router`
- `solana`
- `bip39`
- `flutter_secure_storage`
- `flutter_dotenv`
- `solana_mobile_client`
