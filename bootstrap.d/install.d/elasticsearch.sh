section "Installing Elasticsearch plugins"
cat $DOTFILES_PATH/elasticsearch/requirements.txt | each plugin --install

section "Configure custom Elasticsearch options"

CONFIG_FILE='/usr/local/opt/elasticsearch/config/elasticsearch.yml'

OPTIONS=(
  'script.disable_dynamic: false'
)

if [ -f $CONFIG_FILE ]; then
  for option in "${OPTIONS[@]}"; do
    local key="${option%%:*}"

    echo "Setting $option..."
    if [ "$(grep "$key" $CONFIG_FILE)" == "" ]; then
      echo "$option" >> $CONFIG_FILE
    else
      sed -ie "s/^$key:.*/$option/" $CONFIG_FILE
    fi
  done

  echo "Done"
else
  echo "Elasticsearch config file not found at $CONFIG_FILE"
fi
