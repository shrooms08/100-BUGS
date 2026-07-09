
console.log("Wallet script starting...");
console.log("Location:", window.location.href);

// API base URL comes from config.js (window.API_CONFIG.BASE_URL) — the
// single source of truth. Program/collection addresses are owned by the
// server now; the client only signs and submits what the server builds.
function apiBase() {
  if (window.API_CONFIG && typeof window.API_CONFIG.BASE_URL === "string") {
    return window.API_CONFIG.BASE_URL.replace(/\/$/, "");
  }
  console.warn("API_CONFIG.BASE_URL not set — falling back to same-origin");
  return "";
}

// Wait for page to fully load before checking wallets
window.addEventListener('DOMContentLoaded', function() {
    console.log("DOM loaded, checking for wallets...");
    setTimeout(checkWalletsOnLoad, 500); // Give extensions time to inject
});

function checkWalletsOnLoad() {
    console.log("Checking wallet extensions...");
    console.log("   window.solana:", typeof window.solana);
    console.log("   window.solflare:", typeof window.solflare);
    console.log("   window.solanaWeb3:", typeof window.solanaWeb3);
    console.log("   window.Buffer:", typeof window.Buffer);

    if (window.solana) {
        console.log("    Phantom/Solana provider found! isPhantom:", window.solana.isPhantom);
    } else {
        console.log("    No Solana wallet extension detected");
    }
    if (typeof window.solanaWeb3 === "undefined") {
        console.error("    solanaWeb3 not loaded — vendor bundle missing from the page");
    }
}

// Global wallet state
window.walletState = {
    connected: false,
    address: null,
    provider: null
};

// ============================================
// CHECK FUNCTIONS
// ============================================

function isPhantomInstalled() {
    return !!(window.solana && window.solana.isPhantom);
}

function isSolflareInstalled() {
    return !!(window.solflare && window.solflare.isSolflare) || !!window.solflare;
}

function checkWallets() {
    return {
        phantom: isPhantomInstalled(),
        solflare: isSolflareInstalled()
    };
}

// ============================================
// CONNECT / DISCONNECT
// ============================================

async function connectPhantom() {
    console.log("connectPhantom() called");
    try {
        if (!isPhantomInstalled()) {
            const msg = "Phantom wallet not installed";
            window._walletResult = JSON.stringify({ success: false, error: msg });
            return window._walletResult;
        }
        const resp = await window.solana.connect();
        const address = resp.publicKey.toString();
        window.walletState = { connected: true, address: address, provider: 'phantom' };
        console.log("Phantom connected:", address);
        window._walletResult = JSON.stringify({ success: true, address: address, provider: 'phantom' });
        return window._walletResult;
    } catch (error) {
        console.error("connectPhantom error:", error);
        window._walletResult = JSON.stringify({ success: false, error: error.message || "Connect failed" });
        return window._walletResult;
    }
}

async function connectSolflare() {
    console.log("connectSolflare() called");
    try {
        if (!window.solflare) {
            const msg = "Solflare wallet not installed";
            window._walletResult = JSON.stringify({ success: false, error: msg });
            return window._walletResult;
        }
        await window.solflare.connect();
        if (!window.solflare.publicKey) {
            throw new Error("Solflare did not return a public key");
        }
        const address = window.solflare.publicKey.toString();
        window.walletState = { connected: true, address: address, provider: 'solflare' };
        console.log("Solflare connected:", address);
        window._walletResult = JSON.stringify({ success: true, address: address, provider: 'solflare' });
        return window._walletResult;
    } catch (error) {
        console.error("connectSolflare error:", error);
        window._walletResult = JSON.stringify({ success: false, error: error.message || "Connect failed" });
        return window._walletResult;
    }
}

function disconnectWallet() {
    try {
        if (window.walletState.provider === 'phantom' && window.solana) {
            window.solana.disconnect();
        } else if (window.walletState.provider === 'solflare' && window.solflare) {
            window.solflare.disconnect();
        }
    } catch (e) {
        console.warn("disconnect error (ignored):", e);
    }
    window.walletState = { connected: false, address: null, provider: null };
    return JSON.stringify({ success: true });
}

function getWalletState() {
    return JSON.stringify(window.walletState);
}

// Re-sync the JS wallet state to a saved address on session restore.
// The browser wallet cannot be silently reconnected, so this marks the
// session as "known address, needs reconnect" and returns whether the
// live extension is actually connected to that same address.
function syncWalletState(savedAddress, savedProvider) {
    const provider = savedProvider === 'solflare' ? window.solflare : window.solana;
    const liveKey = provider && provider.publicKey ? provider.publicKey.toString() : null;
    const liveConnected = !!liveKey && liveKey === savedAddress;
    if (liveConnected) {
        window.walletState = { connected: true, address: liveKey, provider: savedProvider };
    } else {
        // known address but the extension is not connected this session
        window.walletState = { connected: false, address: savedAddress, provider: savedProvider };
    }
    return JSON.stringify({
        liveConnected: liveConnected,
        address: savedAddress,
        provider: savedProvider
    });
}

function debugWallet() {
    return JSON.stringify({
        walletState: window.walletState,
        hasSolana: !!window.solana,
        hasSolflare: !!window.solflare,
        hasSolanaWeb3: typeof window.solanaWeb3 !== "undefined",
        hasBuffer: typeof window.Buffer !== "undefined",
        apiBase: apiBase()
    });
}

window.connectPhantom = connectPhantom;
window.connectSolflare = connectSolflare;
window.disconnectWallet = disconnectWallet;
window.getWalletState = getWalletState;
window.syncWalletState = syncWalletState;
window.checkWallets = checkWallets;
window.debugWallet = debugWallet;

// ============================================
// MINTING — server builds the transaction, wallet signs & submits
// (ported from scripts/test-e2e-mint.ts, the proven reference flow)
// ============================================

function activeProvider() {
    if (window.walletState.provider === 'phantom' && window.solana) return window.solana;
    if (window.walletState.provider === 'solflare' && window.solflare) return window.solflare;
    return null;
}

async function requestMintTransaction(walletAddress, bugId, name, imageUri) {
    const res = await fetch(apiBase() + "/mint-campaign-nft", {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            wallet: walletAddress,
            bugId: bugId,
            name: name,
            imageUri: imageUri || ""
        })
    });
    const data = await res.json();
    return { status: res.status, ok: res.ok, data: data };
}

async function mintCampaignNFT(bugId, name, imageUri, walletAddress) {
    console.log("mintCampaignNFT() bug", bugId, "wallet", walletAddress);
    window._mintResult = null;

    if (typeof window.solanaWeb3 === "undefined") {
        window._mintResult = JSON.stringify({ success: false, error: "solanaWeb3 not loaded" });
        return window._mintResult;
    }
    if (!window.walletState.connected || !window.walletState.address) {
        window._mintResult = JSON.stringify({ success: false, error: "Wallet not connected" });
        return window._mintResult;
    }
    if (walletAddress !== window.walletState.address) {
        window._mintResult = JSON.stringify({ success: false, error: "Wallet address mismatch" });
        return window._mintResult;
    }
    const provider = activeProvider();
    if (!provider) {
        window._mintResult = JSON.stringify({ success: false, error: "No wallet provider available" });
        return window._mintResult;
    }

    try {
        const connection = new window.solanaWeb3.Connection(
            window.API_CONFIG.RPC_URL || "https://api.devnet.solana.com",
            'confirmed'
        );

        // one re-request retry for blockhash expiry (user slow on the popup)
        let lastError = null;
        for (let attempt = 0; attempt < 2; attempt++) {
            const mint = await requestMintTransaction(walletAddress, bugId, name, imageUri);

            if (mint.status === 409) {
                window._mintResult = JSON.stringify({
                    success: false,
                    alreadyMinted: true,
                    error: (mint.data && mint.data.error) || "NFT already minted for this bug",
                    nftAddress: mint.data && mint.data.nftAddress
                });
                return window._mintResult;
            }
            if (!mint.ok || !mint.data || !mint.data.success || !mint.data.transaction) {
                const err = (mint.data && mint.data.error) || ("API error " + mint.status);
                window._mintResult = JSON.stringify({ success: false, error: err });
                return window._mintResult;
            }

            const nftAddress = mint.data.nftAddress;
            try {
                const bytes = Uint8Array.from(atob(mint.data.transaction), function (c) {
                    return c.charCodeAt(0);
                });
                const tx = window.solanaWeb3.Transaction.from(bytes);

                console.log("Requesting wallet signature...");
                const signedTx = await provider.signTransaction(tx);

                console.log("Sending transaction...");
                const signature = await connection.sendRawTransaction(signedTx.serialize(), {
                    skipPreflight: false
                });

                await connection.confirmTransaction(
                    {
                        signature: signature,
                        blockhash: tx.recentBlockhash,
                        lastValidBlockHeight: mint.data.lastValidBlockHeight
                    },
                    'confirmed'
                );

                console.log("Transaction confirmed:", signature);
                window._mintResult = JSON.stringify({
                    success: true,
                    nftAddress: nftAddress,
                    transaction: signature,
                    solscanUrl: "https://solscan.io/tx/" + signature + "?cluster=devnet"
                });
                return window._mintResult;
            } catch (sendErr) {
                lastError = sendErr;
                const msg = (sendErr && sendErr.message) || String(sendErr);
                const expired = /block ?hash|expired|not found|blockheight/i.test(msg);
                if (expired && attempt === 0) {
                    console.warn("blockhash likely expired, re-requesting transaction once:", msg);
                    continue; // retry: fetch a fresh server-built tx with a new blockhash
                }
                throw sendErr;
            }
        }
        throw lastError || new Error("mint failed");
    } catch (error) {
        console.error("mintCampaignNFT error:", error);
        window._mintResult = JSON.stringify({
            success: false,
            error: (error && error.message) || "Failed to mint NFT"
        });
        return window._mintResult;
    }
}

window.mintCampaignNFT = mintCampaignNFT;

console.log("Wallet script loaded. API base:", apiBase());
