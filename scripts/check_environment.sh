#!/bin/bash
# 開発環境の最小要件チェック

set -e

echo "🔍 開発環境チェックを開始します..."

# Python バージョンチェック
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 がインストールされていません"
    exit 1
fi

version=$(python3 --version | cut -d' ' -f2)
major=$(echo $version | cut -d'.' -f1)
minor=$(echo $version | cut -d'.' -f2)

if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 10 ]); then
    echo "❌ Python 3.10以上が必要です（現在: $version）"
    exit 1
fi

echo "✅ Python $version"

# pip チェック
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 がインストールされていません"
    exit 1
fi
echo "✅ pip3"

# venv チェック
if ! python3 -m venv --help &> /dev/null; then
    echo "❌ python3-venv がインストールされていません"
    exit 1
fi
echo "✅ venv"

echo ""
echo "✨ 開発環境チェックが完了しました"
