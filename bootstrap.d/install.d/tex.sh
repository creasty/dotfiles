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
(
  cd $TEXLIVE_PATH/2015/texmf-dist/scripts/cjk-gs-integrate
  sudo perl cjk-gs-integrate.pl --link-texmf --force
  sudo mktexlsr
  sudo updmap-sys --setoption kanjiEmbed hiragino-elcapitan-pron
)

subsection "Make bst/bib directories"
mkdir -p ~/Library/texmf/bibtex/bib
mkdir -p ~/Library/texmf/bibtex/bst
mkdir -p ~/Library/texmf/tex/latex
