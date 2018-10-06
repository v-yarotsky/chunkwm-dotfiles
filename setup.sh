#!/bin/bash

set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
MSG_WIDTH=$(expr $(tput cols) - 13)

function echo_step() {
  printf "%-*s%s" "$MSG_WIDTH" "$1"
}

function echo_ok() {
  printf " %s%s%s\n" "$GREEN" "[OK]" "$NORMAL"
}

function echo_err() {
  printf " %s%s%s\n" "$RED" "[FAIL]" "$NORMAL"
}

function echo_hint() {
  if [ -n "$1" ]; then
    echo >&2 "$1"
  fi
}

trap - EXIT
# trap "echo Oh noes! All your base no belong to us :(" EXIT

UNAME=$(uname)
CHUNKWMRC_D="$HOME/.chunkwmrc.d"

if [ "$UNAME" != "Darwin" ]; then
  echo_err
  echo_hint "Only macOS is supported"
  exit 1
fi

echo_step "Checking that chunkwm is installed"
if ! hash chunkwm 2>/dev/null; then
  echo_err
  echo_hint "chunkwm is not installed"
  echo_hint "You can install it by running:\n  brew tap crisidev/homebrew-chunkwm && brew install chunkwm"
else
  echo_ok
fi

echo_step "Checking that skhd is installed"
if ! hash skhd 2>/dev/null; then
  echo_err
  echo_hint "skhd is not installed"
  echo_hint "You can install it by running:\n  brew install koekeishiya/formulae/skhd"
else
  echo_ok
fi

SYMLINKED_CHUNKWM_CONF="$HOME/.chunkwmrc"
echo_step "Symlinking chunkwm config to $SYMLINKED_CHUNKWM_CONF"
if [ ! -f "$SYMLINKED_CHUNKWM_CONF" ]; then
  ln -s "$CHUNKWMRC_D/.chunkwmrc" $SYMLINKED_CHUNKWM_CONF
  echo_ok
else
  echo_err
  echo_hint "$SYMLINKED_CHUNKWM_CONF already exists. I will not overwrite it."
  echo_hint "Remove it cautiously, then rerun"
  exit 1
fi

SYMLINKED_SKHD_CONF="$HOME/.skhdrc"
echo_step "Symlinking skhd config to $SYMLINKED_SKHD_CONF"
if [ ! -f "$SYMLINKED_SKHD_CONF" ]; then
  ln -s "$CHUNKWMRC_D/.skhdrc" $SYMLINKED_SKHD_CONF
  echo_ok
else
  echo_err
  echo_hint "$SYMLINKED_SKHD_CONF already exists. I will not overwrite it."
  echo_hint "Remove it cautiously, then rerun"
  exit 1
fi

echo_step "Ensuring that osdod is installed"
if ! hash osdod 2>/dev/null; then
  OSDOD_TMPDIR=$(mktemp -d -t osdod)
  curl --silent --location "https://github.com/v-yarotsky/osdod/releases/download/v0.0.1a/osdod.zip" > "$OSDOD_TMPDIR/osdod.zip"
  pushd "$OSDOD_TMPDIR"
  unzip osdod.zip
  cp *.plist ~/Library/LaunchAgents
  cp osdod /usr/local/bin/
  cp osdodc /usr/local/bin
  popd
  rm -rf "$OSDOD_TMPDIR"
  echo_ok
else
  echo_ok
fi

echo_step "Launching skhd"
brew services restart skhd && echo_ok || echo_err
brew services restart chunkwm && echo_ok || echo_err
launchctl load ~/Library/LaunchAgents/me.yarotsky.osdod.plist && echo_ok || echo_err

echo "Done."

trap - EXIT
