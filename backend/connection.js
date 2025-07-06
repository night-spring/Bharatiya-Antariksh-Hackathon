const postgres = require( 'postgres' );
const dotenv = require('dotenv');
dotenv.config();

const connectionString = process.env.DATABASE_URL;

const sql = postgres(connectionString, {
  ssl: 'require',
});

async function checkConnection() {
  try {
    await sql`SELECT 1`;
    console.log('✅ Database connection successful');
  } catch (err) {
    console.error('❌ Database connection failed:', err);
  } 
}

checkConnection();

module.exports = sql;
