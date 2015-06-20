section "Installing Elasticsearch plugins"
cat $DOTFILES_PATH/elasticsearch/requirements.txt | xargs -n 1 plugin --install
