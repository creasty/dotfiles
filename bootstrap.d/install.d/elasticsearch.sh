section "Installing Elasticsearch plugins"
plugin --install royrusso/elasticsearch-HQ
plugin --install mobz/elasticsearch-head
plugin --install elasticsearch/elasticsearch-analysis-kuromoji/2.2.0
plugin --install polyfractal/elasticsearch-inquisitor
plugin --install elasticsearch/marvel/latest

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
