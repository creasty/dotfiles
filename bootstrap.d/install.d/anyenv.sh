ANYENV_DIR=$HOME/.anyenv
PLUGINS_DIR=$ANYENV_DIR/plugins

if [ -d $ANYENV_DIR ]; then
  git --git-dir="$ANYENV_DIR" reset --hard HEAD
  git --git-dir="$ANYENV_DIR" pull origin master
else
  git clone https://github.com/riywo/anyenv $ANYENV_DIR
fi

[ -d $PLUGINS_DIR ] || mkdir -p $PLUGINS_DIR

if [ -d $PLUGINS_DIR/anyenv-update ]; then
  git --git-dir="$PLUGINS_DIR/anyenv-update" reset --hard HEAD
  git --git-dir="$PLUGINS_DIR/anyenv-update" pull origin master
else
  git clone https://github.com/znz/anyenv-update.git $PLUGINS_DIR/anyenv-update
fi
