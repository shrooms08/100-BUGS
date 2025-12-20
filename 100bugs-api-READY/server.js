const express = require('express');
const cors = require('cors');
const { PublicKey, Keypair, SystemProgram, Connection } = require('@solana/web3.js');
const anchor = require('@coral-xyz/anchor');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const PROGRAM_ID = new PublicKey('AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL');
const CORE_PROGRAM_ID = new PublicKey('CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d');
const COLLECTION_ADDRESS = new PublicKey(process.env.COLLECTION_ADDRESS || '3ZQPh5QRLuGfNhY3hbCC8e5AYiLEaWaFoYVxdvTpz9gi');

// Load IDL
const IDL = require('./idl.json');

// Connection to Solana (for reading state, not signing)
const connection = process.env.SOLANA_RPC_URL 
  ? new Connection(process.env.SOLANA_RPC_URL, 'confirmed')
  : new Connection('https://api.devnet.solana.com', 'confirmed');

const USE_REAL_BLOCKCHAIN = process.env.USE_REAL_BLOCKCHAIN === 'true';

console.log('🚀 100 Bugs Solana API');
console.log('Program:', PROGRAM_ID.toString());
console.log('Collection:', COLLECTION_ADDRESS.toString());
console.log('Mode:', USE_REAL_BLOCKCHAIN ? 'REAL BLOCKCHAIN' : 'DEMO MODE');
console.log('RPC:', connection.rpcEndpoint);
console.log('');

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    programId: PROGRAM_ID.toString(),
    mode: USE_REAL_BLOCKCHAIN ? 'real' : 'demo'
  });
});

// Serve IDL for client-side transaction building
app.get('/idl', (req, res) => {
  res.json(IDL);
});

// Helper function to derive PDAs
function derivePDA(seeds, programId) {
  return PublicKey.findProgramAddressSync(seeds, programId);
}

app.post('/mint-campaign-nft', async (req, res) => {
  try {
    const { wallet, bugId, name, imageUri, campaignId = 1 } = req.body;
    
    if (!wallet) {
      return res.status(400).json({ 
        success: false, 
        error: 'Wallet address is required' 
      });
    }
    
    console.log(`\n${'='.repeat(60)}`);
    console.log(`🎨 MINTING NFT - Bug #${bugId}`);
    console.log(`${'='.repeat(60)}`);
    console.log(`👤 Wallet: ${wallet}`);
    console.log(`📝 Name: ${name}`);
    console.log(`🖼️  Image: ${imageUri?.substring(0, 50)}...`);
    console.log(`📋 Campaign ID: ${campaignId}`);
    
    const playerPubkey = new PublicKey(wallet);
    
    // Derive PDAs
    const [campaignPda] = derivePDA(
      [Buffer.from('campaign'), Buffer.from([campaignId])],
      PROGRAM_ID
    );
    
    const [campaignCompletionPda] = derivePDA(
      [
        Buffer.from('completion'),
        Buffer.from([campaignId]),
        playerPubkey.toBuffer(),
        Buffer.from([bugId])
      ],
      PROGRAM_ID
    );
    
    const [collectionAuthorityPda] = derivePDA(
      [Buffer.from('collection'), COLLECTION_ADDRESS.toBuffer()],
      PROGRAM_ID
    );
    
    const [playerProgressPda] = derivePDA(
      [
        Buffer.from('progress'),
        Buffer.from([campaignId]),
        playerPubkey.toBuffer()
      ],
      PROGRAM_ID
    );
    
    // Generate NFT asset keypair (client will sign this)
    const assetKeypair = Keypair.generate();
    
    console.log(`\n📍 PDAs:`);
    console.log(`   Campaign: ${campaignPda.toString()}`);
    console.log(`   Completion: ${campaignCompletionPda.toString()}`);
    console.log(`   Collection Authority: ${collectionAuthorityPda.toString()}`);
    console.log(`   Asset (NFT): ${assetKeypair.publicKey.toString()}`);
    
    if (USE_REAL_BLOCKCHAIN) {
      // Check if campaign completion exists (if not, need to start campaign first)
      let needsStartCampaign = false;
      try {
        const completionAccount = await connection.getAccountInfo(campaignCompletionPda);
        needsStartCampaign = !completionAccount;
      } catch (e) {
        needsStartCampaign = true;
      }
      
      // Build transaction instructions
      const instructions = [];
      
      // Step 1: Start campaign if needed
      if (needsStartCampaign) {
        console.log(`\n📝 Step 1: Building start_campaign instruction...`);
        instructions.push({
          type: 'start_campaign',
          programId: PROGRAM_ID.toString(),
          accounts: {
            player: wallet,
            campaignCompletion: campaignCompletionPda.toString(),
            campaign: campaignPda.toString(),
            systemProgram: SystemProgram.programId.toString()
          },
          args: {
            campaign_id: campaignId,
            bug_id: bugId
          }
        });
      }
      
      // Step 2: Record completion
      console.log(`\n📝 Step 2: Building record_campaign_completion instruction...`);
      instructions.push({
        type: 'record_campaign_completion',
        programId: PROGRAM_ID.toString(),
        accounts: {
          player: wallet,
          campaignCompletion: campaignCompletionPda.toString(),
          playerProgress: playerProgressPda.toString(),
          campaign: campaignPda.toString(),
          systemProgram: SystemProgram.programId.toString()
        },
        args: {
          campaign_id: campaignId,
          bug_id: bugId
        }
      });
      
      // Step 3: Mint NFT
      console.log(`\n📝 Step 3: Building mint_nft instruction...`);
      instructions.push({
        type: 'mint_nft',
        programId: PROGRAM_ID.toString(),
        accounts: {
          player: wallet,
          asset: assetKeypair.publicKey.toString(),
          collection: COLLECTION_ADDRESS.toString(),
          collectionAuthority: collectionAuthorityPda.toString(),
          campaignCompletion: campaignCompletionPda.toString(),
          coreProgram: CORE_PROGRAM_ID.toString(),
          systemProgram: SystemProgram.programId.toString()
        },
        args: {
          campaign_id: campaignId,
          bug_id: bugId,
          name: name,
          nft_uri: imageUri || ''
        },
        signers: [assetKeypair.secretKey] // Client needs to sign with this keypair
      });
      
      console.log(`\n✅ Transaction instructions built!`);
      console.log(`   Instructions: ${instructions.length}`);
      console.log(`   Client will sign and send...\n`);
      
      res.json({
        success: true,
        instructions: instructions,
        assetKeypair: Array.from(assetKeypair.secretKey), // Send secret key for client to sign
        campaignId: campaignId,
        bugId: bugId,
        nftAddress: assetKeypair.publicKey.toString(),
        mode: 'real'
      });
    } else {
      // DEMO MODE - return mock data
      console.log(`\n⏳ DEMO MODE - Simulating transaction...`);
    await new Promise(r => setTimeout(r, 1500));
    
    const mockNFT = Keypair.generate().publicKey.toString();
    const mockTx = generateRealisticTxHash();
    const mockSolscan = `https://solscan.io/tx/${mockTx}?cluster=devnet`;
    
      console.log(`\n✅ NFT MINTED SUCCESSFULLY! (DEMO)`);
    console.log(`🎨 NFT Address: ${mockNFT}`);
    console.log(`📜 Transaction: ${mockTx}`);
    console.log(`${'='.repeat(60)}\n`);
    
    res.json({
      success: true,
      nftAddress: mockNFT,
      transaction: mockTx,
      solscanUrl: mockSolscan,
      bugId: bugId,
      bugName: name,
        timestamp: new Date().toISOString(),
        mode: 'demo'
    });
    }
    
  } catch (error) {
    console.error('\n❌ MINTING FAILED:', error.message);
    if (error.stack) console.error(error.stack);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

app.get('/campaign-stats/:id', async (req, res) => {
  const campaignId = parseInt(req.params.id);
  console.log(`\n📊 Campaign ${campaignId} stats requested`);
  
  res.json({
    success: true,
    campaignId: campaignId,
    exists: true,
    totalCompletions: 42,
    mode: 'demo'
  });
});

app.get('/daily-bug', (req, res) => {
  const day = Math.floor(Date.now() / 86400000);
  const bugId = (day % 20) + 1;
  const today = new Date().toISOString().split('T')[0];
  
  console.log(`\n🎲 Daily bug requested: Bug #${bugId} (${today})`);
  
  res.json({
    success: true,
    bugId: bugId,
    date: today,
    difficulty: getBugDifficulty(bugId)
  });
});

app.get('/has-completed-bug/:wallet/:bugId', (req, res) => {
  const { wallet, bugId } = req.params;
  console.log(`\n🔍 Checking if ${wallet.substring(0, 8)}... completed bug #${bugId}`);
  
  res.json({
    success: true,
    wallet: wallet,
    bugId: parseInt(bugId),
    completed: false
  });
});

app.get('/player-progress/:wallet', (req, res) => {
  const wallet = req.params.wallet;
  console.log(`\n📈 Player progress requested: ${wallet.substring(0, 8)}...`);
  
  res.json({
    success: true,
    wallet: wallet,
    completedBugs: [],
    totalCompleted: 0,
    mode: 'demo'
  });
});

// Helper function to generate realistic transaction hashes
function generateRealisticTxHash() {
  const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  let hash = '';
  for (let i = 0; i < 88; i++) {
    hash += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return hash;
}

// Helper function to get bug difficulty
function getBugDifficulty(bugId) {
  if (bugId === 1) return 'Tutorial';
  if (bugId <= 5) return 'Easy';
  if (bugId <= 10) return 'Medium';
  if (bugId <= 15) return 'Hard';
  return 'Legendary';
}

const PORT = 3000;
app.listen(PORT, () => {
  console.log('━'.repeat(60));
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log(`Mode: ${USE_REAL_BLOCKCHAIN ? 'REAL BLOCKCHAIN' : 'DEMO'}`);
  console.log('━'.repeat(60));
  console.log('\n📋 Available endpoints:');
  console.log('  GET  /health');
  console.log('  GET  /idl');
  console.log('  POST /mint-campaign-nft');
  console.log('  GET  /campaign-stats/:id');
  console.log('  GET  /daily-bug');
  console.log('  GET  /has-completed-bug/:wallet/:bugId');
  console.log('  GET  /player-progress/:wallet');
  console.log('\n🎮 Ready for NFT minting!\n');
});