-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :
	-forge install foundry-rs/forge-std --no-commit
	-forge install smartcontractkit/chainlink-brownie-contracts --no-commit
	-forge install Cyfrin/foundry-devops --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test -vvvvv
test-unit :; forge test test/unit/FundMeTest.t.sol -vvv
test-integration :; forge test test/integration/InteractionsTest.s.sol -vvv

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1


#/*//////////////////////////////////////////////////////////////
#                          DEPLOYEMENT
#//////////////////////////////////////////////////////////////*/

# Deploy to Anvil
## make anvil
## make deploy
deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# Deploy to Sepolia
## make deploy ARGS="--network sepolia"
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif


#/*//////////////////////////////////////////////////////////////
#                          INTERACTIONS
#//////////////////////////////////////////////////////////////*/

# Address of the function caller goes here. Just put in $(DEFAULT_ANVIL_ADDRESS) or $(SEPOLIA_ADDRESS)
SENDER_ADDRESS := $(SEPOLIA_ADDRESS)

# Fund last deployed contract
## Anvil: make fund
## Sepolia: make fund ARGS="--network sepolia"
fund:
	@forge script script/Interactions.s.sol:FundFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)

# Withdraw from last deployed contract
## Anvil: make withdraw
## Sepolia: make withdraw ARGS="--network sepolia"
withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)
