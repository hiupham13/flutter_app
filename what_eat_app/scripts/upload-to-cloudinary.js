// Load environment variables from .env file
require('dotenv').config();

const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const path = require('path');

// Cấu hình Cloudinary
// Lấy từ environment variables hoặc thay đổi trực tiếp
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY ,
  api_secret: process.env.CLOUDINARY_API_SECRET ,
});

// Parse command line arguments
const args = process.argv.slice(2);
const folderPath = args[0];
const options = {
  folder: 'foods',
  overwrite: false,
  extensions: ['.jpg', '.jpeg', '.png', '.webp'],
};

// Parse options
for (let i = 1; i < args.length; i++) {
  if (args[i] === '--folder' && args[i + 1]) {
    options.folder = args[i + 1];
    i++;
  } else if (args[i] === '--overwrite') {
    options.overwrite = true;
  } else if (args[i] === '--help' || args[i] === '-h') {
    console.log(`
Cloudinary Batch Upload Script

Usage:
  node upload-to-cloudinary.js <folder-path> [options]

Arguments:
  <folder-path>    Đường dẫn đến folder chứa ảnh cần upload

Options:
  --folder <name>  Folder trên Cloudinary (mặc định: foods)
  --overwrite      Cho phép ghi đè file đã tồn tại
  --help, -h       Hiển thị hướng dẫn này

Environment Variables:
  CLOUDINARY_CLOUD_NAME    Cloud name (mặc định: dinrpqxne)
  CLOUDINARY_API_KEY       API Key
  CLOUDINARY_API_SECRET    API Secret

Example:
  node upload-to-cloudinary.js ./images
  node upload-to-cloudinary.js ./images --folder foods --overwrite

Lưu ý:
  - Tên file sẽ được dùng làm Public ID (bỏ extension)
  - Ví dụ: pho-bo.jpg → Public ID: foods/pho-bo (có folder prefix)
  - Public ID trong URL sẽ có folder prefix: foods/pho-bo.jpg
  - File sẽ được upload vào folder "${options.folder}" trên Cloudinary
    `);
    process.exit(0);
  }
}

// Validate arguments
if (!folderPath) {
  console.error('❌ Lỗi: Chưa chỉ định folder path');
  console.log('Sử dụng: node upload-to-cloudinary.js <folder-path> [options]');
  console.log('Xem thêm: node upload-to-cloudinary.js --help');
  process.exit(1);
}

// Validate Cloudinary config
if (!cloudinary.config().api_key || !cloudinary.config().api_secret) {
  console.error('❌ Lỗi: Chưa cấu hình Cloudinary API credentials');
  console.log('Cách 1: Set environment variables:');
  console.log('  export CLOUDINARY_API_KEY=your_api_key');
  console.log('  export CLOUDINARY_API_SECRET=your_api_secret');
  console.log('');
  console.log('Cách 2: Sửa trực tiếp trong file script');
  process.exit(1);
}

// Get all image files from folder
function getImageFiles(dir) {
  const files = [];
  
  if (!fs.existsSync(dir)) {
    console.error(`❌ Lỗi: Folder không tồn tại: ${dir}`);
    process.exit(1);
  }
  
  const items = fs.readdirSync(dir);
  
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    
    if (stat.isFile()) {
      const ext = path.extname(item).toLowerCase();
      if (options.extensions.includes(ext)) {
        files.push({
          path: fullPath,
          name: item,
          publicId: path.basename(item, ext), // Bỏ extension để làm Public ID
        });
      }
    }
  }
  
  return files;
}

// Upload single file
async function uploadFile(file) {
  return new Promise((resolve, reject) => {
    // Public ID có folder prefix: foods/banh-hue
    // URL sẽ là: https://res.cloudinary.com/dinrpqxne/image/upload/v1765710866/foods/banh-hue.jpg
    // Lưu ý: Chỉ set public_id với folder prefix, KHÔNG set folder option
    // Nếu set cả 2, Cloudinary sẽ tự động thêm folder prefix → foods/foods/banh-hue.jpg (sai!)
    const publicId = `${options.folder}/${file.publicId}`;
    
    cloudinary.uploader.upload(
      file.path,
      {
        public_id: publicId, // Public ID có folder prefix: foods/banh-hue (chỉ set cái này)
        // KHÔNG set folder option ở đây để tránh duplicate prefix
        overwrite: options.overwrite,
        resource_type: 'image',
        use_filename: false, // Không dùng tên file tự động
        unique_filename: false, // Không thêm suffix tự động
      },
      (error, result) => {
        if (error) {
          reject({ file: file.name, error });
        } else {
          resolve({ file: file.name, result });
        }
      }
    );
  });
}

// Main function
async function main() {
  console.log('🚀 Bắt đầu upload ảnh lên Cloudinary...\n');
  console.log(`📁 Folder: ${folderPath}`);
  console.log(`📂 Cloudinary folder: ${options.folder}`);
  console.log(`🔄 Overwrite: ${options.overwrite ? 'Có' : 'Không'}`);
  console.log(`☁️  Cloud name: ${cloudinary.config().cloud_name}`);
  console.log(`ℹ️  Lưu ý: Public ID sẽ có folder prefix (ví dụ: ${options.folder}/banh-can)\n`);
  
  // Get all image files
  const files = getImageFiles(folderPath);
  
  if (files.length === 0) {
    console.log('⚠️  Không tìm thấy file ảnh nào trong folder');
    process.exit(0);
  }
  
  console.log(`📸 Tìm thấy ${files.length} file ảnh:\n`);
  files.forEach((file, index) => {
    console.log(`  ${index + 1}. ${file.name} → Public ID: ${options.folder}/${file.publicId}`);
  });
  console.log('');
  
  // Upload files
  const results = {
    success: [],
    failed: [],
  };
  
  console.log('⏳ Đang upload...\n');
  
  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    try {
      process.stdout.write(`[${i + 1}/${files.length}] Uploading ${file.name}... `);
      const result = await uploadFile(file);
      results.success.push(result);
      console.log('✅');
    } catch (error) {
      results.failed.push({ file: file.name, error: error.error || error });
      console.log('❌');
      if (error.error) {
        console.log(`   Error: ${error.error.message}`);
      }
    }
  }
  
  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 Kết quả:\n');
  console.log(`✅ Thành công: ${results.success.length}`);
  console.log(`❌ Thất bại: ${results.failed.length}`);
  
  if (results.success.length > 0) {
    console.log('\n✅ Files đã upload thành công:');
    results.success.forEach((item) => {
      // Public ID có folder prefix: foods/banh-hue
      const publicId = item.result.public_id;
      const url = item.result.secure_url;
      console.log(`  - ${item.file}`);
      console.log(`    Public ID: ${publicId} (có folder prefix: ${options.folder}/)`);
      console.log(`    URL: ${url}\n`);
    });
  }
  
  if (results.failed.length > 0) {
    console.log('\n❌ Files upload thất bại:');
    results.failed.forEach((item) => {
      console.log(`  - ${item.file}`);
      if (item.error && item.error.message) {
        console.log(`    Error: ${item.error.message}`);
      }
      console.log('');
    });
  }
  
  console.log('='.repeat(50));
  console.log('\n✨ Hoàn thành!');
}

// Run
main().catch((error) => {
  console.error('❌ Lỗi:', error);
  process.exit(1);
});

