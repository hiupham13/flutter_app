// Load environment variables from .env file
require('dotenv').config();

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  file: 'foods (1).json',
  dryRun: false,
};

// Parse options
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--file' && args[i + 1]) {
    options.file = args[i + 1];
    i++;
  } else if (args[i] === '--dry-run') {
    options.dryRun = true;
  } else if (args[i] === '--help' || args[i] === '-h') {
    console.log(`
Firestore Import Script

Usage:
  node import-to-firestore.js [options]

Options:
  --file <path>    Path to JSON file (default: foods (1).json)
  --dry-run        Preview only, không upload thật
  --help, -h       Hiển thị hướng dẫn này

Environment Variables:
  FIREBASE_PROJECT_ID         Firebase project ID
  FIREBASE_CLIENT_EMAIL       Service account email
  FIREBASE_PRIVATE_KEY        Service account private key
  FIREBASE_SERVICE_ACCOUNT    Path to service account JSON file (alternative)

Example:
  node import-to-firestore.js
  node import-to-firestore.js --file custom-foods.json
  node import-to-firestore.js --dry-run
    `);
    process.exit(0);
  }
}

// Initialize Firebase Admin
function initializeFirebase() {
  try {
    // Option 1: Use service account file
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = require(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase initialized from service account file');
      return;
    }

    // Option 2: Use environment variables
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('✅ Firebase initialized from environment variables');
      return;
    }

    throw new Error('Firebase credentials not found');
  } catch (error) {
    console.error('❌ Lỗi khởi tạo Firebase:', error.message);
    console.log('\nCách 1: Set environment variables trong .env:');
    console.log('  FIREBASE_PROJECT_ID=your-project-id');
    console.log('  FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com');
    console.log('  FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"');
    console.log('\nCách 2: Set path to service account JSON:');
    console.log('  FIREBASE_SERVICE_ACCOUNT=./path/to/serviceAccountKey.json');
    process.exit(1);
  }
}

// Read and parse JSON file
function readFoodsFile(filePath) {
  const fullPath = path.resolve(filePath);
  
  if (!fs.existsSync(fullPath)) {
    console.error(`❌ Lỗi: File không tồn tại: ${fullPath}`);
    process.exit(1);
  }

  try {
    const content = fs.readFileSync(fullPath, 'utf8');
    const foods = JSON.parse(content);
    
    if (!Array.isArray(foods)) {
      throw new Error('JSON file must contain an array of food objects');
    }

    console.log(`✅ Đọc thành công ${foods.length} món ăn từ file: ${filePath}`);
    return foods;
  } catch (error) {
    console.error(`❌ Lỗi đọc file JSON: ${error.message}`);
    process.exit(1);
  }
}

// Map JSON food item to Firestore format
function mapToFirestore(foodItem) {
  const now = admin.firestore.Timestamp.now();
  
  // Convert context_scores object to Map format
  const contextScores = foodItem.context_scores || {};
  
  return {
    id: foodItem.id,
    name: foodItem.name,
    search_keywords: foodItem.search_keywords || [],
    description: foodItem.description || '',
    images: foodItem.images || [],
    cuisine_id: foodItem.cuisine_id,
    meal_type_id: foodItem.meal_type_id,
    flavor_profile: foodItem.flavor_profile || [],
    allergen_tags: foodItem.allergen_tags || [],
    price_segment: foodItem.price_segment || 2,
    avg_calories: foodItem.avg_calories || null,
    available_times: foodItem.available_times || [],
    context_scores: contextScores,
    map_query: foodItem.map_query || '',
    is_active: foodItem.is_active !== undefined ? foodItem.is_active : true,
    created_at: now,
    updated_at: now,
    view_count: 0,
    pick_count: 0,
  };
}

// Validate food item structure
function validateFoodItem(foodItem, index) {
  const requiredFields = ['id', 'name', 'cuisine_id', 'meal_type_id'];
  const missingFields = requiredFields.filter(field => !foodItem[field]);
  
  if (missingFields.length > 0) {
    throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
  }

  if (typeof foodItem.price_segment !== 'number' || foodItem.price_segment < 1 || foodItem.price_segment > 4) {
    throw new Error(`Invalid price_segment: ${foodItem.price_segment} (must be 1-4)`);
  }

  return true;
}

// Check if document exists
async function documentExists(firestore, collectionName, docId) {
  try {
    const doc = await firestore.collection(collectionName).doc(docId).get();
    return doc.exists;
  } catch (error) {
    throw new Error(`Error checking document existence: ${error.message}`);
  }
}

// Upload single food document
async function uploadFood(firestore, collectionName, foodData, dryRun) {
  const docId = foodData.id;
  
  if (dryRun) {
    console.log(`  [DRY RUN] Would upload: ${docId}`);
    return { success: true, skipped: false, dryRun: true };
  }

  try {
    // Check if document already exists
    const exists = await documentExists(firestore, collectionName, docId);
    
    if (exists) {
      return { success: true, skipped: true, reason: 'Document already exists' };
    }

    // Upload new document
    await firestore.collection(collectionName).doc(docId).set(foodData);
    return { success: true, skipped: false };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Main function
async function main() {
  console.log('🚀 Bắt đầu import dữ liệu vào Firestore...\n');
  
  // Initialize Firebase
  if (!options.dryRun) {
    initializeFirebase();
  } else {
    console.log('⚠️  DRY RUN mode - không upload thật\n');
  }

  // Read JSON file
  const foods = readFoodsFile(options.file);
  
  if (foods.length === 0) {
    console.log('⚠️  Không có dữ liệu để import');
    process.exit(0);
  }

  const firestore = options.dryRun ? null : admin.firestore();
  const collectionName = 'foods';

  console.log(`📊 Tổng số món ăn: ${foods.length}`);
  console.log(`📂 Collection: ${collectionName}`);
  console.log(`🔄 Mode: ${options.dryRun ? 'DRY RUN (preview only)' : 'LIVE (will upload)'}\n`);

  // Validate and map foods
  const mappedFoods = [];
  const validationErrors = [];

  console.log('⏳ Đang validate và map dữ liệu...\n');

  for (let i = 0; i < foods.length; i++) {
    const food = foods[i];
    try {
      validateFoodItem(food, i);
      const mapped = mapToFirestore(food);
      mappedFoods.push(mapped);
    } catch (error) {
      validationErrors.push({
        index: i,
        id: food.id || 'unknown',
        error: error.message,
      });
    }
  }

  if (validationErrors.length > 0) {
    console.log(`❌ Có ${validationErrors.length} lỗi validation:\n`);
    validationErrors.forEach(err => {
      console.log(`  - Index ${err.index} (ID: ${err.id}): ${err.error}`);
    });
    console.log('');
  }

  if (mappedFoods.length === 0) {
    console.log('❌ Không có dữ liệu hợp lệ để import');
    process.exit(1);
  }

  console.log(`✅ ${mappedFoods.length} món ăn hợp lệ\n`);

  // Upload foods
  const results = {
    success: [],
    skipped: [],
    failed: [],
  };

  console.log('⏳ Đang upload...\n');

  for (let i = 0; i < mappedFoods.length; i++) {
    const food = mappedFoods[i];
    const progress = `[${i + 1}/${mappedFoods.length}]`;
    
    process.stdout.write(`${progress} ${food.id}... `);
    
    const result = await uploadFood(firestore, collectionName, food, options.dryRun);
    
    if (result.success) {
      if (result.skipped) {
        results.skipped.push({ id: food.id, reason: result.reason });
        console.log('⏭️  (skipped)');
      } else if (result.dryRun) {
        results.success.push({ id: food.id });
        console.log('✅ (dry run)');
      } else {
        results.success.push({ id: food.id });
        console.log('✅');
      }
    } else {
      results.failed.push({ id: food.id, error: result.error });
      console.log('❌');
      console.log(`   Error: ${result.error}`);
    }
  }

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 Kết quả:\n');
  console.log(`✅ Thành công: ${results.success.length}`);
  console.log(`⏭️  Đã bỏ qua (đã tồn tại): ${results.skipped.length}`);
  console.log(`❌ Thất bại: ${results.failed.length}`);
  
  if (validationErrors.length > 0) {
    console.log(`⚠️  Lỗi validation: ${validationErrors.length}`);
  }

  if (options.dryRun) {
    console.log('\n⚠️  DRY RUN mode - không có dữ liệu nào được upload thật');
  }

  if (results.success.length > 0 && !options.dryRun) {
    console.log('\n✅ Documents đã upload thành công:');
    results.success.slice(0, 10).forEach(item => {
      console.log(`  - ${item.id}`);
    });
    if (results.success.length > 10) {
      console.log(`  ... và ${results.success.length - 10} documents khác`);
    }
  }

  if (results.skipped.length > 0) {
    console.log('\n⏭️  Documents đã bỏ qua (đã tồn tại):');
    results.skipped.slice(0, 10).forEach(item => {
      console.log(`  - ${item.id}`);
    });
    if (results.skipped.length > 10) {
      console.log(`  ... và ${results.skipped.length - 10} documents khác`);
    }
  }

  if (results.failed.length > 0) {
    console.log('\n❌ Documents upload thất bại:');
    results.failed.forEach(item => {
      console.log(`  - ${item.id}: ${item.error}`);
    });
  }

  console.log('\n' + '='.repeat(60));
  console.log('\n✨ Hoàn thành!');
  
  if (!options.dryRun && results.failed.length === 0) {
    process.exit(0);
  } else if (results.failed.length > 0) {
    process.exit(1);
  }
}

// Run
main().catch((error) => {
  console.error('❌ Lỗi:', error);
  process.exit(1);
});

