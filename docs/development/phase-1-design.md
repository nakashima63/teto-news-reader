# Phase -1: アーキテクチャ設計

## このフェーズのゴール

実装前に全体設計を明確化し、ドキュメント化する。
実装中の迷いを減らし、モジュール間の依存関係を整理する。

## 作業内容

1. `docs/architecture.md` の作成
2. `docs/api-reference.md` の作成（骨格）
3. システムフロー図の作成

## やらないこと

- 実装コードの作成
- 詳細な実装方法の決定（各フェーズで決める）

---

## docs/architecture.md
````markdown
# システムアーキテクチャ

## 全体構成
````
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
````

## レイヤー構造
````
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
````

## モジュール依存関係
````
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