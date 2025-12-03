const anchor = require('@coral-xyz/anchor');
const { PublicKey, Keypair, SystemProgram, Connection } = require('@solana/web3.js');
require('dotenv').config();

// IDL
const IDL = require('./idl.json');

async function setup() {
  try {
    console.log('🚀 Setting up campaign and collection...\n');

    // Connection
    const connection = new Connection(process.env.SOLANA_RPC_URL, 'confirmed');
    
    // Load wallet
    const walletPrivateKey = JSON.parse(process.env.WALLET_PRIVATE_KEY);
    const walletKeypair = Keypair.fromSecretKey(new Uint8Array(walletPrivateKey));
    console.log('💼 Wallet:', walletKeypair.publicKey.toString());

    // Check balance
    const balance = await connection.getBalance(walletKeypair.publicKey);
    console.log('💰 Balance:', balance / 1e9, 'SOL');
    
    if (balance === 0) {
      console.error('❌ Wallet has no SOL! Airdrop some first:');
      console.error(`   solana airdrop 2 ${walletKeypair.publicKey.toString()} --url devnet`);
      process.exit(1);
    }

    // Load collection keypair
    const collectionSecretKey = JSON.parse(process.env.COLLECTION_SECRET_KEY);
    const collectionKeypair = Keypair.fromSecretKey(new Uint8Array(collectionSecretKey));
    console.log('🎨 Collection:', collectionKeypair.publicKey.toString());

    // Setup Anchor
    const wallet = new anchor.Wallet(walletKeypair);
    const provider = new anchor.AnchorProvider(connection, wallet, { commitment: 'confirmed' });
    const program = new anchor.Program(IDL, provider);

    const campaignId = parseInt(process.env.CAMPAIGN_ID || '1');
    console.log('📋 Campaign ID:', campaignId);

    // Derive campaign PDA
    const [campaignPda] = PublicKey.findProgramAddressSync(
      [Buffer.from('campaign'), Buffer.from([campaignId])],
      program.programId
    );
    console.log('📍 Campaign PDA:', campaignPda.toString());

    // Step 1: Initialize Campaign
    console.log('\n📝 Step 1: Initialize Campaign...');
    try {
      const tx1 = await program.methods
        .initialize(campaignId)
        .accounts({
          gameAuthority: walletKeypair.publicKey,
          campaign: campaignPda,
          systemProgram: SystemProgram.programId
        })
        .rpc();
      
      console.log('✅ Campaign initialized!');
      console.log('   Transaction:', tx1);
      
      // Wait for confirmation
      console.log('   Waiting for confirmation...');
      await new Promise(resolve => setTimeout(resolve, 3000));
    } catch (error) {
      console.error('❌ Error initializing campaign:', error.message);
      if (error.logs) {
        console.error('\n📋 Transaction logs:');
        error.logs.forEach(log => console.error('   ', log));
      }
      if (error.message.includes('already in use')) {
        console.log('ℹ️  Campaign already initialized, continuing...');
      } else {
        console.error('\n💡 This might mean:');
        console.error('   - Wrong campaign_id');
        console.error('   - Campaign already exists');
        console.error('   - Insufficient SOL');
        throw error;
      }
    }

    // Step 2: Create Collection
    console.log('\n🎨 Step 2: Create Collection...');
    
    // Derive collection authority PDA
    const [collectionAuthorityPda] = PublicKey.findProgramAddressSync(
      [Buffer.from('collection'), collectionKeypair.publicKey.toBuffer()],
      program.programId
    );
    console.log('📍 Collection Authority PDA:', collectionAuthorityPda.toString());

    const CORE_PROGRAM_ID = new PublicKey('CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d');

    const createCollectionArgs = {
      name: "100 Bugs Campaign",
      uri: "ipfs://bafkreidksax7r3inqjpxuaitbhq5h6mhmrd5yp2dvirac6kcixn5h2bc5u",
      nftName: "100 Bugs",
      nftUri: "ipfs://default"
    };

    try {
      console.log('   Building transaction...');
      console.log('   Accounts:');
      console.log('     creator:', walletKeypair.publicKey.toString());
      console.log('     collection:', collectionKeypair.publicKey.toString());
      console.log('     collectionAuthority:', collectionAuthorityPda.toString());
      console.log('     campaign:', campaignPda.toString());
      console.log('     coreProgram:', CORE_PROGRAM_ID.toString());
      
      const tx2 = await program.methods
        .createCollection(campaignId, createCollectionArgs)
        .accounts({
          creator: walletKeypair.publicKey,
          collection: collectionKeypair.publicKey,
          collectionAuthority: collectionAuthorityPda,
          campaign: campaignPda,
          coreProgram: CORE_PROGRAM_ID,
          systemProgram: SystemProgram.programId
        })
        .signers([collectionKeypair])
        .rpc();
      
      console.log('✅ Collection created!');
      console.log('   Transaction:', tx2);
    } catch (error) {
      console.error('❌ Error creating collection:', error.message);
      if (error.logs) {
        console.error('\n📋 Transaction logs:');
        error.logs.forEach(log => console.error('   ', log));
      }
      if (error.message.includes('already in use')) {
        console.log('ℹ️  Collection already created, continuing...');
      } else {
        console.error('\n💡 This might mean:');
        console.error('   - Campaign not initialized yet');
        console.error('   - Wrong wallet (not game authority)');
        console.error('   - Insufficient SOL');
        throw error;
      }
    }

    console.log('\n🎉 SETUP COMPLETE!');
    console.log('\n📋 Summary:');
    console.log('   Campaign PDA:', campaignPda.toString());
    console.log('   Collection:', collectionKeypair.publicKey.toString());
    console.log('   Collection Authority:', collectionAuthorityPda.toString());
    console.log('\n✅ Ready to mint NFTs!');
    console.log('   Run: npm start');

  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    if (error.logs) {
      console.error('\n📋 Full transaction logs:');
      error.logs.forEach(log => console.error(log));
    }
    console.error('\n💡 Next steps:');
    console.error('   1. Check your wallet has Devnet SOL');
    console.error('   2. Verify campaign_id is correct');
    console.error('   3. Ask your dev if there are any prerequisites');
    process.exit(1);
  }
}

setup();