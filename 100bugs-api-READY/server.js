const express = require('express');
const cors = require('cors');
const { PublicKey, Keypair } = require('@solana/web3.js');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const PROGRAM_ID = new PublicKey('AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL');

console.log('🚀 100 Bugs Solana API - DEMO MODE');
console.log('📺 Ready for technical video recording');
console.log('Program:', PROGRAM_ID.toString());
console.log('✅ Mock NFT minting enabled\n');

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    programId: PROGRAM_ID.toString(),
    mode: 'demo'
  });
});

app.post('/mint-campaign-nft', async (req, res) => {
  try {
    const { bugId, name, imageUri } = req.body;
    
    console.log(`\n${'='.repeat(60)}`);
    console.log(`🎨 MINTING NFT - Bug #${bugId}`);
    console.log(`${'='.repeat(60)}`);
    console.log(`📝 Name: ${name}`);
    console.log(`🖼️  Image: ${imageUri?.substring(0, 50)}...`);
    console.log(`\n⏳ Processing blockchain transaction...`);
    
    // Simulate blockchain delay (realistic timing)
    await new Promise(r => setTimeout(r, 1500));
    
    // Generate realistic-looking addresses
    const mockNFT = Keypair.generate().publicKey.toString();
    const mockTx = generateRealisticTxHash();
    const mockSolscan = `https://solscan.io/tx/${mockTx}?cluster=devnet`;
    
    console.log(`\n✅ NFT MINTED SUCCESSFULLY!`);
    console.log(`${'='.repeat(60)}`);
    console.log(`🎯 Bug Completed: #${bugId}`);
    console.log(`🎨 NFT Address: ${mockNFT}`);
    console.log(`📜 Transaction: ${mockTx}`);
    console.log(`🔗 View on Solscan: ${mockSolscan}`);
    console.log(`${'='.repeat(60)}\n`);
    
    res.json({
      success: true,
      nftAddress: mockNFT,
      transaction: mockTx,
      solscanUrl: mockSolscan,
      bugId: bugId,
      bugName: name,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('\n❌ MINTING FAILED:', error.message);
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
  console.log('🎬 Ready to record technical demo!');
  console.log('━'.repeat(60));
  console.log('\n📋 Available endpoints:');
  console.log('  GET  /health');
  console.log('  POST /mint-campaign-nft');
  console.log('  GET  /campaign-stats/:id');
  console.log('  GET  /daily-bug');
  console.log('  GET  /has-completed-bug/:wallet/:bugId');
  console.log('  GET  /player-progress/:wallet');
  console.log('\n🎮 Start your game and begin recording!\n');
});