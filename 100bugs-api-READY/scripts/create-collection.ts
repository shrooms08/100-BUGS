console.log("== create-collection.ts starting ==");
/**
 * Create the Metaplex Core collection for the campaign, signed by the
 * game authority (WALLET_PRIVATE_KEY) with the collection keypair from
 * COLLECTION_SECRET_KEY.
 *
 * Run from 100bugs-api-READY/:
 *   npx ts-node scripts/create-collection.ts            # real run
 *   npx ts-node scripts/create-collection.ts --dry-run  # build only, send nothing
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

const DRY_RUN = process.argv.includes("--dry-run");

// If the process exits before we explicitly said we're done, say so —
// this catches "silent exit" failure modes (unresolved promises, broken
// toolchains) instead of dying with no output.
let finished = false;
process.on("beforeExit", (code) => {
  if (!finished) {
    console.error(
      `\n❌ script exited prematurely (code ${code}) — an await never resolved ` +
        "or the event loop drained before completion"
    );
    process.exitCode = 1;
  }
});

function step(msg: string) {
  console.log(`\n[${new Date().toISOString().slice(11, 19)}] ${msg}`);
}

function fail(msg: string, err?: any): never {
  console.error(`\n❌ ${msg}`);
  if (err) {
    if (err.error?.errorCode) {
      console.error(
        `   anchor error: ${err.error.errorCode.code} (${err.error.errorCode.number}) — ${err.error.errorMessage ?? ""}`
      );
    }
    if (Array.isArray(err.logs)) {
      console.error("   program logs:");
      for (const l of err.logs) console.error(`     ${l}`);
    }
    if (err.message) console.error(`   message: ${err.message}`);
  }
  finished = true;
  process.exit(1);
}

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
  if (!raw) fail(`missing ${name} in .env`);
  try {
    return Keypair.fromSecretKey(new Uint8Array(JSON.parse(raw!)));
  } catch (e: any) {
    fail(`${name} is not a valid keypair array`, e);
  }
}

async function main() {
  step("loading .env");
  const envPath = path.join(__dirname, "..", ".env");
  if (!fs.existsSync(envPath)) fail(`.env not found at ${envPath}`);
  dotenv.config({ path: envPath });

  step("loading wallets from env");
  const gameAuthority = envKeypair("WALLET_PRIVATE_KEY");
  const collection = envKeypair("COLLECTION_SECRET_KEY");
  console.log("  game authority:", gameAuthority.publicKey.toBase58());
  console.log("  collection:    ", collection.publicKey.toBase58());

  const campaignId = parseInt(process.env.CAMPAIGN_ID ?? "", 10);
  if (!Number.isInteger(campaignId) || campaignId < 1 || campaignId > 255) {
    fail("CAMPAIGN_ID must be an integer 1-255 in .env");
  }
  console.log("  campaign id:   ", campaignId);

  step("connecting to RPC");
  const rpcUrl = process.env.SOLANA_RPC_URL ?? "https://api.devnet.solana.com";
  const connection = new Connection(rpcUrl, "confirmed");
  console.log("  rpc:", rpcUrl);

  const provider = new anchor.AnchorProvider(
    connection,
    new anchor.Wallet(gameAuthority),
    { commitment: "confirmed" }
  );
  anchor.setProvider(provider);

  step("loading IDL");
  const idlPath = path.join(__dirname, "..", "idl.json");
  const idl = JSON.parse(fs.readFileSync(idlPath, "utf8"));
  const program = new Program(idl, provider);
  console.log("  program:", program.programId.toBase58());

  step("deriving PDAs");
  const campaignPda = PublicKey.findProgramAddressSync(
    [Buffer.from("campaign"), Buffer.from([campaignId])],
    program.programId
  )[0];
  const collectionAuthorityPda = PublicKey.findProgramAddressSync(
    [Buffer.from("collection"), collection.publicKey.toBuffer()],
    program.programId
  )[0];
  console.log("  campaign PDA:         ", campaignPda.toBase58());
  console.log("  collection authority: ", collectionAuthorityPda.toBase58());

  step("checking on-chain state");
  const campaignAccount = await (program.account as any).campaign.fetchNullable(
    campaignPda
  );
  if (!campaignAccount) {
    fail(
      `campaign ${campaignId} is not initialized on-chain — run the submodule's ` +
        "scripts/init-campaign-2.ts first"
    );
  }
  console.log("  campaign exists, game_authority:", campaignAccount.gameAuthority.toBase58());
  if (!campaignAccount.gameAuthority.equals(gameAuthority.publicKey)) {
    fail(
      `WALLET_PRIVATE_KEY (${gameAuthority.publicKey.toBase58()}) is not the ` +
        `campaign's game authority (${campaignAccount.gameAuthority.toBase58()}) — ` +
        "create_collection will be rejected with NotAuthorized"
    );
  }

  const existing = await connection.getAccountInfo(collection.publicKey);
  if (existing) {
    console.log(
      `\n✅ collection account ${collection.publicKey.toBase58()} already exists — nothing to do`
    );
    finished = true;
    return;
  }
  console.log("  collection account does not exist yet — will create");

  const balance = await connection.getBalance(gameAuthority.publicKey);
  console.log(`  game authority balance: ${balance / 1e9} SOL`);
  if (balance < 5_000_000) {
    fail("game authority has less than 0.005 SOL — fund it before running");
  }

  step("validating args");
  const nameBytes = Buffer.byteLength(NFT_NAME, "utf8");
  const uriBytes = Buffer.byteLength(NFT_URI, "utf8");
  console.log(`  nft_name: "${NFT_NAME}" (${nameBytes}B / 32B max)`);
  console.log(`  nft_uri:  "${NFT_URI}" (${uriBytes}B / 32B max)`);
  if (nameBytes > 32 || uriBytes > 32) {
    fail("NFT_NAME and NFT_URI must each be <= 32 bytes (on-chain max_len)");
  }

  step("building create_collection instruction");
  const builder = program.methods
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
    .signers([collection]);

  const ix = await builder.instruction();
  console.log(`  instruction built: ${ix.keys.length} accounts, ${ix.data.length}B data`);

  if (DRY_RUN) {
    console.log("\n🏁 DRY RUN — stopping before signing/sending. Everything above is valid.");
    finished = true;
    return;
  }

  step("sending transaction");
  let sig: string;
  try {
    sig = await builder.rpc();
  } catch (e: any) {
    fail("create_collection transaction failed", e);
  }
  console.log("  tx:", sig!);
  console.log(`  https://solscan.io/tx/${sig!}?cluster=devnet`);

  step("verifying on-chain CollectionAuthority");
  const authority = await (program.account as any).collectionAuthority.fetch(
    collectionAuthorityPda
  );
  console.log("  creator:   ", authority.creator.toBase58());
  console.log("  collection:", authority.collection.toBase58());
  console.log("  nft_name:  ", authority.nftName);
  console.log("  nft_uri:   ", authority.nftUri);

  if (!authority.creator.equals(gameAuthority.publicKey)) {
    fail("creator mismatch in stored CollectionAuthority");
  }

  console.log("\n✅ collection created and verified");
  finished = true;
}

main().catch((e) => {
  fail("unhandled error", e);
});
