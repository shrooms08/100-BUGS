# 100 Bugs Solana API

API server that wraps Solana smart contract calls for "100 Bugs You Must Exploit" game.

## Setup

### Prerequisites
- Node.js 18+ installed
- Your Solana contract deployed to Devnet

### Installation

1. Install dependencies:
```bash
npm install
```

2. Configure environment:
```bash
# Edit .env file with your settings
# Make sure PROGRAM_ID matches your deployed contract
```

3. Start the server:
```bash
npm start
```

The server will run on http://localhost:3000

## API Endpoints

### Health Check
```
GET /health
```

Returns server status and configuration.

### Mint Campaign NFT
```
POST /mint-campaign-nft

Body:
{
  "wallet": "player_wallet_address",
  "bugId": 1,
  "name": "Bug #1: Plain and Simple",
  "description": "Mastered the basics",
  "imageUri": "ipfs://bafkrei...",
  "difficulty": "Tutorial"
}

Response:
{
  "success": true,
  "nftAddress": "mint_address",
  "bugId": 1,
  "name": "Bug #1: Plain and Simple",
  "imageUri": "ipfs://..."
}
```

### Check Bug Completion
```
GET /has-completed-bug/:wallet/:bugId

Response:
{
  "success": true,
  "wallet": "...",
  "bugId": 1,
  "completed": true
}
```

### Get Campaign Stats
```
GET /campaign-stats/:campaignId

Response:
{
  "success": true,
  "campaignId": 1,
  "totalCompletions": 42,
  "uniquePlayers": 15
}
```

## Godot Integration

Example SolanaManager.gd code:

```gdscript
func mint_campaign_nft(bug_id: int, metadata: Dictionary):
    var http = HTTPRequest.new()
    add_child(http)
    
    var body = {
        "wallet": GameState.wallet_address,
        "bugId": bug_id,
        "name": metadata.name,
        "description": metadata.description,
        "imageUri": metadata.image_uri,
        "difficulty": metadata.difficulty
    }
    
    var headers = ["Content-Type: application/json"]
    http.request(
        "http://localhost:3000/mint-campaign-nft",
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(body)
    )
```

## Testing

Test the API with curl:

```bash
# Health check
curl http://localhost:3000/health

# Mint NFT
curl -X POST http://localhost:3000/mint-campaign-nft \
  -H "Content-Type: application/json" \
  -d '{
    "wallet": "test_wallet",
    "bugId": 1,
    "name": "Bug #1: Plain and Simple",
    "imageUri": "ipfs://bafkrei...",
    "difficulty": "Tutorial"
  }'
```

## Next Steps

1. Copy IDL from `cmpgn/target/idl/cmpgn.json`
2. Update server.js with actual Anchor program calls
3. Test on Devnet with real transactions
4. Deploy to production server for mainnet
