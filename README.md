# Peng-Protocol
A Decentralized Network for Creating Liquid Tokens Using Coded Transaction Inputs on the Monero Blockchain
# Definitions

HYPRv2: Hydra Protection

InLg; Internal Ledger

XMR; Monero XMR

NEO; Node Endpoint Operator

Pub-Key; Public Key (Address)

NFT; Non-Fungible Token

FFT; Float-enabled Fungible Token

Pseud: Pseudo-Treasury

LDeN: Lowest Decimal Number

DoS: Denial of Service 

# ~ Basics ~
Peng(e)v2 is a revised version of Peng(e) which addresses the issue of private key storage, in this version network nodes do not store private keys. 
Peng(e)v2 functions using coded inputs to "Pseudo-treasuries" owned and controlled by users. Users send "coded inputs" to these addresses whose public view key is known to the network upon the Pseudo-treasury's creation. The amount sent is an instruction of what to do with the Pseud's balances. Token balances are stored inside the network. 

# ~ Network ~
Hybrid Linear Network: What you have is a node, this node has a child, that child has a subsequent child and so on, like a snake or chain of nodes. You then have a "formal website" which is an immutable IPFS object that directs to the newest non-delinquent root node with the longest chain. Root nodes can fall off and be replaced by the following node, all nodes can fall off and attempt re-discovery with non-delinquent nodes. All actions require consensus with the root, roots must act in accordance with what is agreed by all nodes to be sequentially correct, all nodes acting outside of sequence are considered delinquent, all join/rejoin requests must use debugging. And finally; all nodes can break away from delinquent roots to attempt re-discovery.  

# ~ Balances ~ 
Internal Ledger (InLg): The “internal ledger” is a database of json files which the network uses to present user balances and token information. Nodes require consensus to change the InLg or they risk being kicked.
Data requisition: Client requests are directed from the formal website to the current non-delinquent root node, who then routes to a random node down the line. The information the client inputs is known to the entire network and anyone else watching, so is the data which the serving node updates in its database. 

# ~ Pseudo-Treasury ~
A Pseud is a user owned address which they encode into the database using specific inputs (transaction amounts), three kinds of Pseuds exist; Login Pseuds, which are then used to control NFT Pseuds and FFT Pseuds. Inputs from the login Pseud are used to verify ownership.  

# ~ Proofing ~
Each NFT and FFT Pseud is a public key, the public view key is made known to the network, each input sent to the Pseud from a specific “login address” is considered a valid order. The proof of each transaction is that the login Pseud that created the NFT or FFT Pseud is the same and that the input code issued by a node is what the user sent to the Pseud. 

# ~ Allocation ~
Each time a transaction is initiated the coded input is sent to the node operator’s public key; this is the same public key the node presents to the user. The input acts as a fee. 

# ~ Test by Finality ~
TeF is a way to get the current market price of a blockchain without using external data, it instead uses information from the VM nodes. Because transaction amounts are unknowable on the Monero blockchain, TeF-XMR will be based on average reward per block for the past 10 blocks, current average reward per 10 blocks (17-Jan-2023) is 0.60785‬XMR, this becomes 1XMR to 0.60785TeF-XMR‬, reward per block is an indicator of on-chain activity which in turn is an indicator of demand or price, reward per block can be used as TeF to denote the value of the chain against the overall commodities market. This data does not need to be inverted because it will go up as the chain becomes more valuable, meaning in the pairing it will be less valuable.

Full Design paper can be found [here](https://drive.google.com/file/d/1bwUl0gLsmyU5IhG-590zLvUVE2x3gRHG/view?usp=share_link)

UX visualization with easy to understand explanations and graphics can be found [here](https://medium.com/@genericmage1127/pengv2a-monero-nfts-revised-aa2ce905182d?source=user_profile---------0----------------------------)
