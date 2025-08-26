#!/bin/bash

# Script để push ONVIF Flutter library lên GitHub
# Sử dụng: ./push_to_github.sh <your-github-username>

if [ $# -eq 0 ]; then
    echo "❌ Vui lòng cung cấp tên GitHub username"
    echo "Sử dụng: ./push_to_github.sh <your-github-username>"
    echo ""
    echo "📝 Ví dụ: ./push_to_github.sh nghinguyen"
    exit 1
fi

GITHUB_USERNAME=$1
REPO_NAME="onvif-flutter"
REMOTE_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

echo "🚀 Đang thiết lập repository cho: $REMOTE_URL"
echo ""

# Thêm remote origin
echo "📡 Thêm remote origin..."
git remote add origin $REMOTE_URL

# Kiểm tra remote đã được thêm
echo "✅ Kiểm tra remote..."
git remote -v

# Push code lên main branch
echo ""
echo "📤 Push code lên GitHub..."
git branch -M main
git push -u origin main

echo ""
echo "🎉 Hoàn thành! Repository đã được push lên GitHub"
echo "🔗 URL: $REMOTE_URL"
echo ""
echo "📋 Các bước tiếp theo:"
echo "1. Truy cập $REMOTE_URL để xem code"
echo "2. Thêm description và topics cho repository"
echo "3. Tạo releases khi cần thiết"
echo "4. Thêm collaborators nếu cần"
