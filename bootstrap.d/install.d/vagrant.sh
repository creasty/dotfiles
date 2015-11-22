section "Installing vagrant boxes"

cat $DOTFILES_PATH/vagrant/boxes.txt \
  | sed 's/\s*#.*$//' \
  | {
    while read -r line; do
      if ! [ -z "$line" ]; then
        name="$(cut -d' ' -f 1 <<< "$line")"
        image="$(cut -d' ' -f 2 <<< "$line")"

        subsection "Install $name"
        vagrant box add "$name" "$image"
        print_status $?
      fi
    done
  }

section "Installing vagrant plugins"
cat $DOTFILES_PATH/vagrant/plugins.txt | xargs -n 1 vagrant plugin install
