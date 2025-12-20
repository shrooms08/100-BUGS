
console.log("Wallet script starting...");
console.log("Location:", window.location.href);

// Program configuration
const PROGRAM_ID = "AuXF95nT7WS865AzQpuj3os9r6DjTYY9ekh4mGgG6gfL";
const CORE_PROGRAM_ID = "CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d";
const COLLECTION_ADDRESS = "3ZQPh5QRLuGfNhY3hbCC8e5AYiLEaWaFoYVxdvTpz9gi";
const RPC_URL = "https://api.devnet.solana.com";

// IDL will be loaded from API
let IDL = null;
let program = null;
let connection = null;

// Wait for page to fully load before checking wallets
window.addEventListener('DOMContentLoaded', function() {
    console.log("DOM loaded, checking for wallets...");
    setTimeout(checkWalletsOnLoad, 500); // Give extensions time to inject
});

function checkWalletsOnLoad() {
    console.log("Checking wallet extensions...");
    console.log("   window.solana:", typeof window.solana);
    console.log("   window.phantom:", typeof window.phantom);
    console.log("   window.solflare:", typeof window.solflare);
    
    if (window.solana) {
        console.log("    Phantom/Solana provider found!");
        console.log("   isPhantom:", window.solana.isPhantom);
    } else {
        console.log("    No Solana wallet extension detected");
        console.log("   Make sure Phantom extension is installed and enabled");
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
    const hasPhantom = window.solana && window.solana.isPhantom;
    console.log(" isPhantomInstalled:", hasPhantom);
    return hasPhantom;
}

function isSolflareInstalled() {
    const hasSolflare = window.solflare && window.solflare.isSolflare;
    console.log(" isSolflareInstalled:", hasSolflare);
    return hasSolflare;
}

function checkWallets() {
    const result = {
        phantom: isPhantomInstalled(),
        solflare: isSolflareInstalled()
    };
    console.log("📋 Available wallets:", JSON.stringify(result));
    return result;
}

// ============================================
// CONNECT FUNCTIONS
// ============================================

async function connectPhantom() {
    console.log(" connectPhantom() called");
    
    // Check if we're in a browser
    if (typeof window === 'undefined') {
        console.error(" Not running in browser");
        return JSON.stringify({
            success: false,
            error: "Not running in browser"
        });
    }
    
    // Check if Phantom is installed
    if (!window.solana) {
        console.error(" window.solana not found");
        console.log(" Tip: Make sure Phantom extension is installed and enabled for this site");
        return JSON.stringify({
            success: false,
            error: "Phantom wallet not detected. Please install Phantom extension from phantom.app"
        });
    }
    
    if (!window.solana.isPhantom) {
        console.error(" window.solana exists but is not Phantom");
        return JSON.stringify({
            success: false,
            error: "Solana wallet found but it's not Phantom"
        });
    }
    
    console.log(" Phantom detected, attempting connection...");
    
    try {
        // Request connection
        const resp = await window.solana.connect();
        const publicKey = resp.publicKey.toString();
        
        // Update global state
        window.walletState.connected = true;
        window.walletState.address = publicKey;
        window.walletState.provider = 'phantom';
        
        console.log(" Phantom connected successfully!");
        console.log(" Address:", publicKey);
        
        return JSON.stringify({
            success: true,
            address: publicKey,
            provider: 'phantom'
        });
        
    } catch (error) {
        console.error(" Phantom connection failed:", error);
        console.error("Error message:", error.message);
        console.error("Error code:", error.code);
        
        return JSON.stringify({
            success: false,
            error: error.message || "Connection failed or was cancelled"
        });
    }
}

async function connectSolflare() {
    console.log(" connectSolflare() called");
    
    if (!window.solflare) {
        console.error(" window.solflare not found");
        return JSON.stringify({
            success: false,
            error: "Solflare wallet not detected. Please install from solflare.com"
        });
    }
    
    if (!window.solflare.isSolflare) {
        console.error(" window.solflare exists but is not Solflare");
        return JSON.stringify({
            success: false,
            error: "Wallet found but it's not Solflare"
        });
    }
    
    console.log(" Solflare detected, attempting connection...");
    
    try {
        await window.solflare.connect();
        const publicKey = window.solflare.publicKey.toString();
        
        window.walletState.connected = true;
        window.walletState.address = publicKey;
        window.walletState.provider = 'solflare';
        
        console.log(" Solflare connected successfully!");
        console.log(" Address:", publicKey);
        
        return JSON.stringify({
            success: true,
            address: publicKey,
            provider: 'solflare'
        });
        
    } catch (error) {
        console.error(" Solflare connection failed:", error);
        
        return JSON.stringify({
            success: false,
            error: error.message || "Connection failed or was cancelled"
        });
    }
}

function disconnectWallet() {
    console.log("🔌 disconnectWallet() called");
    
    try {
        if (window.walletState.provider === 'phantom' && window.solana) {
            window.solana.disconnect();
            console.log(" Disconnected from Phantom");
        } else if (window.walletState.provider === 'solflare' && window.solflare) {
            window.solflare.disconnect();
            console.log(" Disconnected from Solflare");
        }
        
        window.walletState.connected = false;
        window.walletState.address = null;
        window.walletState.provider = null;
        
        return JSON.stringify({ success: true });
        
    } catch (error) {
        console.error(" Disconnect failed:", error);
        return JSON.stringify({
            success: false,
            error: error.message
        });
    }
}

function getWalletState() {
    console.log(" getWalletState() called");
    console.log("   State:", JSON.stringify(window.walletState));
    return JSON.stringify(window.walletState);
}

// ============================================
// DEBUG FUNCTION
// ============================================

function debugWallet() {
    console.log("\n========== WALLET DEBUG ==========");
    console.log("URL:", window.location.href);
    console.log("Protocol:", window.location.protocol);
    console.log("");
    console.log("window.solana:", window.solana);
    console.log("window.phantom:", window.phantom);
    console.log("window.solflare:", window.solflare);
    console.log("");
    
    if (window.solana) {
        console.log("solana.isPhantom:", window.solana.isPhantom);
        console.log("solana.isConnected:", window.solana.isConnected);
        console.log("solana.publicKey:", window.solana.publicKey?.toString());
    }
    
    console.log("");
    console.log("Wallet state:", window.walletState);
    console.log("");
    console.log("Functions available:");
    console.log("  window.connectPhantom:", typeof window.connectPhantom);
    console.log("  window.connectSolflare:", typeof window.connectSolflare);
    console.log("  window.disconnectWallet:", typeof window.disconnectWallet);
    console.log("  window.getWalletState:", typeof window.getWalletState);
    console.log("  window.checkWallets:", typeof window.checkWallets);
    console.log("===================================\n");
    
    return "Debug info printed to console";
}

// ============================================
// MAKE FUNCTIONS GLOBALLY ACCESSIBLE
// ============================================

window.connectPhantom = connectPhantom;
window.connectSolflare = connectSolflare;
window.disconnectWallet = disconnectWallet;
window.getWalletState = getWalletState;
window.checkWallets = checkWallets;
window.debugWallet = debugWallet;

// ============================================
// TRANSACTION BUILDING & SIGNING
// ============================================

async function loadIDL() {
    if (IDL) return IDL;
    
    try {
        // Try to load IDL from API
        const response = await fetch('http://localhost:3000/idl');
        if (response.ok) {
            IDL = await response.json();
            console.log(" IDL loaded from API");
            return IDL;
        }
    } catch (e) {
        console.log(" Could not load IDL from API, using fallback");
    }
    
    // Fallback: Return null and we'll build transactions manually
    return null;
}

async function initializeProgram(walletAddress) {
    if (program && connection) return { program, connection };
    
    // Initialize connection
    if (!connection) {
        connection = new window.solanaWeb3.Connection(RPC_URL, 'confirmed');
    }
    
    // Get wallet provider
    let provider = null;
    if (window.walletState.provider === 'phantom' && window.solana) {
        provider = window.solana;
    } else if (window.walletState.provider === 'solflare' && window.solflare) {
        provider = window.solflare;
    } else {
        throw new Error("No wallet provider available");
    }
    
    // Load IDL
    const idl = await loadIDL();
    
    if (idl && window.anchor) {
        // Use Anchor if available
        const programId = new window.solanaWeb3.PublicKey(PROGRAM_ID);
        const anchorProvider = new window.anchor.AnchorProvider(
            connection,
            {
                publicKey: new window.solanaWeb3.PublicKey(walletAddress),
                signTransaction: async (tx) => {
                    return await provider.signTransaction(tx);
                },
                signAllTransactions: async (txs) => {
                    return await provider.signAllTransactions(txs);
                }
            },
            { commitment: 'confirmed' }
        );
        
        program = new window.anchor.Program(idl, anchorProvider);
        console.log(" Anchor program initialized");
    } else {
        console.log(" Anchor not available, will use manual transaction building");
    }
    
    return { program, connection };
}

async function buildAndSignTransaction(walletAddress, instructions, assetKeypairArray, bugId, name, imageUri) {
    try {
        console.log(" Building transaction...");
        
        const { connection } = await initializeProgram(walletAddress);
        
        // Get wallet provider
        let provider = null;
        if (window.walletState.provider === 'phantom' && window.solana) {
            provider = window.solana;
        } else if (window.walletState.provider === 'solflare' && window.solflare) {
            provider = window.solflare;
        } else {
            throw new Error("No wallet provider available");
        }
        
        const playerPubkey = new window.solanaWeb3.PublicKey(walletAddress);
        const programId = new window.solanaWeb3.PublicKey(PROGRAM_ID);
        const coreProgramId = new window.solanaWeb3.PublicKey(CORE_PROGRAM_ID);
        const collectionPubkey = new window.solanaWeb3.PublicKey(COLLECTION_ADDRESS);
        
        // Create asset keypair from secret key
        const assetKeypair = window.solanaWeb3.Keypair.fromSecretKey(
            new Uint8Array(assetKeypairArray)
        );
        
        // Build transaction
        const transaction = new window.solanaWeb3.Transaction();
        
        // Process each instruction
        for (const instruction of instructions) {
            let ix = null;
            
            if (instruction.type === 'start_campaign') {
                // Build start_campaign instruction manually
                const campaignId = instruction.args.campaign_id;
                const bugId = instruction.args.bug_id;
                
                const [campaignPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [Buffer.from('campaign'), Buffer.from([campaignId])],
                    programId
                );
                
                const [completionPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [
                        Buffer.from('completion'),
                        Buffer.from([campaignId]),
                        playerPubkey.toBuffer(),
                        Buffer.from([bugId])
                    ],
                    programId
                );
                
                // Instruction discriminator for start_campaign: [229, 59, 6, 209, 253, 163, 39, 124]
                const discriminator = Buffer.from([229, 59, 6, 209, 253, 163, 39, 124]);
                const args = Buffer.concat([
                    Buffer.from([campaignId]),
                    Buffer.from([bugId])
                ]);
                
                ix = new window.solanaWeb3.TransactionInstruction({
                    programId: programId,
                    keys: [
                        { pubkey: playerPubkey, isSigner: true, isWritable: true },
                        { pubkey: completionPda, isSigner: false, isWritable: true },
                        { pubkey: campaignPda, isSigner: false, isWritable: true },
                        { pubkey: window.solanaWeb3.SystemProgram.programId, isSigner: false, isWritable: false }
                    ],
                    data: Buffer.concat([discriminator, args])
                });
                
            } else if (instruction.type === 'record_campaign_completion') {
                // Build record_campaign_completion instruction
                const campaignId = instruction.args.campaign_id;
                const bugId = instruction.args.bug_id;
                
                const [campaignPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [Buffer.from('campaign'), Buffer.from([campaignId])],
                    programId
                );
                
                const [completionPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [
                        Buffer.from('completion'),
                        Buffer.from([campaignId]),
                        playerPubkey.toBuffer(),
                        Buffer.from([bugId])
                    ],
                    programId
                );
                
                const [progressPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [
                        Buffer.from('progress'),
                        Buffer.from([campaignId]),
                        playerPubkey.toBuffer()
                    ],
                    programId
                );
                
                // Instruction discriminator: [152, 123, 124, 51, 143, 145, 181, 179]
                const discriminator = Buffer.from([152, 123, 124, 51, 143, 145, 181, 179]);
                const args = Buffer.concat([
                    Buffer.from([campaignId]),
                    Buffer.from([bugId])
                ]);
                
                ix = new window.solanaWeb3.TransactionInstruction({
                    programId: programId,
                    keys: [
                        { pubkey: playerPubkey, isSigner: true, isWritable: true },
                        { pubkey: completionPda, isSigner: false, isWritable: true },
                        { pubkey: progressPda, isSigner: false, isWritable: true },
                        { pubkey: campaignPda, isSigner: false, isWritable: true },
                        { pubkey: window.solanaWeb3.SystemProgram.programId, isSigner: false, isWritable: false }
                    ],
                    data: Buffer.concat([discriminator, args])
                });
                
            } else if (instruction.type === 'mint_nft') {
                // Build mint_nft instruction
                const campaignId = instruction.args.campaign_id;
                const bugId = instruction.args.bug_id;
                
                const [collectionAuthorityPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [Buffer.from('collection'), collectionPubkey.toBuffer()],
                    programId
                );
                
                const [completionPda] = window.solanaWeb3.PublicKey.findProgramAddressSync(
                    [
                        Buffer.from('completion'),
                        Buffer.from([campaignId]),
                        playerPubkey.toBuffer(),
                        Buffer.from([bugId])
                    ],
                    programId
                );
                
                // Instruction discriminator: [211, 57, 6, 167, 15, 219, 35, 251]
                const discriminator = Buffer.from([211, 57, 6, 167, 15, 219, 35, 251]);
                
                // Encode args: campaign_id (u8), bug_id (u8), name (string), nft_uri (string)
                const nameBuffer = Buffer.from(instruction.args.name, 'utf8');
                const uriBuffer = Buffer.from(instruction.args.nft_uri || '', 'utf8');
                
                // String encoding: 4 bytes length + data
                const nameLength = Buffer.allocUnsafe(4);
                nameLength.writeUInt32LE(nameBuffer.length, 0);
                
                const uriLength = Buffer.allocUnsafe(4);
                uriLength.writeUInt32LE(uriBuffer.length, 0);
                
                const args = Buffer.concat([
                    Buffer.from([campaignId]),
                    Buffer.from([bugId]),
                    nameLength,
                    nameBuffer,
                    uriLength,
                    uriBuffer
                ]);
                
                ix = new window.solanaWeb3.TransactionInstruction({
                    programId: programId,
                    keys: [
                        { pubkey: playerPubkey, isSigner: true, isWritable: true },
                        { pubkey: assetKeypair.publicKey, isSigner: true, isWritable: true },
                        { pubkey: collectionPubkey, isSigner: false, isWritable: true },
                        { pubkey: collectionAuthorityPda, isSigner: false, isWritable: false },
                        { pubkey: completionPda, isSigner: false, isWritable: true },
                        { pubkey: coreProgramId, isSigner: false, isWritable: false },
                        { pubkey: window.solanaWeb3.SystemProgram.programId, isSigner: false, isWritable: false }
                    ],
                    data: Buffer.concat([discriminator, args])
                });
            }
            
            if (ix) {
                transaction.add(ix);
            }
        }
        
        // Get recent blockhash
        const { blockhash } = await connection.getLatestBlockhash('confirmed');
        transaction.recentBlockhash = blockhash;
        transaction.feePayer = playerPubkey;
        
        // Sign with asset keypair (for NFT mint)
        transaction.sign(assetKeypair);
        
        // Sign with wallet
        console.log(" Requesting wallet signature...");
        const signedTx = await provider.signTransaction(transaction);
        
        // Send transaction
        console.log(" Sending transaction to blockchain...");
        const signature = await connection.sendRawTransaction(signedTx.serialize(), {
            skipPreflight: false,
            maxRetries: 3
        });
        
        console.log(" Transaction sent! Signature:", signature);
        console.log(" Waiting for confirmation...");
        
        // Wait for confirmation
        await connection.confirmTransaction(signature, 'confirmed');
        
        console.log(" Transaction confirmed!");
        
        return {
            success: true,
            signature: signature
        };
        
    } catch (error) {
        console.error(" Transaction error:", error);
        return {
            success: false,
            error: error.message || "Transaction failed"
        };
    }
}

// ============================================
// NFT MINTING FUNCTIONS
// ============================================

async function mintCampaignNFT(bugId, name, imageUri, walletAddress) {
    console.log(" mintCampaignNFT() called");
    console.log("   Bug ID:", bugId);
    console.log("   Name:", name);
    console.log("   Wallet:", walletAddress);
    
    // Initialize result storage
    window._mintResult = null;
    
    if (!window.walletState.connected || !window.walletState.address) {
        console.error(" Wallet not connected!");
        window._mintResult = JSON.stringify({
            success: false,
            error: "Wallet not connected"
        });
        return window._mintResult;
    }
    
    if (walletAddress !== window.walletState.address) {
        console.error(" Wallet address mismatch!");
        window._mintResult = JSON.stringify({
            success: false,
            error: "Wallet address mismatch"
        });
        return window._mintResult;
    }
    
    try {
        // Call API to get transaction instructions
        const apiUrl = "http://localhost:3000/mint-campaign-nft";
        console.log(" Calling API:", apiUrl);
        
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                wallet: walletAddress,
                bugId: bugId,
                name: name,
                imageUri: imageUri || "",
                campaignId: 1
            })
        });
        
        const data = await response.json();
        console.log(" API response:", data);
        
        if (!data.success) {
            console.error(" API error:", data.error);
            window._mintResult = JSON.stringify({
                success: false,
                error: data.error || "API request failed"
            });
            return window._mintResult;
        }
        
        // If demo mode, return success immediately
        if (data.mode === 'demo') {
            console.log(" Demo mode - NFT minted (mock)");
            window._mintResult = JSON.stringify({
                success: true,
                nftAddress: data.nftAddress,
                transaction: data.transaction,
                mode: 'demo'
            });
            return window._mintResult;
        }
        
        // Real blockchain mode - need to sign and send
        console.log(" Real blockchain mode - building and signing transaction...");
        console.log("   Instructions:", data.instructions.length);
        console.log("   NFT Address:", data.nftAddress);
        
        // Build and sign transaction
        const txResult = await buildAndSignTransaction(
            walletAddress,
            data.instructions,
            data.assetKeypair,
            bugId,
            name,
            imageUri
        );
        
        if (txResult.success) {
            window._mintResult = JSON.stringify({
                success: true,
                nftAddress: data.nftAddress,
                transaction: txResult.signature,
                solscanUrl: `https://solscan.io/tx/${txResult.signature}?cluster=devnet`,
                mode: 'real'
            });
        } else {
            window._mintResult = JSON.stringify({
                success: false,
                error: txResult.error || "Transaction failed"
            });
        }
        
        return window._mintResult;
        
    } catch (error) {
        console.error(" mintCampaignNFT error:", error);
        window._mintResult = JSON.stringify({
            success: false,
            error: error.message || "Failed to mint NFT"
        });
        return window._mintResult;
    }
}

// Make minting function globally accessible
window.mintCampaignNFT = mintCampaignNFT;

console.log(" Wallet script loaded successfully!");
console.log(" Available functions:");
console.log("   window.connectPhantom()");
console.log("   window.connectSolflare()");
console.log("   window.disconnectWallet()");
console.log("   window.getWalletState()");
console.log("   window.checkWallets()");
console.log("   window.debugWallet()");
console.log("   window.mintCampaignNFT()");
console.log("");
console.log("🔧 Run window.debugWallet() for full diagnostics");