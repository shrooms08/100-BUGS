/**
 * Create the Metaplex Core collection for the campaign, signed by the
 * game authority (WALLET_PRIVATE_KEY) with the collection keypair from
 * COLLECTION_SECRET_KEY.
 *
 * Run from 100bugs-api-READY/:  npx ts-node scripts/create-collection.ts
 *
 * On-chain constraint: creator must equal campaign.game_authority, so
 * the campaign (CAMPAIGN_ID in .env) must already be initialized with
 * this wallet as its game authority.
 *
 * NOTE: CollectionAuthority stores nft_name / nft_uri with max_len(32).
 * Keep NFT_NAME and NFT_URI at 32 bytes or less or the instruction
 * fails with AccountDidNotSerialize.
 */
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Connection, Keypair, PublicKey, SystemProgram } from "@solana/web3.js";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

dotenv.config({ path: path.join(__dirname, "..", ".env") });

const CORE_PROGRAM_ID = new PublicKey(
  "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d"
);

const COLLECTION_NAME = "100 Bugs Season 1";
const COLLECTION_URI = "ipfs://placeholder-collection-metadata";
// both stored on-chain with max_len(32) — keep short
const NFT_NAME = "100 Bugs Badge";
const NFT_URI = "ipfs://default";

function envKeypair(name: string): Keypair {
  const raw = process.env[name];
  if (!raw) throw new Error(`missing ${name} in .env`);
  return Keypair.fromSecretKey(new Uint8Array(JSON.parse(raw)));
}

async function main() {
  const gameAuthority = envKeypair("WALLET_PRIVATE_KEY");
  const collection = envKeypair("COLLECTION_SECRET_KEY");
  const campaignId = parseInt(process.env.CAMPAIGN_ID ?? "", 10);
  if (!Number.isInteger(campaignId) || campaignId < 1 || campaignId > 255) {
    throw new Error("CAMPAIGN_ID must be an integer 1-255 in .env");
  }

  const connection = new Connection(
    process.env.SOLANA_RPC_URL ?? "https://api.devnet.solana.com",
    "confirmed"
  );
  const provider = new anchor.AnchorProvider(
    connection,
    new anchor.Wallet(gameAuthority),
    { commitment: "confirmed" }
  );
  anchor.setProvider(provider);

  const idl = JSON.parse(
    fs.readFileSync(path.join(__dirname, "..", "idl.json"), "utf8")
  );
  const program = new Program(idl, provider);

  const campaignPda = PublicKey.findProgramAddressSync(
    [Buffer.from("campaign"), Buffer.from([campaignId])],
    program.programId
  )[0];
  const collectionAuthorityPda = PublicKey.findProgramAddressSync(
    [Buffer.from("collection"), collection.publicKey.toBuffer()],
    program.programId
  )[0];

  console.log("program:              ", program.programId.toBase58());
  console.log("campaign PDA:         ", campaignPda.toBase58());
  console.log("game authority:       ", gameAuthority.publicKey.toBase58());
  console.log("collection:           ", collection.publicKey.toBase58());
  console.log("collection authority: ", collectionAuthorityPda.toBase58());

  const existing = await connection.getAccountInfo(collection.publicKey);
  if (existing) {
    console.log("\ncollection account already exists — nothing to do");
    return;
  }

  const nameBytes = Buffer.byteLength(NFT_NAME, "utf8");
  const uriBytes = Buffer.byteLength(NFT_URI, "utf8");
  if (nameBytes > 32 || uriBytes > 32) {
    throw new Error(
      `NFT_NAME (${nameBytes}B) and NFT_URI (${uriBytes}B) must each be <= 32 bytes`
    );
  }

  const sig = await program.methods
    .createCollection(campaignId, {
      name: COLLECTION_NAME,
      uri: COLLECTION_URI,
      nftName: NFT_NAME,
      nftUri: NFT_URI,
    })
    .accounts({
      creator: gameAuthority.publicKey,
      collection: collection.publicKey,
      collectionAuthority: collectionAuthorityPda,
      campaign: campaignPda,
      coreProgram: CORE_PROGRAM_ID,
      systemProgram: SystemProgram.programId,
    })
    .signers([collection])
    .rpc();

  console.log("\ncreate_collection tx:", sig);
  console.log(`https://solscan.io/tx/${sig}?cluster=devnet`);

  const authority = await (program.account as any).collectionAuthority.fetch(
    collectionAuthorityPda
  );
  console.log("\non-chain CollectionAuthority:");
  console.log("  creator:   ", authority.creator.toBase58());
  console.log("  collection:", authority.collection.toBase58());
  console.log("  nft_name:  ", authority.nftName);
  console.log("  nft_uri:   ", authority.nftUri);

  const ok = authority.creator.equals(gameAuthority.publicKey);
  console.log(ok ? "\n✅ collection created" : "\n❌ creator mismatch");
  if (!ok) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
