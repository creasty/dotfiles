#!/usr/bin/env bash

# symbolic links
echo "Creating symbolic links..."
cd ~

for file in ~/dotfiles/_*; do
  f=$(basename $file)
  f="$HOME/${f/_/.}"

  if [ ! -L "$f" ]; then
    ln -sf "$file" "$f"
    echo "$file > $f"
  fi
done

echo "ok"

