#!/bin/bash
set -e

echo "=== DevContainer セットアップ開始 ==="

# システムパッケージの更新とインストール
echo "1/5: システムパッケージを更新中..."
sudo apt-get update

echo "2/5: 必要パッケージをインストール中..."
sudo apt-get install -y \
    pandoc \
    fonts-noto-cjk \
    fonts-morisawa-bizud-mincho \
    fonts-morisawa-bizud-gothic \
    locales \
    python3-pip \
    python3-venv \
    python3-full \
    pipx

# pipxでDVCインストール（SSH対応）
echo "3/5: pipxでDVCをインストール中（SSH対応）..."
pipx install "dvc[ssh]"

# 日本語ロケール設定
echo "4/5: 日本語ロケールを設定中..."
sudo sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=ja_JP.UTF-8

# クリーンアップ
echo "5/5: クリーンアップ中..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "=== DevContainer セットアップ完了 ==="
echo "DVCバージョン: $(dvc --version)"
