import run from '../src/tests/feedData.js';

const main = async () => {
    try {
        await run();
    } catch (err) {
        console.error(`Error: ${err.message}`);
        process.exitCode = 1;
    } finally {
        console.log('🌱 Database feed completed.');
    }
}

main()
  .catch(err => {
    console.error(`Error: ${err.message}`);
    process.exitCode = 1;
  })