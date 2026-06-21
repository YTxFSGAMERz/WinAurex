import { chromium } from 'playwright-extra';
import stealthPlugin from 'puppeteer-extra-plugin-stealth';
import { createCursor } from 'ghost-cursor';

chromium.use(stealthPlugin());

const TARGET_DOMAIN = 'winaurex.vercel.app';
const HIGH_VALUE_PATHS = ['/os_builder/', '/tweaks/', '/activators/'];
const SEARCH_QUERIES = [
    'WinAurex',
    'WinAurex',
    'WinAurex OS Builder free',
    'Windows 11 debloater WinAurex'
];

/**
 * Fetch a list of working elite proxies from ProxyScrape
 */
async function fetchProxies() {
    console.log('[+] Fetching elite proxies...');
    try {
        // Fetch HTTP/S elite anonymity proxies that support SSL
        const url = 'https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=yes&anonymity=elite';
        
        // Dynamically import node-fetch as it is an ESM module
        const { default: fetch } = await import('node-fetch');
        const response = await fetch(url);
        const data = await response.text();
        
        const proxies = data.split('\r\n').filter(p => p.trim() !== '');
        console.log(`[+] Found ${proxies.length} proxies.`);
        return proxies;
    } catch (e) {
        console.error('[-] Failed to fetch proxies:', e);
        return [];
    }
}

/**
 * Utility to sleep for a random time between min and max ms
 */
function randomSleep(min, max) {
    const ms = Math.floor(Math.random() * (max - min + 1)) + min;
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Main Journey Function
 */
async function runSession(proxyStr) {
    console.log(`\n======================================`);
    console.log(`[*] Starting session with proxy: ${proxyStr}`);
    
    // We launch with no specific executable path, relying on the installed playwright browser
    let browser;
    try {
        browser = await chromium.launch({
            headless: true, // Run headless in CI
            args: [
                `--proxy-server=${proxyStr}`,
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-blink-features=AutomationControlled',
            ]
        });

        // Randomize viewport size
        const widths = [1280, 1366, 1440, 1920];
        const heights = [720, 768, 900, 1080];
        const width = widths[Math.floor(Math.random() * widths.length)];
        const height = heights[Math.floor(Math.random() * heights.length)];

        const context = await browser.newContext({
            viewport: { width, height },
            locale: 'en-US',
            timezoneId: 'America/New_York', // In a real scenario, this should match proxy location, but NY is fine for spoofing.
        });

        const page = await context.newPage();
        const cursor = createCursor(page);

        // ---------------------------------------------------------
        // 1. Organic Search Simulation (DuckDuckGo for less captchas)
        // ---------------------------------------------------------
        console.log(`[*] Navigating to search engine...`);
        try {
            await page.goto('https://duckduckgo.com', { waitUntil: 'domcontentloaded', timeout: 20000 });
            await randomSleep(2000, 4000);
            
            const query = SEARCH_QUERIES[Math.floor(Math.random() * SEARCH_QUERIES.length)];
            console.log(`[*] Searching for: "${query}"`);
            
            await cursor.click('#searchbox_input');
            await page.keyboard.type(query, { delay: 150 });
            await randomSleep(500, 1500);
            await page.keyboard.press('Enter');
            
            await page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 20000 });
            await randomSleep(3000, 5000);
            
            // Scroll a bit
        } catch (e) {
            console.warn(`[-] Search engine step failed or timed out. Error: ${e.message}`);
            // If the proxy fails to load or times out on the search engine, it's dead/too slow.
            // Abort immediately instead of wasting time trying the target domain.
            throw new Error(`Proxy is dead or too slow during search. Aborting session. (${e.message})`);
        }

        // ---------------------------------------------------------
        // 2. Navigate to WinAurex Target
        // ---------------------------------------------------------
        console.log(`[*] Navigating to https://${TARGET_DOMAIN}...`);
        await page.goto(`https://${TARGET_DOMAIN}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
        
        console.log(`[+] Reached homepage. Simulating reading...`);
        // Simulate reading: scroll down, pause, scroll up
        await cursor.move({ x: width/2, y: height/2 });
        await randomSleep(2000, 5000);
        await page.mouse.wheel(0, 500);
        await randomSleep(3000, 6000);
        await page.mouse.wheel(0, -200);
        await randomSleep(2000, 4000);

        // ---------------------------------------------------------
        // 3. High Value Page Interaction
        // ---------------------------------------------------------
        const numPages = Math.floor(Math.random() * 2) + 2; // Visit 2 or 3 pages
        console.log(`[*] Will visit ${numPages} internal pages.`);

        for (let i = 0; i < numPages; i++) {
            // Pick a random high value path
            const targetPath = HIGH_VALUE_PATHS[Math.floor(Math.random() * HIGH_VALUE_PATHS.length)];
            
            // Look for a link containing this path
            const linkElements = await page.$$(`a[href*="${targetPath}"]`);
            
            if (linkElements.length > 0) {
                // Click the first matching link organically
                console.log(`[*] Clicking link to: ${targetPath}`);
                await cursor.click(linkElements[0]);
                await page.waitForLoadState('domcontentloaded', { timeout: 30000 });
                
                console.log(`[+] Page loaded. Simulating reading...`);
                await randomSleep(4000, 8000);
                await page.mouse.wheel(0, 800);
                await randomSleep(3000, 7000);
                await page.mouse.wheel(0, -400);
                await randomSleep(2000, 5000);
            } else {
                console.log(`[-] Could not find link for ${targetPath} on current page.`);
                break;
            }
        }

        console.log(`[+] Session complete.`);
        return true;
    } catch (err) {
        console.error(`[-] Session failed (proxy might be dead): ${err.message}`);
        return false;
    } finally {
        if (browser) {
            await browser.close();
            console.log(`[*] Browser closed.`);
        }
    }
}

/**
 * Orchestrator
 */
(async () => {
    console.log('--- WINAUREX TRAFFIC SIMULATOR ---');
    
    const proxies = await fetchProxies();
    
    if (proxies.length === 0) {
        console.error('[-] No proxies available. Exiting.');
        process.exit(1);
    }

    // We want 2 successful sessions per run
    const TARGET_SUCCESSFUL_SESSIONS = 2;
    const MAX_ATTEMPTS = 50;
    let successfulSessions = 0;
    
    for (let i = 0; i < MAX_ATTEMPTS; i++) {
        if (successfulSessions >= TARGET_SUCCESSFUL_SESSIONS) {
            break;
        }

        // Grab a random proxy
        const proxy = proxies[Math.floor(Math.random() * proxies.length)];
        
        const success = await runSession(proxy);
        
        if (success) {
            successfulSessions++;
        }
        
        if (successfulSessions < TARGET_SUCCESSFUL_SESSIONS) {
            console.log(`[*] Waiting before next session attempt...`);
            await randomSleep(3000, 7000); 
        }
    }
    
    console.log(`\n[+] Finished with ${successfulSessions}/${TARGET_SUCCESSFUL_SESSIONS} successful sessions.`);
    process.exit(0);
})();
