const express = require('express');
const cors = require('cors');
const { PublicKey, Keypair, SystemProgram, Connection, Transaction } = require('@solana/web3.js');
const anchor = require('@coral-xyz/anchor');
require('dotenv').config();

// ---------- configuration (env-driven, no hardcoded fallbacks) ----------

function requireEnv(...names) {
  for (const n of names) {
    if (process.env[n]) return process.env[n];
  }
  console.error(`❌ Missing required env var: ${names.join(' or ')} (check .env)`);
  process.exit(1);
}

const PORT = parseInt(requireEnv('PORT'), 10);
const PROGRAM_ID = new PublicKey(requireEnv('PROGRAM_ID'));
const COLLECTION_ADDRESS = new PublicKey(
  requireEnv('COLLECTION_ADDRESS', 'COLLECTION_PUBLIC_KEY')
);
const CAMPAIGN_ID = parseInt(requireEnv('CAMPAIGN_ID'), 10);

// Metaplex Core has a single fixed program id on every cluster
const CORE_PROGRAM_ID = new PublicKey('CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d');

// Game authority: co-signs record_campaign_completion (required signer on-chain)
const gameAuthority = Keypair.fromSecretKey(
  new Uint8Array(JSON.parse(requireEnv('WALLET_PRIVATE_KEY')))
);

const IDL = require('./idl.json');
if (IDL.address !== PROGRAM_ID.toString()) {
  console.error(
    `❌ idl.json address (${IDL.address}) does not match PROGRAM_ID (${PROGRAM_ID}). ` +
      'Re-export the IDL from the program build.'
  );
  process.exit(1);
}

const connection = new Connection(
  process.env.SOLANA_RPC_URL || 'https://api.devnet.solana.com',
  'confirmed'
);
const provider = new anchor.AnchorProvider(connection, new anchor.Wallet(gameAuthority), {
  commitment: 'confirmed',
});
const program = new anchor.Program(IDL, provider);

const app = express();
app.use(cors());
app.use(express.json());

console.log('🚀 100 Bugs Solana API');
console.log('Program:', PROGRAM_ID.toString());
console.log('Collection:', COLLECTION_ADDRESS.toString());
console.log('Campaign:', CAMPAIGN_ID);
console.log('Game authority:', gameAuthority.publicKey.toString());
console.log('Mode: REAL BLOCKCHAIN');
console.log('RPC:', connection.rpcEndpoint);
console.log('');

// ---------- helpers ----------

function derivePDA(seeds, programId) {
  return PublicKey.findProgramAddressSync(seeds, programId);
}

function parseWallet(value) {
  try {
    return new PublicKey(value);
  } catch {
    return null;
  }
}

function parseBugId(value) {
  const n = Number(value);
  return Number.isInteger(n) && n >= 1 && n <= 20 ? n : null;
}

function parseCampaignId(value) {
  const n = Number(value);
  return Number.isInteger(n) && n >= 1 && n <= 255 ? n : null;
}

function completionPda(campaignId, playerPubkey, bugId) {
  return derivePDA(
    [
      Buffer.from('completion'),
      Buffer.from([campaignId]),
      playerPubkey.toBuffer(),
      Buffer.from([bugId]),
    ],
    PROGRAM_ID
  )[0];
}

function progressPda(campaignId, playerPubkey) {
  return derivePDA(
    [Buffer.from('progress'), Buffer.from([campaignId]), playerPubkey.toBuffer()],
    PROGRAM_ID
  )[0];
}

function campaignPda(campaignId) {
  return derivePDA([Buffer.from('campaign'), Buffer.from([campaignId])], PROGRAM_ID)[0];
}

// ---------- endpoints ----------

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    programId: PROGRAM_ID.toString(),
    campaignId: CAMPAIGN_ID,
    mode: 'real',
  });
});

// Serve IDL for client-side transaction building
app.get('/idl', (req, res) => {
  res.json(IDL);
});

app.post('/mint-campaign-nft', async (req, res) => {
  try {
    const { wallet, name, imageUri } = req.body;
    const bugId = parseBugId(req.body.bugId);
    const campaignId = parseCampaignId(req.body.campaignId ?? CAMPAIGN_ID);

    const playerPubkey = wallet ? parseWallet(wallet) : null;
    if (!playerPubkey) {
      return res.status(400).json({ success: false, error: 'Valid wallet address is required' });
    }
    if (!bugId) {
      return res.status(400).json({ success: false, error: 'bugId must be an integer 1-20' });
    }
    if (!campaignId) {
      return res.status(400).json({ success: false, error: 'campaignId must be an integer 1-255' });
    }

    console.log(`\n${'='.repeat(60)}`);
    console.log(`🎨 MINTING NFT - Bug #${bugId} (campaign ${campaignId})`);
    console.log(`👤 Wallet: ${wallet}`);

    const campaign = campaignPda(campaignId);
    const completion = completionPda(campaignId, playerPubkey, bugId);
    const progress = progressPda(campaignId, playerPubkey);
    const [collectionAuthority] = derivePDA(
      [Buffer.from('collection'), COLLECTION_ADDRESS.toBuffer()],
      PROGRAM_ID
    );

    {
      const completionAccount = await program.account.campaignCompletion.fetchNullable(completion);

      if (completionAccount?.nftMintAddress) {
        return res.status(409).json({
          success: false,
          error: 'NFT already minted for this bug',
          nftAddress: completionAccount.nftMintAddress.toString(),
        });
      }

      const assetKeypair = Keypair.generate();
      const instructions = [];

      if (!completionAccount) {
        instructions.push(
          await program.methods
            .startCampaign(campaignId, bugId)
            .accounts({
              player: playerPubkey,
              campaignCompletion: completion,
              campaign,
              systemProgram: SystemProgram.programId,
            })
            .instruction()
        );
      }

      if (!completionAccount?.campaignEnd) {
        instructions.push(
          await program.methods
            .recordCampaignCompletion(campaignId, bugId)
            .accounts({
              player: playerPubkey,
              gameAuthority: gameAuthority.publicKey,
              campaignCompletion: completion,
              playerProgress: progress,
              campaign,
              systemProgram: SystemProgram.programId,
            })
            .instruction()
        );
      }

      instructions.push(
        await program.methods
          .mintNft(campaignId, bugId, name || `Bug #${bugId}`, imageUri || '')
          .accounts({
            player: playerPubkey,
            asset: assetKeypair.publicKey,
            collection: COLLECTION_ADDRESS,
            collectionAuthority,
            campaignCompletion: completion,
            coreProgram: CORE_PROGRAM_ID,
            systemProgram: SystemProgram.programId,
          })
          .instruction()
      );

      const tx = new Transaction().add(...instructions);
      tx.feePayer = playerPubkey;
      const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash('confirmed');
      tx.recentBlockhash = blockhash;
      // Server signs as game authority (required for record_campaign_completion)
      // and as the ephemeral asset. The asset secret key never leaves the server.
      tx.partialSign(gameAuthority, assetKeypair);

      const serialized = tx
        .serialize({ requireAllSignatures: false, verifySignatures: false })
        .toString('base64');

      console.log(`✅ Partially-signed transaction built (${instructions.length} instructions)`);
      console.log(`   NFT will be: ${assetKeypair.publicKey.toString()}\n`);

      return res.json({
        success: true,
        transaction: serialized, // base64; player signs as fee payer and submits
        lastValidBlockHeight,
        nftAddress: assetKeypair.publicKey.toString(),
        campaignId,
        bugId,
      });
    }
  } catch (error) {
    console.error('\n❌ MINTING FAILED:', error.message);
    if (error.stack) console.error(error.stack);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/campaign-stats/:id', async (req, res) => {
  const campaignId = parseCampaignId(req.params.id);
  if (!campaignId) {
    return res.status(400).json({ success: false, error: 'campaign id must be 1-255' });
  }

  try {
    const account = await program.account.campaign.fetchNullable(campaignPda(campaignId));
    if (!account) {
      return res.json({ success: true, campaignId, exists: false });
    }
    res.json({
      success: true,
      campaignId,
      exists: true,
      gameAuthority: account.gameAuthority.toString(),
      totalCompletions: account.totalCompletions,
    });
  } catch (error) {
    console.error('❌ campaign-stats failed:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Today's bug comes from the on-chain DailyBug singleton PDA, set by the
// request_daily_bug -> consume_daily_bug VRF flow. If no bug has been
// consumed yet, report that honestly instead of inventing one.
app.get('/daily-bug', async (req, res) => {
  try {
    const [bugStatePda] = derivePDA([Buffer.from('daily_bug_seed')], PROGRAM_ID);
    const state = await program.account.dailyBug.fetchNullable(bugStatePda);

    if (!state) {
      return res.json({
        success: true,
        available: false,
        reason: 'daily bug has never been requested on-chain',
      });
    }

    const day = state.day.toNumber ? state.day.toNumber() : Number(state.day);
    const currentDay = Math.floor(Date.now() / 1000 / 86400);

    if (state.bugId === null || state.bugId === undefined) {
      return res.json({
        success: true,
        available: false,
        reason: 'daily bug requested but randomness not yet consumed',
        day,
      });
    }

    const bugId = state.bugId;
    res.json({
      success: true,
      available: true,
      stale: day < currentDay, // on-chain bug is from a previous day
      bugId,
      day,
      difficulty: getBugDifficulty(bugId),
    });
  } catch (error) {
    console.error('❌ daily-bug failed:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/has-completed-bug/:wallet/:bugId', async (req, res) => {
  const playerPubkey = parseWallet(req.params.wallet);
  const bugId = parseBugId(req.params.bugId);
  const campaignId = parseCampaignId(req.query.campaignId ?? CAMPAIGN_ID);
  if (!playerPubkey) {
    return res.status(400).json({ success: false, error: 'invalid wallet address' });
  }
  if (!bugId) {
    return res.status(400).json({ success: false, error: 'bugId must be 1-20' });
  }
  if (!campaignId) {
    return res.status(400).json({ success: false, error: 'campaignId must be 1-255' });
  }

  try {
    const account = await program.account.campaignCompletion.fetchNullable(
      completionPda(campaignId, playerPubkey, bugId)
    );
    res.json({
      success: true,
      wallet: req.params.wallet,
      campaignId,
      bugId,
      started: !!account,
      completed: !!account?.campaignEnd,
      nftMinted: !!account?.nftMintAddress,
      nftAddress: account?.nftMintAddress?.toString() ?? null,
    });
  } catch (error) {
    console.error('❌ has-completed-bug failed:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/player-progress/:wallet', async (req, res) => {
  const playerPubkey = parseWallet(req.params.wallet);
  const campaignId = parseCampaignId(req.query.campaignId ?? CAMPAIGN_ID);
  if (!playerPubkey) {
    return res.status(400).json({ success: false, error: 'invalid wallet address' });
  }
  if (!campaignId) {
    return res.status(400).json({ success: false, error: 'campaignId must be 1-255' });
  }

  try {
    const account = await program.account.playerProgress.fetchNullable(
      progressPda(campaignId, playerPubkey)
    );
    const completedBugs = account ? Array.from(account.completedBugs) : [];
    res.json({
      success: true,
      wallet: req.params.wallet,
      campaignId,
      completedBugs,
      totalCompleted: account ? account.totalCompletedBugs : 0,
    });
  } catch (error) {
    console.error('❌ player-progress failed:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

function getBugDifficulty(bugId) {
  if (bugId === 1) return 'Tutorial';
  if (bugId <= 5) return 'Easy';
  if (bugId <= 10) return 'Medium';
  if (bugId <= 15) return 'Hard';
  return 'Legendary';
}

const server = app.listen(PORT, () => {
  console.log('━'.repeat(60));
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log('Mode: REAL BLOCKCHAIN');
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

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use. Set PORT in .env to a free port.`);
    process.exit(1);
  }
  throw err;
});
