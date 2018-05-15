#! /bin/bash

instdir=$(pwd)/inst

export PATH="$HOME/homebrew/opt/jpeg-turbo:$HOME/homebrew/bin:$HOME/homebrew/Cellar/gettext/0.19.8.1/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/homebrew/opt/jpeg-turbo/lib:$HOME/homebrew/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/homebrew/opt/jpeg-turbo/lib/pkgconfig:$HOME/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
export ACLOCAL_PATH="$HOME/homebrew/share/aclocal:$ACLOCAL_PATH"
export ACLOCAL_FLAGS="-I $HOME/homebrew/share/aclocal -I $HOME/homebrew/Cellar/gettext/0.19.8.1/share/aclocal/"

export LD_LIBRARY_PATH="$HOME/homebrew/Cellar/libffi/3.2.1/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/homebrew/Cellar/libffi/3.2.1/lib/pkgconfig:$PKG_CONFIG_PATH"

export LD_LIBRARY_PATH="$HOME/homebrew/Cellar/gegl/HEAD-34f217b/lib:$LD_LIBRARY_PATH"

export PATH="$instdir/bin:$PATH"
export LD_LIBRARY_PATH="$instdir/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$instdir/lib/pkgconfig:$instdir/share/pkgconfig:$PKG_CONFIG_PATH"
export GEGL_PATH="$instdir/lib/gegl-0.3"

lldb inst/bin/gimp