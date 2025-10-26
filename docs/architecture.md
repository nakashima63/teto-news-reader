# システムアーキテクチャ

## システム概要

Teto News Readerは、RSSフィードからニュースを自動取得し、ChatGPT APIで要約、VOICEPEAK（重音テト）で音声合成して定時読み上げを行うシステムです。

### 主要機能
- RSS フィードからのニュース自動取得
- ChatGPT API による要約生成
- VOICEPEAK による音声合成
- 既読管理によるニュース重複防止
- 定時実行対応（cron連携）

### 設計原則
- **疎結合**: 各モジュールは独立して動作可能
- **テスタビリティ**: 外部依存はモック化可能
- **拡張性**: 新しいRSSフィード、音声エンジンの追加が容易
- **エラー耐性**: 部分的な失敗でもシステム全体は継続動作

---

## 全体構成

```
┌─────────────┐
│    cron     │ 定時実行トリガー
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│              main.py                        │
│  (エントリーポイント・全体制御)              │
└─────┬───────────────────────────────────┬───┘
      │                                   │
      ▼                                   ▼
┌─────────────┐                     ┌──────────────┐
│  config.py  │                     │  logger.py   │
│ (設定読込)   │                     │ (ログ管理)    │
└─────────────┘                     └──────────────┘
      │
      ▼
┌──────────────────────────────────────────────────┐
│              処理フロー                            │
└──────────────────────────────────────────────────┘
      │
      ├─► RSSFetcher ──► NewsArticle[]
      │   (RSS取得)
      │
      ├─► CacheManager.is_read() ──► 既読チェック
      │
      ├─► NewsSummarizer ──► 要約テキスト
      │   (ChatGPT API)
      │
      ├─► TextSplitter ──► 分割テキスト[]
      │   (140文字制限対応)
      │
      ├─► TTSHandler ──► 音声ファイル
      │   (VOICEPEAK)
      │
      ├─► AudioPlayer ──► 音声再生
      │
      └─► CacheManager.mark_as_read() ──► 既読登録
```

---

## レイヤー構造

```
┌─────────────────────────────────────┐
│   Presentation Layer                │
│   - main.py (CLI)                   │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│   Application Layer                 │
│   - 処理フロー制御                    │
│   - エラーハンドリング                 │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│   Domain Layer                      │
│   - RSSFetcher                      │
│   - NewsSummarizer                  │
│   - TTSHandler                      │
│   - AudioPlayer                     │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│   Infrastructure Layer              │
│   - Config (設定管理)                │
│   - Logger (ログ管理)                │
│   - CacheManager (永続化)            │
│   - TextSplitter (ユーティリティ)     │
└─────────────────────────────────────┘
```

### レイヤーの責務

#### Presentation Layer（表現層）
- **main.py**: CLIエントリーポイント、コマンドライン引数処理
- ユーザーインターフェース（将来的にはWeb UI も対応可能）

#### Application Layer（アプリケーション層）
- ビジネスロジックの統合
- 各ドメインサービスの呼び出し順序制御
- トランザクション管理（キャッシュの読み書き）
- 全体的なエラーハンドリング

#### Domain Layer（ドメイン層）
- コアビジネスロジック
- 外部サービスとのインテグレーション
- ドメインモデル（NewsArticle等）の定義

#### Infrastructure Layer（インフラストラクチャ層）
- 設定ファイル読み込み
- ログ出力
- ファイル I/O
- ユーティリティ関数

---

## モジュール依存関係

```
main.py
├── config.py
├── logger.py
├── modules/
│   ├── rss_fetcher.py (依存: feedparser)
│   ├── summarizer.py (依存: openai, exceptions)
│   ├── tts_handler.py (依存: subprocess, text_splitter)
│   └── audio_player.py (依存: subprocess)
└── utils/
    ├── exceptions.py (依存なし)
    ├── text_splitter.py (依存なし)
    └── cache_manager.py (依存: json, datetime)
```

### 依存関係の原則
- **上位層から下位層への依存のみ**: Presentation → Application → Domain → Infrastructure
- **循環依存の禁止**: どのモジュール間にも循環参照は存在しない
- **インターフェース分離**: モジュール間は明確なインターフェースで分離

---

## データフロー

### 1. ニュース取得フロー
```
[RSS Feed] → RSSFetcher.fetch()
            ↓
         NewsArticle[]
            ↓
         CacheManager.is_read(article_id)
            ↓
         [未読記事のフィルタリング]
```

### 2. 要約生成フロー
```
NewsArticle.content
    ↓
NewsSummarizer.summarize(content)
    ↓ (OpenAI API呼び出し)
要約テキスト (str)
```

### 3. 音声合成フロー
```
要約テキスト
    ↓
TextSplitter.split(text, max_length=120)
    ↓
テキストチャンク[] (各120文字以下)
    ↓
for chunk in chunks:
    TTSHandler.synthesize(chunk)
    ↓
    音声ファイルパス (str)
    ↓
    AudioPlayer.play(filepath)
```

### 4. 既読管理フロー
```
処理完了後
    ↓
CacheManager.mark_as_read(article_id)
    ↓
cache/read_articles.json に保存
```

---

## モジュール詳細

### config.py
**責務**: 設定ファイル（config.yaml, .env）の読み込みと検証

**主要機能**:
- YAML 設定ファイルのパース
- 環境変数の読み込み（.env）
- 設定値のバリデーション
- デフォルト値の提供

**依存**: pyyaml, python-dotenv

---

### logger.py
**責務**: ロギング設定の一元管理

**主要機能**:
- ログレベルの設定
- ログファイル出力
- コンソール出力
- ログフォーマット統一

**依存**: Python標準 logging モジュール

---

### modules/rss_fetcher.py
**責務**: RSS フィードからニュース記事を取得

**主要機能**:
- RSS フィードのパース
- NewsArticle データクラスへの変換
- フィード取得エラーのハンドリング
- タイムアウト処理

**依存**: feedparser

**データモデル**:
```python
@dataclass
class NewsArticle:
    id: str          # 記事の一意ID (通常はlink)
    title: str       # タイトル
    content: str     # 本文
    link: str        # 元記事URL
    published: datetime  # 公開日時
```

---

### modules/summarizer.py
**責務**: ChatGPT API を使った記事要約

**主要機能**:
- OpenAI API呼び出し
- プロンプトエンジニアリング（簡潔な要約指示）
- API エラーハンドリング（リトライ、レート制限）
- トークン数制限対応

**依存**: openai, utils/exceptions

**制約**:
- モデル: gpt-4o-mini
- 最大トークン: 150
- 要約長: 約100-200文字程度

---

### modules/tts_handler.py
**責務**: VOICEPEAK による音声合成

**主要機能**:
- VOICEPEAK CLI の実行
- 音声ファイル生成
- 140文字制限への対応（TextSplitterとの連携）
- コマンドインジェクション対策

**依存**: subprocess, utils/text_splitter

**制約**:
- VOICEPEAK の制限: 1回あたり最大140文字
- ナレーター: 重音テト
- 出力形式: WAV

---

### modules/audio_player.py
**責務**: 音声ファイルの再生

**主要機能**:
- プラットフォーム別再生コマンド実行
  - Linux: aplay
  - macOS: afplay
  - Windows: 未対応（将来実装）
- 再生完了待機
- エラーハンドリング

**依存**: subprocess

---

### utils/exceptions.py
**責務**: カスタム例外クラスの定義

**主要クラス**:
- `TetoNewsError`: 基底例外
- `ConfigError`: 設定エラー
- `RSSFetchError`: RSS取得エラー
- `SummarizerError`: 要約生成エラー
- `TTSError`: 音声合成エラー
- `AudioPlaybackError`: 音声再生エラー

---

### utils/text_splitter.py
**責務**: テキストを指定文字数で分割

**主要機能**:
- 句読点を考慮した自然な分割
- 最大文字数制限の遵守
- 空白・改行の正規化

**依存**: なし

**アルゴリズム**:
1. テキストを句点（。）で分割
2. 各文が max_length を超える場合は読点（、）で分割
3. それでも超える場合は強制分割

---

### utils/cache_manager.py
**責務**: 既読記事のキャッシュ管理

**主要機能**:
- JSON ファイルへの読み書き
- 記事ID による既読チェック
- TTL（Time To Live）による古いキャッシュの削除
- スレッドセーフな読み書き（将来実装）

**依存**: json, datetime

**データ構造**:
```json
{
  "article_id_1": {
    "read_at": "2025-10-26T10:00:00",
    "title": "記事タイトル"
  },
  "article_id_2": { ... }
}
```

---

## 技術スタック

### コアパッケージ
| パッケージ | バージョン | 用途 |
|-----------|-----------|------|
| feedparser | 6.0.11 | RSS解析 |
| pyyaml | 6.0.1 | 設定ファイル |
| python-dotenv | 1.0.1 | 環境変数管理 |
| python-dateutil | 2.8.2 | 日時処理 |

### 開発ツール
| ツール | バージョン | 用途 |
|--------|-----------|------|
| pytest | 8.0.0 | テストフレームワーク |
| pytest-cov | 4.1.0 | カバレッジ測定 |
| pytest-mock | 3.12.0 | モック作成 |
| black | 24.1.1 | コードフォーマッター |
| flake8 | 7.0.0 | リンター |
| mypy | 1.8.0 | 型チェッカー |

### 外部サービス
- **OpenAI API**: gpt-4o-mini モデル使用
- **VOICEPEAK**: CLI版、重音テト

---

## エラーハンドリング戦略

### 基本方針
1. **予測可能なエラーは例外として明示的に定義**
2. **リトライ可能なエラーは自動リトライ**
3. **致命的でないエラーは警告ログのみ**
4. **致命的エラーは終了コード 1 で終了**

### エラー分類

#### 回復可能エラー（リトライ対象）
- ネットワーク一時エラー（RSS取得、OpenAI API）
- API レート制限エラー
- 一時的なファイル I/O エラー

**対応**: 指数バックオフでリトライ（最大3回）

#### 部分的エラー（警告ログ）
- 一部の RSS フィード取得失敗
- 一部の記事の要約生成失敗
- 音声ファイル削除失敗

**対応**: ログ出力して処理継続

#### 致命的エラー（即座に終了）
- 設定ファイル読み込み失敗
- VOICEPEAK が見つからない
- OpenAI API キーが未設定

**対応**: エラーメッセージ出力して exit(1)

### エラーログフォーマット
```
ERROR - [モジュール名] エラー内容
  ├─ 原因: ...
  ├─ 詳細: ...
  └─ 対処: ...
```

---

## セキュリティ考慮事項

### 1. 認証情報管理
- **OpenAI API キー**: `.env` ファイルで管理、.gitignore 対象
- **ファイルパーミッション**: config.yaml, .env は 600 に設定
- **ログ出力**: API キーや個人情報は絶対にログに出力しない

### 2. コマンドインジェクション対策
- **subprocess 使用時**: 必ず引数リスト形式で実行（shell=False）
- **外部入力の検証**: RSS フィードの URL やタイトルをサニタイズ

例:
```python
# NG
os.system(f"voicepeak -s '{text}' -o {output}")

# OK
subprocess.run([
    "voicepeak", "-s", text, "-o", output
], check=True)
```

### 3. ファイルパス検証
- **ディレクトリトラバーサル対策**: パス結合時は os.path.join 使用
- **絶対パス化**: 設定ファイルのパスは起動時に絶対パスに変換

### 4. 外部入力の検証
- **RSS フィード**: feedparser で安全にパース
- **URL スキーム**: https のみ許可（http は自動昇格または拒否）

---

## パフォーマンス考慮事項

### 1. API 呼び出し最適化
- **バッチ処理**: 複数記事を並列処理せず、逐次処理（レート制限対策）
- **キャッシュ**: 既読記事は処理をスキップ
- **タイムアウト**: RSS 取得、API 呼び出しにタイムアウト設定

### 2. ファイル I/O 最適化
- **音声ファイル**: 一時ファイルとして生成、再生後に削除
- **キャッシュファイル**: JSON ファイルは読み書き時のみオープン

### 3. メモリ使用量
- **ストリーミング処理**: 大量の記事を一度にメモリに載せない
- **音声ファイル**: チャンクごとに生成・再生・削除

### 4. 実行時間の目安
- RSS 取得: 1-3秒/フィード
- 要約生成: 2-5秒/記事
- 音声合成: 1-2秒/チャンク
- 音声再生: 実際の音声長 + 1秒

**全体**: 3記事で約30-60秒程度

---

## 拡張性

### 将来的な拡張ポイント

#### 1. 複数の音声エンジン対応
- VOICEPEAK 以外（VOICEVOX、CoeFont など）
- 音声エンジンの抽象化インターフェース導入

#### 2. 複数の要約エンジン対応
- Claude、Gemini などの対応
- フォールバック機構（OpenAI が使えない場合）

#### 3. Web UI の追加
- Flask/FastAPI によるダッシュボード
- ニュース一覧表示、手動再生機能

#### 4. データベース導入
- SQLite による永続化
- 記事の全文検索機能

#### 5. 通知機能
- メール通知
- Slack/Discord 連携

---

## テスト戦略

### ユニットテスト
- **カバレッジ目標**: 80% 以上
- **モック対象**: OpenAI API, VOICEPEAK, RSS フィード
- **テストデータ**: `tests/fixtures/` に配置

### インテグレーションテスト
- **シナリオテスト**: RSS取得 → 要約 → 音声合成の一連の流れ
- **エラーケース**: API エラー、ネットワークエラー

### テスト実行
```bash
# 全テスト実行
pytest

# カバレッジ付き
pytest --cov=src --cov-report=html

# 特定のモジュール
pytest tests/test_summarizer.py
```

---

## デプロイメント

### 本番環境
- **OS**: Ubuntu Server 22.04 LTS
- **Python**: 3.10 以上
- **定時実行**: cron

### cron 設定例
```cron
# 毎日 7:00, 12:00, 18:00 にニュース読み上げ
0 7,12,18 * * * cd /path/to/teto-news-reader && /path/to/venv/bin/python src/main.py
```

### ログローテーション
```bash
# /etc/logrotate.d/teto-news
/path/to/teto-news-reader/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

---

## ディレクトリ構造

```
teto-news-reader/
├── src/
│   ├── __init__.py
│   ├── main.py              # エントリーポイント
│   ├── config.py            # 設定管理
│   ├── logger.py            # ログ管理
│   ├── modules/             # ドメインモジュール
│   │   ├── __init__.py
│   │   ├── rss_fetcher.py
│   │   ├── summarizer.py
│   │   ├── tts_handler.py
│   │   └── audio_player.py
│   └── utils/               # ユーティリティ
│       ├── __init__.py
│       ├── exceptions.py
│       ├── text_splitter.py
│       └── cache_manager.py
├── tests/                   # テストコード
│   ├── __init__.py
│   ├── conftest.py          # pytest fixtures
│   ├── fixtures/            # テストデータ
│   ├── test_rss_fetcher.py
│   ├── test_summarizer.py
│   ├── test_tts_handler.py
│   ├── test_audio_player.py
│   ├── test_text_splitter.py
│   └── test_cache_manager.py
├── scripts/                 # セットアップスクリプト
│   ├── check_environment.sh
│   └── install.sh
├── docs/                    # ドキュメント
│   ├── architecture.md      # このファイル
│   ├── api-reference.md
│   └── development/         # フェーズ別開発ガイド
├── logs/                    # ログファイル（.gitignore）
├── cache/                   # キャッシュファイル（.gitignore）
├── audio/                   # 一時音声ファイル（.gitignore）
├── config.yaml.example      # 設定ファイルテンプレート
├── .env.example             # 環境変数テンプレート
├── requirements.txt         # 本番依存パッケージ
├── requirements-dev.txt     # 開発依存パッケージ
├── pytest.ini               # pytest 設定
├── .gitignore
├── LICENSE
└── README.md
```

---

## まとめ

本システムは、レイヤードアーキテクチャに基づいて設計されており、各モジュールが明確な責務を持ち、疎結合で拡張性の高い構造となっています。

外部依存（OpenAI API、VOICEPEAK、RSS フィード）は全てモック化可能であり、テスタビリティを重視した設計となっています。

今後の実装フェーズでは、このアーキテクチャ文書に従ってモジュールごとに段階的に実装を進めていきます。
