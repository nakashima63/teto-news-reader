# Phase 0: 環境構築

## このフェーズのゴール

開発環境をセットアップし、pytestが実行できる状態にする。
**このフェーズでは実装コードは一切書かない。**

## 作業内容

1. ディレクトリ構造の作成
2. 環境構築スクリプトの作成
3. 依存関係ファイルの作成
4. 設定ファイルテンプレートの作成
5. 基本的なREADME.mdの作成

## やらないこと

- Pythonコードの実装
- テストコードの実装
- 複雑なロジック

---

## 作成するファイル一覧

### ディレクトリ構造
````
teto-news-reader/
├── src/
│   ├── __init__.py (空ファイル)
│   ├── modules/
│   │   └── __init__.py (空ファイル)
│   └── utils/
│       └── __init__.py (空ファイル)
├── tests/
│   └── __init__.py (空ファイル)
├── scripts/
├── docs/
│   └── development/  (このファイルがある場所)
├── logs/ (空ディレクトリ、.gitkeep作成)
├── cache/ (空ディレクトリ、.gitkeep作成)
└── audio/ (空ディレクトリ、.gitkeep作成)
````

---

## scripts/check_environment.sh

実行権限を付与すること（chmod +x）
````bash
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
````

---

## scripts/install.sh

実行権限を付与すること（chmod +x）
````bash
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
````

---

## requirements.txt
````txt
feedparser==6.0.11
pyyaml==6.0.1
python-dotenv==1.0.1
python-dateutil==2.8.2
````

---

## requirements-dev.txt
````txt
pytest==8.0.0
pytest-cov==4.1.0
pytest-mock==3.12.0
black==24.1.1
flake8==7.0.0
mypy==1.8.0
types-PyYAML==6.0.12.12
````

---

## .gitignore
````
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.pytest_cache/
.mypy_cache/
.coverage
htmlcov/
*.egg-info/
dist/
build/

# 設定ファイル（機密情報）
.env
config.yaml

# 実行時生成ファイル
logs/
cache/
audio/
*.wav
*.log

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
````

---

## LICENSE
````
MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
````

---

## config.yaml.example
````yaml
# RSS フィード設定
rss_feeds:
  - url: "https://news.yahoo.co.jp/rss/topics/top-picks.xml"
    name: "Yahoo!ニュース"
    max_items: 3

# VOICEPEAK 設定
voicepeak:
  path: "voicepeak"
  narrator: "重音テト"
  max_chars: 120

# OpenAI 設定
openai:
  model: "gpt-4o-mini"
  max_tokens: 150

# ログ設定
logging:
  level: "INFO"
  file: "./logs/teto-news.log"

# キャッシュ設定
cache:
  file: "./cache/read_articles.json"
  ttl_hours: 24
````

---

## .env.example
````bash
# OpenAI API Key (本番環境のみ必要)
# OPENAI_API_KEY=sk-proj-xxxxx
````

---

## pytest.ini
````ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --cov=src --cov-report=term-missing
````

---

## README.md
````markdown
# 🎙️ Teto News Reader

VOICEPEAKの重音テトによる自動ニュース読み上げシステム

## 概要

RSSフィードからニュースを取得し、ChatGPT APIで要約、VOICEPEAKで音声合成して定時読み上げを行います。

## セットアップ

### 環境要件

- Python 3.10以上
- Ubuntu Server 22.04 LTS推奨

### インストール
```bash
# リポジトリのクローン
git clone https://github.com/yourusername/teto-news-reader.git
cd teto-news-reader

# 自動セットアップ
bash scripts/install.sh

# 仮想環境を有効化
source venv/bin/activate
```

## 開発

### テスト実行
```bash
pytest
```

### コード品質チェック
```bash
# フォーマット
black src/ tests/

# 型チェック
mypy src/

# リント
flake8 src/
```

## ライセンス

MIT License

## 開発ドキュメント

詳細は `docs/` ディレクトリを参照してください。
````

---

## 完了条件

- [ ] 上記の全ファイルが作成されている
- [ ] スクリプトに実行権限が付与されている（chmod +x）
- [ ] `bash scripts/install.sh` が正常に実行できる
- [ ] 仮想環境が作成され、パッケージがインストールされている
- [ ] `pytest` が実行できる（テストは0件でもOK）

## 確認コマンド
````bash
# 1. インストール実行
bash scripts/install.sh

# 2. 仮想環境有効化
source venv/bin/activate

# 3. テスト実行（テストファイルがまだないのでコレクションエラーは正常）
pytest

# 4. importチェック
python -c "import yaml; import feedparser; print('OK')"
````

## 完了報告

以下の形式で報告してください：
````
Phase 0 完了

作成ファイル:
- scripts/check_environment.sh
- scripts/install.sh
- requirements.txt
- requirements-dev.txt
- .gitignore
- LICENSE
- config.yaml.example
- .env.example
- pytest.ini
- README.md
- (その他のディレクトリ構造)

確認結果:
$ bash scripts/install.sh
✨ セットアップが完了しました

$ pytest
collected 0 items
(テストファイルがまだないため正常)

次の作業:
Phase 1の指示を待っています。
````