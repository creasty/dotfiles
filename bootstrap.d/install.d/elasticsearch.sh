section "Installing Elasticsearch plugins"
cat $DOTFILES_PATH/elasticsearch/plugins.txt | xargs -n 1 plugin --install
