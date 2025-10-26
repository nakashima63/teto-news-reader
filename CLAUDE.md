# Teto News Reader - 開発ガイド

## プロジェクト概要

VOICEPEAKの重音テトによる自動ニュース読み上げシステム。
RSSフィードからニュース取得 → ChatGPT要約 → VOICEPEAK音声合成 → 定時読み上げ。

## 開発方針

### 1. 段階的開発
このプロジェクトは**フェーズ単位**で開発を進めます。
各フェーズの詳細は `docs/development/phaseX-*.md` に記載されています。

**重要**: 
- 1フェーズごとに完了報告をして、次の指示を待つこと
- 勝手に次のフェーズに進まないこと
- 指示されたファイル以外は編集しないこと

### 2. コーディング規約

#### 必須事項
- **型ヒント**: 全ての関数に型アノテーションを付ける
- **Docstring**: Google style形式で記述
- **PEP 8準拠**: blackでフォーマット
- **エラーハンドリング**: 適切な例外処理とログ出力
- **テスト**: 実装と同時に単体テストを作成

#### コードスタイル例
````python
def split_text(text: str, max_length: int = 120) -> list[str]:
    """テキストを指定文字数で分割する.
    
    Args:
        text: 分割対象のテキスト
        max_length: 1チャンクの最大文字数
        
    Returns:
        分割されたテキストのリスト
        
    Raises:
        ValueError: max_lengthが0以下の場合
        
    Examples:
        >>> split_text("こんにちは。世界。", 10)
        ["こんにちは。", "世界。"]
    """
    if max_length <= 0:
        raise ValueError("max_length must be positive")
    
    # 実装...
````

### 3. テスト戦略

#### モックの使用
外部依存（OpenAI API、VOICEPEAK、RSSフィード）は全てモック化します。
````python
# tests/conftest.py にモック用フィクスチャを配置
@pytest.fixture
def mock_openai_client():
    """OpenAI APIクライアントのモック."""
    mock = Mock()
    mock.chat.completions.create.return_value = Mock(
        choices=[Mock(message=Mock(content="テスト要約"))]
    )
    return mock
````

#### テストファイル命名規則
- `tests/test_<モジュール名>.py`
- 各関数に対して正常系・異常系のテストを作成

### 4. ファイル構成規則
````
src/
├── config.py           # 設定読み込み
├── logger.py           # ロガー設定
├── main.py             # エントリーポイント
├── modules/            # 機能モジュール
│   ├── __init__.py
│   ├── rss_fetcher.py
│   ├── summarizer.py
│   ├── tts_handler.py
│   └── audio_player.py
└── utils/              # ユーティリティ
    ├── __init__.py
    ├── exceptions.py
    ├── text_splitter.py
    └── cache_manager.py
````

### 5. 技術スタック

#### 必須パッケージ
- **feedparser**: RSS解析
- **pyyaml**: 設定ファイル
- **python-dotenv**: 環境変数管理

#### 開発ツール
- **pytest**: テストフレームワーク
- **black**: コードフォーマッター
- **mypy**: 型チェッカー
- **flake8**: リンター

#### 外部API（本番環境のみ）
- **OpenAI API**: gpt-4o-mini使用
- **VOICEPEAK**: CLI版、140文字制限あり

### 6. セキュリティ要件

- APIキーは`.env`ファイルで管理（.gitignore対象）
- config.yamlのパーミッション: 600
- ログにAPIキーや個人情報を出力しない
- コマンドインジェクション対策（subprocess使用時）

### 7. 完了報告フォーマット

各フェーズ完了時、以下の形式で報告すること：
````
Phase X 完了

作成ファイル:
- path/to/file1.py
- path/to/file2.py

テスト結果:
============================= test session starts ==============================
...
============================= X passed in Xs ===============================

型チェック結果:
Success: no issues found in X source files

次の作業:
次のフェーズの指示を待っています。
````

### 8. 実装の進め方

#### フェーズの開始方法
1. 開発者から「Phase X を開始してください」と指示される
2. `docs/development/phaseX-*.md` を読む
3. そのフェーズで指定されたファイルのみ実装
4. リンターの実行
5. テストを作成・実行
6. 完了報告（上記フォーマット）
7. **次の指示を待つ（勝手に進まない）**

#### 実装順序
各ファイル内では以下の順序で実装：

1. **型定義**: dataclass、型エイリアスなど
2. **例外クラス**: 必要な場合
3. **メイン実装**: クラスや関数
4. **テストコード**: 実装と並行して作成

### 9. よくある質問

#### Q: フェーズの詳細仕様はどこ？
A: `docs/development/phaseX-*.md` を参照してください。

#### Q: 外部APIはどうテストする？
A: `tests/conftest.py` のモックフィクスチャを使用します。

#### Q: エラーが出た場合は？
A: エラー内容を報告して、次の指示を待ってください。

#### Q: フェーズ完了後は？
A: 完了報告をして、**必ず次の指示を待ってください**。勝手に次のフェーズに進まないこと。

---

## 現在のフェーズ

開発を開始する際は、開発者が明示的に指示します。
例: "Phase 0を開始してください。docs/development/phase0-setup.mdを参照してください。"

## アーキテクチャ

詳細は `docs/architecture.md` を参照してください。
````
[定時実行] → [ニュース取得] → [要約] → [音声合成] → [再生]
   cron      RSS Fetcher    ChatGPT    VOICEPEAK   audio player
````

## ライセンス

MIT License