const anchor = require('@coral-xyz/anchor');
const { PublicKey, Keypair, SystemProgram, Connection } = require('@solana/web3.js');
require('dotenv').config();

const IDL = require('./idl.json');

async function initCampaign() {
  try {
    console.log('📝 Initializing Campaign...\n');

    const connection = new Connection(process.env.SOLANA_RPC_URL, 'confirmed');
    
    const walletPrivateKey = JSON.parse(process.env.WALLET_PRIVATE_KEY);
    const walletKeypair = Keypair.fromSecretKey(new Uint8Array(walletPrivateKey));
    console.log('💼 Wallet:', walletKeypair.publicKey.toString());

    const balance = await connection.getBalance(walletKeypair.publicKey);
    console.log('💰 Balance:', balance / 1e9, 'SOL\n');

    const wallet = new anchor.Wallet(walletKeypair);
    const provider = new anchor.AnchorProvider(connection, wallet, { commitment: 'confirmed' });
    const program = new anchor.Program(IDL, provider);

    const campaignId = 1;
    
    const [campaignPda] = PublicKey.findProgramAddressSync(
      [Buffer.from('campaign'), Buffer.from([campaignId])],
      program.programId
    );
    console.log('📍 Campaign PDA:', campaignPda.toString());

    console.log('\n🚀 Sending transaction...');
    const tx = await program.methods
      .initialize(campaignId)
      .accounts({
        gameAuthority: walletKeypair.publicKey,
        campaign: campaignPda,
        systemProgram: SystemProgram.programId
      })
      .rpc();
    
    console.log('\n✅ Campaign initialized!');
    console.log('   Transaction:', tx);
    console.log('   Campaign PDA:', campaignPda.toString());
    console.log('\n🎉 Success! Now run: node create-collection.js');

  } catch (error) {
    console.error('\n❌ Failed:', error.message);
    if (error.logs) {
      console.error('\n📋 Logs:');
      error.logs.forEach(log => console.error('  ', log));
    }
  }
}

initCampaign();