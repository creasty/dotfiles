section "Configure MacTex"

TEXLIVE_PATH=/usr/local/texlive
TEXLIVE_BIN_PATH=$TEXLIVE_PATH/2015/bin/universal-darwin
TEXLIVE_TEXMR_PATH=$TEXLIVE_PATH/texmf-local

subsection "Install"
if [ -d $TEXLIVE_PATH ]; then
  print_info "Installed"
else
  print_error "Install from http://tug.org/mactex/mactex-download.html"
  exit 1
fi

subsection "Update software"
sudo $TEXLIVE_BIN_PATH/tlmgr update --self --all

subsection "Configure texmf"
mv $DOTFILES_PATH/tex/texmf.cnf $TEXLIVE_TEXMR_PATH/web2c/texmf.cnf
sudo $TEXLIVE_BIN_PATH/mktexlsr

subsection "Setup tex to use Hiragino fonts"
HIRAGINO_INSTALL_DIR=$TEXLIVE_TEXMR_PATH/fonts/opentype/hiragino
sudo mkdir -p $HIRAGINO_INSTALL_DIR

sudo ln -fs "/Library/Fonts/ヒラギノ明朝 Pro W3.otf" $HIRAGINO_INSTALL_DIR/HiraMinPro-W3.otf
sudo ln -fs "/Library/Fonts/ヒラギノ明朝 Pro W6.otf" $HIRAGINO_INSTALL_DIR/HiraMinPro-W6.otf
sudo ln -fs "/Library/Fonts/ヒラギノ丸ゴ Pro W4.otf" $HIRAGINO_INSTALL_DIR/HiraMaruPro-W4.otf
sudo ln -fs "/Library/Fonts/ヒラギノ角ゴ Pro W3.otf" $HIRAGINO_INSTALL_DIR/HiraKakuPro-W3.otf
sudo ln -fs "/Library/Fonts/ヒラギノ角ゴ Pro W6.otf" $HIRAGINO_INSTALL_DIR/HiraKakuPro-W6.otf
sudo ln -fs "/Library/Fonts/ヒラギノ角ゴ Std W8.otf" $HIRAGINO_INSTALL_DIR/HiraKakuStd-W8.otf

sudo $TEXLIVE_BIN_PATH/mktexlsr
sudo $TEXLIVE_BIN_PATH/updmap-sys --setoption kanjiEmbed hiragino

subsection "Make bst/bib directories"
mkdir -p ~/Library/texmf/bibtex/bib
mkdir -p ~/Library/texmf/bibtex/bst
mkdir -p ~/Library/texmf/tex/latex
