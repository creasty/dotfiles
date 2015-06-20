section "Installing Elasticsearch plugins"
cat $DOTFILES_PATH/elasticsearch/requirements.txt | each plugin --install
