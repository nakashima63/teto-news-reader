#!/bin/bash
# 開発環境のセットアップスクリプト

set -e

PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$PROJECT_ROOT"

echo "🚀 セットアップを開始します..."

# 環境チェック
echo "📋 環境チェック"
bash scripts/check_environment.sh || exit 1

# 仮想環境の作成
echo ""
echo "📋 仮想環境の作成"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ 仮想環境を作成しました"
else
    echo "✅ 仮想環境は既に存在します"
fi

# 仮想環境の有効化
source venv/bin/activate

# pipのアップグレード
pip install --upgrade pip -q

# 依存パッケージのインストール
echo ""
echo "📋 パッケージインストール"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt -q
fi
if [ -f "requirements-dev.txt" ]; then
    pip install -r requirements-dev.txt -q
fi
echo "✅ パッケージをインストールしました"

# 必要なディレクトリの作成
mkdir -p logs cache audio

# 設定ファイルのコピー
if [ ! -f "config.yaml" ] && [ -f "config.yaml.example" ]; then
    cp config.yaml.example config.yaml
fi
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    cp .env.example .env
fi

# パーミッション設定
if [ -f "config.yaml" ]; then
    chmod 600 config.yaml
fi
if [ -f ".env" ]; then
    chmod 600 .env
fi

echo ""
echo "✨ セットアップが完了しました"
echo ""
echo "次のコマンドで仮想環境を有効化:"
echo "  source venv/bin/activate"
