# API リファレンス

このドキュメントは、Teto News Reader の各モジュールの公開 API を定義します。
実装時はこのインターフェースに従って開発を進めてください。

---

## config.py

### 関数

#### `load_config(config_path: str = "config.yaml") -> dict`

設定ファイルを読み込む。

**Args:**
- `config_path` (str): 設定ファイルのパス（デフォルト: "config.yaml"）

**Returns:**
- `dict`: 設定内容の辞書

**Raises:**
- `ConfigError`: 設定ファイルが見つからない、または形式が不正な場合

**Example:**
```python
config = load_config()
rss_feeds = config["rss_feeds"]
```

---

#### `validate_config(config: dict) -> None`

設定内容の妥当性を検証する。

**Args:**
- `config` (dict): 検証する設定辞書

**Raises:**
- `ConfigError`: 必須項目が不足している、または値が不正な場合

---

## logger.py

### 関数

#### `setup_logger(name: str = "teto-news", config: dict | None = None) -> logging.Logger`

ロガーのセットアップを行う。

**Args:**
- `name` (str): ロガー名（デフォルト: "teto-news"）
- `config` (dict | None): ログ設定（Noneの場合はデフォルト設定）

**Returns:**
- `logging.Logger`: 設定済みのロガーインスタンス

**Example:**
```python
logger = setup_logger("teto-news")
logger.info("処理を開始します")
```

---

## modules/rss_fetcher.py

### データクラス

#### `NewsArticle`

ニュース記事を表すデータクラス。

**Attributes:**
- `id` (str): 記事の一意ID（通常はリンクURL）
- `title` (str): 記事タイトル
- `content` (str): 記事本文
- `link` (str): 元記事のURL
- `published` (datetime): 公開日時

**Example:**
```python
@dataclass
class NewsArticle:
    id: str
    title: str
    content: str
    link: str
    published: datetime
```

---

### クラス

#### `class RSSFetcher`

RSS フィードからニュース記事を取得するクラス。

##### `__init__(config: dict, logger: logging.Logger)`

**Args:**
- `config` (dict): RSS設定（rss_feeds キーを含む）
- `logger` (logging.Logger): ロガーインスタンス

---

##### `fetch() -> list[NewsArticle]`

設定された全てのRSSフィードからニュース記事を取得する。

**Returns:**
- `list[NewsArticle]`: 取得した記事のリスト

**Raises:**
- `RSSFetchError`: フィード取得に失敗した場合（部分失敗は許容）

**Example:**
```python
fetcher = RSSFetcher(config, logger)
articles = fetcher.fetch()
for article in articles:
    print(article.title)
```

---

##### `fetch_feed(feed_url: str, max_items: int = 10) -> list[NewsArticle]`

指定されたRSSフィードから記事を取得する。

**Args:**
- `feed_url` (str): RSS フィードのURL
- `max_items` (int): 取得する最大記事数（デフォルト: 10）

**Returns:**
- `list[NewsArticle]`: 取得した記事のリスト

**Raises:**
- `RSSFetchError`: フィード取得に失敗した場合

---

## modules/summarizer.py

### クラス

#### `class NewsSummarizer`

ChatGPT API を使ってニュース記事を要約するクラス。

##### `__init__(config: dict, logger: logging.Logger)`

**Args:**
- `config` (dict): OpenAI設定（openai キーを含む）
- `logger` (logging.Logger): ロガーインスタンス

**Environment Variables:**
- `OPENAI_API_KEY`: OpenAI API キー（必須）

**Raises:**
- `SummarizerError`: API キーが未設定の場合

---

##### `summarize(content: str, max_length: int = 150) -> str`

記事本文を要約する。

**Args:**
- `content` (str): 要約対象のテキスト
- `max_length` (int): 要約の最大文字数（目安、デフォルト: 150）

**Returns:**
- `str`: 要約されたテキスト

**Raises:**
- `SummarizerError`: API 呼び出しに失敗した場合

**Example:**
```python
summarizer = NewsSummarizer(config, logger)
summary = summarizer.summarize(article.content)
print(summary)
```

---

## modules/tts_handler.py

### クラス

#### `class TTSHandler`

VOICEPEAK を使って音声合成を行うクラス。

##### `__init__(config: dict, logger: logging.Logger)`

**Args:**
- `config` (dict): VOICEPEAK設定（voicepeak キーを含む）
- `logger` (logging.Logger): ロガーインスタンス

**Raises:**
- `TTSError`: VOICEPEAK が見つからない場合

---

##### `synthesize(text: str, output_path: str | None = None) -> str`

テキストを音声ファイルに変換する。

**Args:**
- `text` (str): 音声合成するテキスト（140文字以内推奨）
- `output_path` (str | None): 出力ファイルパス（Noneの場合は一時ファイル）

**Returns:**
- `str`: 生成された音声ファイルのパス

**Raises:**
- `TTSError`: 音声合成に失敗した場合

**Example:**
```python
tts = TTSHandler(config, logger)
audio_file = tts.synthesize("こんにちは、重音テトです。")
```

---

##### `synthesize_chunks(chunks: list[str], output_dir: str = "./audio") -> list[str]`

複数のテキストチャンクを音声ファイルに変換する。

**Args:**
- `chunks` (list[str]): テキストチャンクのリスト
- `output_dir` (str): 出力ディレクトリ（デフォルト: "./audio"）

**Returns:**
- `list[str]`: 生成された音声ファイルパスのリスト

**Raises:**
- `TTSError`: 音声合成に失敗した場合

---

## modules/audio_player.py

### クラス

#### `class AudioPlayer`

音声ファイルを再生するクラス。

##### `__init__(logger: logging.Logger)`

**Args:**
- `logger` (logging.Logger): ロガーインスタンス

---

##### `play(audio_path: str, cleanup: bool = True) -> None`

音声ファイルを再生する。

**Args:**
- `audio_path` (str): 再生する音声ファイルのパス
- `cleanup` (bool): 再生後にファイルを削除するか（デフォルト: True）

**Raises:**
- `AudioPlaybackError`: 再生に失敗した場合

**Example:**
```python
player = AudioPlayer(logger)
player.play("/path/to/audio.wav")
```

---

##### `play_multiple(audio_paths: list[str], cleanup: bool = True) -> None`

複数の音声ファイルを順次再生する。

**Args:**
- `audio_paths` (list[str]): 再生する音声ファイルパスのリスト
- `cleanup` (bool): 再生後にファイルを削除するか（デフォルト: True）

**Raises:**
- `AudioPlaybackError`: 再生に失敗した場合

---

## utils/exceptions.py

### 例外クラス

#### `class TetoNewsError(Exception)`

全ての例外の基底クラス。

---

#### `class ConfigError(TetoNewsError)`

設定ファイル関連のエラー。

---

#### `class RSSFetchError(TetoNewsError)`

RSS フィード取得時のエラー。

---

#### `class SummarizerError(TetoNewsError)`

要約生成時のエラー。

---

#### `class TTSError(TetoNewsError)`

音声合成時のエラー。

---

#### `class AudioPlaybackError(TetoNewsError)`

音声再生時のエラー。

---

## utils/text_splitter.py

### 関数

#### `split_text(text: str, max_length: int = 120) -> list[str]`

テキストを指定文字数で分割する。

**Args:**
- `text` (str): 分割対象のテキスト
- `max_length` (int): 1チャンクの最大文字数（デフォルト: 120）

**Returns:**
- `list[str]`: 分割されたテキストのリスト

**Raises:**
- `ValueError`: max_length が 0 以下の場合

**Example:**
```python
chunks = split_text("長いテキスト...", max_length=120)
for chunk in chunks:
    print(chunk)
```

**アルゴリズム:**
1. まず句点（。）で分割
2. チャンクが max_length を超える場合は読点（、）で分割
3. それでも超える場合は強制的に max_length で分割

---

## utils/cache_manager.py

### クラス

#### `class CacheManager`

既読記事のキャッシュを管理するクラス。

##### `__init__(cache_file: str = "./cache/read_articles.json", ttl_hours: int = 24)`

**Args:**
- `cache_file` (str): キャッシュファイルのパス（デフォルト: "./cache/read_articles.json"）
- `ttl_hours` (int): キャッシュの有効期限（時間、デフォルト: 24）

---

##### `is_read(article_id: str) -> bool`

記事が既読かどうかをチェックする。

**Args:**
- `article_id` (str): 記事の一意ID

**Returns:**
- `bool`: 既読の場合 True、未読の場合 False

**Example:**
```python
cache = CacheManager()
if not cache.is_read(article.id):
    # 未読記事を処理
    process_article(article)
    cache.mark_as_read(article.id, article.title)
```

---

##### `mark_as_read(article_id: str, title: str = "") -> None`

記事を既読としてマークする。

**Args:**
- `article_id` (str): 記事の一意ID
- `title` (str): 記事タイトル（オプション、ログ用）

**Raises:**
- `IOError`: ファイル書き込みに失敗した場合

---

##### `cleanup_old_entries() -> int`

TTL を超えた古いエントリを削除する。

**Returns:**
- `int`: 削除したエントリ数

---

##### `clear() -> None`

全てのキャッシュをクリアする。

---

## main.py

### 関数

#### `main() -> int`

メインエントリーポイント。

**Returns:**
- `int`: 終了コード（0: 成功、1: エラー）

**処理フロー:**
1. 設定ファイル読み込み
2. ロガーセットアップ
3. RSS フィード取得
4. 既読チェック
5. 要約生成
6. テキスト分割
7. 音声合成
8. 音声再生
9. 既読登録

**Example:**
```bash
python src/main.py
```

---

## データ型定義

### 型エイリアス

```python
from typing import TypeAlias
from datetime import datetime

# 設定辞書の型
ConfigDict: TypeAlias = dict[str, Any]

# RSS フィード設定
RSSFeedConfig: TypeAlias = dict[str, str | int]  # {"url": str, "name": str, "max_items": int}

# ログ設定
LogConfig: TypeAlias = dict[str, str]  # {"level": str, "file": str}
```

---

## 使用例

### 基本的な使用例

```python
from src.config import load_config
from src.logger import setup_logger
from src.modules.rss_fetcher import RSSFetcher
from src.modules.summarizer import NewsSummarizer
from src.modules.tts_handler import TTSHandler
from src.modules.audio_player import AudioPlayer
from src.utils.cache_manager import CacheManager
from src.utils.text_splitter import split_text

# 設定とロガーのセットアップ
config = load_config()
logger = setup_logger()

# 各モジュールの初期化
rss_fetcher = RSSFetcher(config, logger)
summarizer = NewsSummarizer(config, logger)
tts_handler = TTSHandler(config, logger)
audio_player = AudioPlayer(logger)
cache_manager = CacheManager()

# ニュース取得と処理
articles = rss_fetcher.fetch()

for article in articles:
    # 既読チェック
    if cache_manager.is_read(article.id):
        logger.info(f"既読記事をスキップ: {article.title}")
        continue

    # 要約生成
    summary = summarizer.summarize(article.content)

    # テキスト分割
    chunks = split_text(summary, max_length=120)

    # 音声合成
    audio_files = tts_handler.synthesize_chunks(chunks)

    # 音声再生
    audio_player.play_multiple(audio_files)

    # 既読登録
    cache_manager.mark_as_read(article.id, article.title)

    logger.info(f"処理完了: {article.title}")

# 古いキャッシュのクリーンアップ
cache_manager.cleanup_old_entries()
```

---

## 注意事項

### 実装時の注意
1. **型ヒント**: 全ての関数に型アノテーションを付けること
2. **Docstring**: Google style形式で記述すること
3. **エラーハンドリング**: 適切な例外を発生させること
4. **ログ出力**: 重要な処理の前後でログを出力すること
5. **テスト**: 実装と同時に単体テストを作成すること

### テスト時の注意
- 外部依存（OpenAI API、VOICEPEAK、RSSフィード）は全てモック化すること
- モックフィクスチャは `tests/conftest.py` に配置すること
- テストデータは `tests/fixtures/` に配置すること

---

## バージョニング

このAPI仕様は実装フェーズの進行に伴って更新されます。

- **Version 0.1.0** (Phase -1): 初版作成
- 今後のフェーズで随時更新予定

---

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2025-10-26 | 0.1.0 | 初版作成（Phase -1） |
