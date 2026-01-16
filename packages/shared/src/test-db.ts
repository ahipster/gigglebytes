import { db } from './index';

async function main() {
    console.log('Connecting to database...');
    try {
        const jurisdictions = await db.jurisdiction.findMany();
        console.log(`Successfully connected! Found ${jurisdictions.length} jurisdictions.`);
        if (jurisdictions.length === 0) {
            console.warn("WARNING: No jurisdictions found. Did seed data run?");
        } else {
            console.log("First jurisdiction:", jurisdictions[0].name);
        }
    } catch (error) {
        console.error('Error connecting to database:', error);
        process.exit(1);
    } finally {
        await db.$disconnect();
    }
}

main();
