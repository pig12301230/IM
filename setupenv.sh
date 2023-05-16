#!/bin/bash

# 這個 script 裡各個套件的版本都跟 build machine 一樣，只要執行這段 script，你的開發環境就會跟 build machine 上一樣。但如果你是第一次安裝 rbenv，就會需要這段 script 幫你安裝完 rbenv 之後，重開你的 terminal 後再執行這段 script 一次將後面的套件安裝完。

# 檢查 Homebrew 是否已經安裝
if ! command -v brew &> /dev/null; then
    echo "Homebrew 未安裝，正在安裝 Homebrew..."
    # 使用 Homebrew 的安裝腳本進行安裝
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "Homebrew 安裝完成。"
else
    echo "Homebrew 已經安裝。"
fi

# 檢查是否已經安裝 rbenv
if ! command -v rbenv >/dev/null 2>&1; then
    echo "正在安裝 rbenv..."
    # 透過 Homebrew 安裝 rbenv
    brew install rbenv
    # 初始化 rbenv
    rbenv init

    # 自動將 rbenv 初始化代碼添加到 shell 啟動文件中
    if [ -n "$ZSH_VERSION" ]; then
        echo 'eval "$(rbenv init -)"' >> ~/.zshrc
        echo "已將 rbenv 初始化代碼添加到 ~/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
        echo "已將 rbenv 初始化代碼添加到 ~/.bashrc"
    else
        echo "未檢測到 bash 或 zsh，請手動將以下代碼加入您的 shell 啟動文件："
        echo 'eval "$(rbenv init -)"'
    fi
    echo "請重新啟動您的 shell 以便使用 rbenv。"
    exit
else
    echo "rbenv 已經安裝！"
fi

# 檢查 Ruby 2.6.8 是否已安裝
if ! rbenv versions | grep -q '2.6.8'; then
  echo "正在安裝 Ruby 2.6.8..."
  rbenv install 2.6.8
  rbenv local 2.6.8
fi

rbenv local 2.6.8

# 檢查 Bundler 2.2.21 是否已安裝
if ! gem list bundler | grep -q '2.2.21'; then
  echo "正在安裝 Bundler 2.2.21..."
  rbenv exec gem install bundler -v 2.2.21
fi

# 安裝專案依賴
rbenv exec bundle install
# 執行 pod install
rbenv exec bundle exec pod install
