/**
 * End-to-end mint test against the running API + devnet.
 *
 *   1. generate a throwaway player keypair
 *   2. airdrop it devnet SOL
 *   3. POST /mint-campaign-nft (campaign 2, bug 1)
 *   4. deserialize the base64 partially-signed transaction,
 *      sign as the player, submit, confirm
 *   5. verify via /has-completed-bug and /player-progress
 *
 * Requires the API server running on port 3100 (npm start).
 * Run from 100bugs-api-READY/:  npx ts-node scripts/test-e2e-mint.ts
 *
 * Costs the throwaway wallet a little rent+fees; the airdrop covers it.
 * The throwaway key is printed so the minted NFT can be inspected, but
 * it holds nothing of value.
 */
import { Connection, Keypair, Transaction } from "@solana/web3.js";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";

dotenv.config({ path: path.join(__dirname, "..", ".env") });

const API = "http://localhost:3100";
const CAMPAIGN_ID = 2;
// override with BUG_ID env var; a reused player that already minted a
// given bug will 409 (double-completion guard), so target a fresh bug
const BUG_ID = (() => {
  const raw = process.env.BUG_ID;
  if (raw === undefined) return 1;
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 1 || n > 20) {
    fail(`BUG_ID must be an integer 1-20 (got "${raw}")`);
  }
  return n;
})();
const AIRDROP_SOL = 0.5;
// reused players below this balance still get topped up via the faucet
const MIN_BALANCE_LAMPORTS = 0.03 * 1_000_000_000;

function fail(msg: string): never {
  console.error(`\n❌ ${msg}`);
  process.exit(1);
}

function loadPlayer(): { player: Keypair; reused: boolean } {
  const keypairPath = process.env.PLAYER_KEYPAIR;
  if (!keypairPath) {
    return { player: Keypair.generate(), reused: false };
  }
  const resolved = keypairPath.replace(/^~(?=\/)/, process.env.HOME ?? "~");
  if (!fs.existsSync(resolved)) {
    fail(`PLAYER_KEYPAIR file not found: ${resolved}`);
  }
  try {
    const secret = JSON.parse(fs.readFileSync(resolved, "utf8"));
    return { player: Keypair.fromSecretKey(new Uint8Array(secret)), reused: true };
  } catch (e: any) {
    fail(`PLAYER_KEYPAIR is not a valid keypair JSON file: ${e.message}`);
  }
}

async function getJson(url: string): Promise<any> {
  const res = await fetch(url);
  const body = await res.json();
  if (!res.ok) fail(`GET ${url} -> ${res.status}: ${JSON.stringify(body)}`);
  return body;
}

async function main() {
  const connection = new Connection(
    process.env.SOLANA_RPC_URL ?? "https://api.devnet.solana.com",
    "confirmed"
  );

  // 0. sanity: server up and in real mode
  const health = await getJson(`${API}/health`).catch(() =>
    fail(`API server not reachable on ${API} — start it with npm start`)
  );
  if (health.mode !== "real") {
    fail(`server is in '${health.mode}' mode — set USE_REAL_BLOCKCHAIN=true`);
  }
  console.log(`server ok — program ${health.programId}, campaign ${health.campaignId}`);

  // 1. player: reuse from PLAYER_KEYPAIR, else generate a throwaway
  const { player, reused } = loadPlayer();
  console.log(
    `\nplayer (${reused ? "reused from PLAYER_KEYPAIR" : "throwaway"}): ${player.publicKey.toBase58()}`
  );
  console.log(`targeting campaign ${CAMPAIGN_ID}, bug ${BUG_ID}`);

  // 2. fund: skip the airdrop if a reused player already has enough
  let balance = await connection.getBalance(player.publicKey);
  if (reused && balance >= MIN_BALANCE_LAMPORTS) {
    console.log(
      `balance: ${balance / 1_000_000_000} SOL — sufficient, skipping airdrop`
    );
  } else {
    console.log(
      `balance: ${balance / 1_000_000_000} SOL — requesting ${AIRDROP_SOL} SOL airdrop...`
    );
    try {
      const sig = await connection.requestAirdrop(
        player.publicKey,
        AIRDROP_SOL * 1_000_000_000
      );
      const latest = await connection.getLatestBlockhash("confirmed");
      await connection.confirmTransaction({ signature: sig, ...latest }, "confirmed");
    } catch (e: any) {
      fail(
        `airdrop failed (devnet faucet may be rate-limited): ${e.message}\n` +
          `   fund ${player.publicKey.toBase58()} manually and re-run, or use https://faucet.solana.com`
      );
    }
    balance = await connection.getBalance(player.publicKey);
    console.log(`balance: ${balance / 1_000_000_000} SOL`);
  }

  // 3. request the partially-signed mint transaction
  console.log(`\nrequesting mint transaction for campaign ${CAMPAIGN_ID}, bug ${BUG_ID}...`);
  const mintRes = await fetch(`${API}/mint-campaign-nft`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      wallet: player.publicKey.toBase58(),
      campaignId: CAMPAIGN_ID,
      bugId: BUG_ID,
      name: `Bug #${BUG_ID}`,
      imageUri: "ipfs://e2e-test",
    }),
  });
  const mint: any = await mintRes.json();
  if (mintRes.status === 409) {
    fail(
      `bug ${BUG_ID} already minted for this player (${JSON.stringify(mint)})\n` +
        `   this player has already completed it — rerun with BUG_ID=<other bug> to target a fresh one`
    );
  }
  if (!mintRes.ok || !mint.success) {
    fail(`mint endpoint failed (${mintRes.status}): ${JSON.stringify(mint)}`);
  }
  if (!mint.transaction) fail("mint response has no transaction field");
  console.log(`expected NFT address: ${mint.nftAddress}`);

  // 4. sign as player and submit
  const tx = Transaction.from(Buffer.from(mint.transaction, "base64"));
  tx.partialSign(player);

  console.log("submitting transaction...");
  const signature = await connection.sendRawTransaction(tx.serialize(), {
    skipPreflight: false,
  });
  console.log(`tx: ${signature}`);
  console.log(`https://solscan.io/tx/${signature}?cluster=devnet`);

  const confirmation = await connection.confirmTransaction(
    {
      signature,
      blockhash: tx.recentBlockhash!,
      lastValidBlockHeight: mint.lastValidBlockHeight,
    },
    "confirmed"
  );
  if (confirmation.value.err) {
    fail(`transaction failed on-chain: ${JSON.stringify(confirmation.value.err)}`);
  }
  console.log("✅ transaction confirmed");

  // 5. verify via the read endpoints
  const wallet = player.publicKey.toBase58();
  const completed = await getJson(`${API}/has-completed-bug/${wallet}/${BUG_ID}`);
  const progress = await getJson(`${API}/player-progress/${wallet}`);

  console.log("\n/has-completed-bug:", JSON.stringify(completed));
  console.log("/player-progress:  ", JSON.stringify(progress));

  const checks: [string, boolean][] = [
    ["completed === true", completed.completed === true],
    ["nftMinted === true", completed.nftMinted === true],
    ["nftAddress matches mint response", completed.nftAddress === mint.nftAddress],
    [`completedBugs includes ${BUG_ID}`, progress.completedBugs.includes(BUG_ID)],
    ["totalCompleted >= 1", progress.totalCompleted >= 1],
  ];

  let ok = true;
  console.log("");
  for (const [label, pass] of checks) {
    console.log(`${pass ? "✅" : "❌"} ${label}`);
    if (!pass) ok = false;
  }

  if (!ok) fail("one or more verification checks failed");

  console.log(`\n🎉 E2E mint succeeded`);
  console.log(`NFT: ${mint.nftAddress}`);
  console.log(`https://solscan.io/token/${mint.nftAddress}?cluster=devnet`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
