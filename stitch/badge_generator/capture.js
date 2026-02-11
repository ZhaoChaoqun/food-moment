/**
 * FoodMoment Badge Generator - Puppeteer Capture Script
 *
 * Captures each badge from badges.html as transparent PNG at @2x and @3x resolutions.
 * Output: ../../FoodMoment/Resources/Assets.xcassets/Badges/<badge_id>.imageset/
 *
 * Usage:
 *   cd stitch/badge_generator
 *   npm install puppeteer
 *   node capture.js
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

// Badge IDs matching data-badge-id in badges.html
const BADGE_IDS = [
    'first_glimpse',
    'weekly_streak',
    'perfect_loop',
    'protein_hunter',
    'forest_walker',
    'rainbow_diet',
    'sugar_controller',
    'midnight_diner',
    'early_bird',
    'food_encyclopedia',
    'cheat_day',
    'caffeine_fix',
    // Locked states
    'locked_normal',
    'locked_hidden',
];

// Output base directory
const ASSETS_DIR = path.resolve(__dirname, '../../FoodMoment/Resources/Assets.xcassets/Badges');

// Scale factors
const SCALES = [
    { suffix: '@2x', scale: 2 },  // 160x160
    { suffix: '@3x', scale: 3 },  // 240x240
];

const BADGE_SIZE = 80; // Base size in CSS pixels

/**
 * Generate Contents.json for an Xcode imageset
 */
function generateContentsJson(badgeId) {
    return JSON.stringify({
        images: [
            {
                filename: `badge_${badgeId}@2x.png`,
                idiom: 'universal',
                scale: '2x',
            },
            {
                filename: `badge_${badgeId}@3x.png`,
                idiom: 'universal',
                scale: '3x',
            },
        ],
        info: {
            author: 'badge_generator',
            version: 1,
        },
        properties: {
            'preserves-vector-representation': false,
            'template-rendering-intent': 'original',
        },
    }, null, 2);
}

/**
 * Generate Contents.json for the Badges folder
 */
function generateFolderContentsJson() {
    return JSON.stringify({
        info: {
            author: 'badge_generator',
            version: 1,
        },
        properties: {
            'provides-namespace': true,
        },
    }, null, 2);
}

async function main() {
    console.log('🎨 FoodMoment Badge Generator');
    console.log('============================\n');

    // Ensure output directory exists
    if (!fs.existsSync(ASSETS_DIR)) {
        fs.mkdirSync(ASSETS_DIR, { recursive: true });
        console.log(`📁 Created: ${ASSETS_DIR}`);
    }

    // Write folder Contents.json
    const folderContentsPath = path.join(ASSETS_DIR, 'Contents.json');
    fs.writeFileSync(folderContentsPath, generateFolderContentsJson());

    // Launch browser
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    const page = await browser.newPage();

    // Load the badges HTML file
    const htmlPath = path.resolve(__dirname, 'badges.html');
    const htmlUrl = `file://${htmlPath}`;
    await page.goto(htmlUrl, { waitUntil: 'networkidle0', timeout: 30000 });

    // Wait for Material Symbols font to load
    await page.evaluate(() => document.fonts.ready);
    // Extra delay for font rendering
    await new Promise(r => setTimeout(r, 2000));

    console.log('✅ Page loaded, fonts ready\n');

    let captured = 0;
    let failed = 0;

    for (const badgeId of BADGE_IDS) {
        const imagesetDir = path.join(ASSETS_DIR, `badge_${badgeId}.imageset`);

        // Create imageset directory
        if (!fs.existsSync(imagesetDir)) {
            fs.mkdirSync(imagesetDir, { recursive: true });
        }

        // Write Contents.json
        fs.writeFileSync(
            path.join(imagesetDir, 'Contents.json'),
            generateContentsJson(badgeId)
        );

        // Find the badge element
        const selector = `[data-badge-id="${badgeId}"]`;
        const element = await page.$(selector);

        if (!element) {
            console.log(`❌ Badge not found: ${badgeId}`);
            failed++;
            continue;
        }

        // Capture at each scale
        for (const { suffix, scale } of SCALES) {
            const filename = `badge_${badgeId}${suffix}.png`;
            const outputPath = path.join(imagesetDir, filename);

            // Set device scale factor for high-res capture
            await page.setViewport({
                width: 1200,
                height: 2000,
                deviceScaleFactor: scale,
            });

            // Re-navigate to apply scale (viewport change may require it)
            // Actually, just setting viewport is enough for screenshot

            // Get bounding box
            const box = await element.boundingBox();
            if (!box) {
                console.log(`  ⚠️  No bounding box for ${badgeId} at ${suffix}`);
                continue;
            }

            // Capture with transparent background
            await element.screenshot({
                path: outputPath,
                omitBackground: true,
            });

            const stats = fs.statSync(outputPath);
            const sizeKb = (stats.size / 1024).toFixed(1);
            console.log(`  ✅ ${filename} (${sizeKb} KB)`);
        }

        captured++;
    }

    await browser.close();

    console.log(`\n============================`);
    console.log(`📊 Results: ${captured} captured, ${failed} failed`);
    console.log(`📁 Output: ${ASSETS_DIR}`);
    console.log('🎉 Done!');
}

main().catch(console.error);
