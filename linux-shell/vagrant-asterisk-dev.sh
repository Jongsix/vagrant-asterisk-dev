echo "Installing Dev Tools"

mkdir -p ~/.vim/autoload ~/.vim/bundle
if [ ! -f ~/.vim/autoload/pathogen.vim ]; then
    curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi
if [ ! -d ~/.vim/bundle/syntastic ]; then
    git clone https://github.com/scrooloose/syntastic.git  ~/.vim/bundle/syntastic
fi
if [ ! -d ~/.vim/bundle/vim-go ]; then
    git clone https://github.com/fatih/vim-go.git ~/.vim/bundle/vim-go
fi
if [ ! -d ~/.vim/bundle/vim-multiple-cursors ]; then
    git clone git://github.com/terryma/vim-multiple-cursors.git ~/.vim/bundle/vim-multiple-cursors
fi

if [ ! -d ~/.vim/bundle/vim-smarttabs ]; then
    git clone https://github.com/dpc/vim-smarttabs.git ~/.vim/bundle/vim-smarttabs
fi
cat <<EOF >~/.vimrc
call pathogen#infect()
filetype off
syntax on
filetype plugin indent on

set paste
set number
set relativenumber
set backspace=indent,eol,start

noremap <silent> <expr> j (v:count == 0 ? 'gj' : 'j')
noremap <silent> <expr> k (v:count == 0 ? 'gk' : 'k')

map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:go_fmt_fail_silently = 1
let g:go_list_type = "quickfix"

let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_fields = 1
let g:go_highlight_structs = 1
let g:go_highlight_interfaces = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
EOF


echo "Installing Asterisk Development Environment"

sudo mkdir -p ~/dev/asterisk
cd $_
sudo chown -R vagrant ~/dev
sudo chmod -R 775 ~/dev/asterisk

sudo pip3 install git-review

mkdir -p ~/dev/asterisk/
cd ~/dev/asterisk/
git clone --progress https://gerrit.asterisk.org/testsuite

cd testsuite/asttest
make
sudo make install

cd ~/dev/asterisk/testsuite/addons
make update
cd starpy
sudo python setup.py install

echo "* Installing SIPp *"

cd ~/dev/asterisk/testsuite
wget https://github.com/SIPp/sipp/releases/download/v3.6.1/sipp-3.6.1.tar.gz 
tar -zxvf sipp-3.6.1.tar.gz
cd sipp-3.6.1
cmake . -DUSE_GSL=1 -DUSE_PCAP=1 -DUSE_SSL=1 -DUSE_SCTP=1
make -j4
sudo make install
rm -rf sipp-3.6.1*

echo "* Installing Asterisk *"

gerrituser=$(cat /tmp/gerritusername)
sudo chmod 600 /home/vagrant/.ssh/config 

cd ~/dev/asterisk
ssh -T $gerrituser@gerrit.asterisk.org  -p 29418 -o StrictHostKeyChecking=no
git clone --progress -b master ssh://$gerrituser@gerrit.asterisk.org:29418/asterisk asterisk

cd asterisk
ssh -T $gerrituser@gerrit.asterisk.org  -p 29418 -o StrictHostKeyChecking=no

git remote add gerrit ssh://$gerrituser@gerrit.asterisk.org:29418/asterisk.git
git review -s

./configure --with-pjproject-bundled  --enable-dev-mode
contrib/scripts/get_mp3_source.sh
make menuselect.makeopts

# Set our menuselect options
menuselect/menuselect --enable BETTER_BACKTRACES menuselect.makeopts
menuselect/menuselect --enable DONT_OPTIMIZE menuselect.makeopts
menuselect/menuselect --enable DO_CRASH menuselect.makeopts
menuselect/menuselect --enable TEST_FRAMEWORK menuselect.makeopts

make

sudo make install
sudo make samples
sudo make config

echo '/usr/lib' | sudo tee --append /etc/ld.so.conf.d/asterisk.conf > /dev/null
sudo ldconfig

echo "Development Environment Setup Complete"