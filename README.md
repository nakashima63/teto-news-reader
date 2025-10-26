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
