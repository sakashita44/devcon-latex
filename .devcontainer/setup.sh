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

# ロケールの確認と環境変数の設定
echo "利用可能なロケール:"
locale -a | grep ja || echo "日本語ロケールが見つかりません"

# 利用可能なロケール形式を自動検出して設定
if locale -a | grep -q "ja_JP.utf8"; then
    export LC_ALL=ja_JP.utf8
    export LANG=ja_JP.utf8
    echo "ロケールをja_JP.utf8に設定"
elif locale -a | grep -q "ja_JP.UTF-8"; then
    export LC_ALL=ja_JP.UTF-8
    export LANG=ja_JP.UTF-8
    echo "ロケールをja_JP.UTF-8に設定"
else
    echo "日本語ロケールが利用できません。C.UTF-8を使用します"
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
fi

# クリーンアップ
echo "5/5: クリーンアップ中..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "=== DevContainer セットアップ完了 ==="
echo "DVCバージョン: $(dvc --version)"
