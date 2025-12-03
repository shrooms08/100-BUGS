const express = require('express');
const cors = require('cors');
const anchor = require('@coral-xyz/anchor');
const { PublicKey, Keypair, SystemProgram, Connection } = require('@solana/web3.js');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Solana connection
const DEVNET_URL = process.env.SOLANA_RPC_URL || 'https://api.devnet.solana.com';
const connection = new Connection(DEVNET_URL, 'confirmed');

// Program ID (from your contract)
const PROGRAM_ID = new PublicKey('AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL');

// IDL (from your deployed contract)
const IDL = {
  "address": "AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL",
  "metadata": {
    "name": "cmpgn",
    "version": "0.1.0",
    "spec": "0.1.0"
  },
  "instructions": [
    {
      "name": "mint_nft",
      "discriminator": [211, 57, 6, 167, 15, 219, 35, 251],
      "accounts": [
        { "name": "minter", "writable": true, "signer": true },
        { "name": "asset", "writable": true, "signer": true },
        { "name": "collection", "writable": true },
        { "name": "collection_authority" },
        { "name": "core_program", "address": "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d" },
        { "name": "system_program", "address": "11111111111111111111111111111111" }
      ],
      "args": [
        { "name": "bug_id", "type": "u8" },
        { "name": "name", "type": "string" },
        { "name": "nft_uri", "type": "string" }
      ]
    }
  ]
};

// Setup Anchor provider and program
let program = null;

async function setupProgram(walletKeypair) {
  const wallet = new anchor.Wallet(walletKeypair);
  const provider = new anchor.AnchorProvider(
    connection,
    wallet,
    { commitment: 'confirmed' }
  );
  program = new anchor.Program(IDL, provider);
  return program;
}

console.log('🚀 100 Bugs Solana API Server');
console.log(`📡 Connected to: ${DEVNET_URL}`);
console.log(`📋 Program ID: ${PROGRAM_ID.toString()}`);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    network: 'devnet',
    programId: PROGRAM_ID.toString()
  });
});

// Endpoint: Mint Campaign NFT
app.post('/mint-campaign-nft', async (req, res) => {
  try {
    const { wallet, bugId, name, description, imageUri, difficulty, collectionAddress } = req.body;

    // Validate inputs
    if (!wallet || !bugId || !name || !imageUri || !collectionAddress) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: wallet, bugId, name, imageUri, collectionAddress'
      });
    }

    console.log('🎨 Minting Campaign NFT:');
    console.log(`  - Wallet: ${wallet}`);
    console.log(`  - Bug ID: ${bugId}`);
    console.log(`  - Name: ${name}`);
    console.log(`  - Image URI: ${imageUri}`);
    console.log(`  - Collection: ${collectionAddress}`);

    // For now, return mock response
    // TODO: You need to provide a wallet keypair with SOL to sign transactions
    // Once you have that, we'll build the real transaction
    
    const mockNftAddress = Keypair.generate().publicKey.toString();
    
    console.log('⚠️  NOTE: This is still a mock response.');
    console.log('   To mint real NFTs, you need to:');
    console.log('   1. Set WALLET_PRIVATE_KEY in .env');
    console.log('   2. Ensure wallet has Devnet SOL');
    console.log('   3. Uncomment the real transaction code below');
    
    /*
    // REAL TRANSACTION CODE (uncomment when you have wallet):
    
    // Load your wallet from environment
    const walletPrivateKey = JSON.parse(process.env.WALLET_PRIVATE_KEY);
    const payerKeypair = Keypair.fromSecretKey(new Uint8Array(walletPrivateKey));
    
    // Setup program
    const program = await setupProgram(payerKeypair);
    
    // Generate new asset keypair
    const assetKeypair = Keypair.generate();
    
    // Collection public key
    const collectionPubkey = new PublicKey(collectionAddress);
    
    // Derive collection authority PDA
    const [collectionAuthorityPda] = PublicKey.findProgramAddressSync(
      [Buffer.from('collection'), collectionPubkey.toBuffer()],
      program.programId
    );
    
    // Core program ID
    const CORE_PROGRAM_ID = new PublicKey('CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d');
    
    // Build and send transaction
    const tx = await program.methods
      .mintNft(bugId, name, imageUri)
      .accounts({
        minter: payerKeypair.publicKey,
        asset: assetKeypair.publicKey,
        collection: collectionPubkey,
        collectionAuthority: collectionAuthorityPda,
        coreProgram: CORE_PROGRAM_ID,
        systemProgram: SystemProgram.programId
      })
      .signers([assetKeypair])
      .rpc();
    
    console.log('✅ Transaction signature:', tx);
    console.log('✅ NFT minted at:', assetKeypair.publicKey.toString());
    
    return res.json({
      success: true,
      message: 'NFT minted successfully',
      nftAddress: assetKeypair.publicKey.toString(),
      transaction: tx,
      bugId: bugId,
      name: name,
      imageUri: imageUri
    });
    */
    
    // Simulate transaction delay
    await new Promise(resolve => setTimeout(resolve, 1000));

    res.json({
      success: true,
      message: 'NFT minted successfully (MOCK)',
      nftAddress: mockNftAddress,
      bugId: bugId,
      name: name,
      imageUri: imageUri,
      note: 'This is a mock response. Set up wallet keypair to mint real NFTs.'
    });

  } catch (error) {
    console.error('❌ Error minting NFT:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Endpoint: Check if bug is completed
app.get('/has-completed-bug/:wallet/:bugId', async (req, res) => {
  try {
    const { wallet, bugId } = req.params;

    console.log(`🔍 Checking completion: Wallet ${wallet}, Bug ${bugId}`);

    // TODO: Check on-chain if wallet has completed this bug
    
    // Mock response for now
    res.json({
      success: true,
      wallet: wallet,
      bugId: parseInt(bugId),
      completed: false // Will check on-chain later
    });

  } catch (error) {
    console.error('❌ Error checking completion:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Endpoint: Get campaign stats
app.get('/campaign-stats/:campaignId', async (req, res) => {
  try {
    const { campaignId } = req.params;

    console.log(`📊 Getting stats for campaign ${campaignId}`);

    // TODO: Fetch on-chain campaign stats
    
    res.json({
      success: true,
      campaignId: parseInt(campaignId),
      totalCompletions: 0,
      uniquePlayers: 0
    });

  } catch (error) {
    console.error('❌ Error fetching stats:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`\n✅ Server running on http://localhost:${PORT}`);
  console.log(`\n📚 Available endpoints:`);
  console.log(`  GET  /health`);
  console.log(`  POST /mint-campaign-nft`);
  console.log(`  GET  /has-completed-bug/:wallet/:bugId`);
  console.log(`  GET  /campaign-stats/:campaignId`);
  console.log(`\n🎮 Ready for Godot integration!\n`);
});
