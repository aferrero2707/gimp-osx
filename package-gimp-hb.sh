#!/bin/bash

instdir=$(pwd)/inst

export PATH="$HOME/homebrew/opt/jpeg-turbo:$HOME/homebrew/bin:$HOME/homebrew/opt/gettext/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/homebrew/opt/jpeg-turbo/lib:$HOME/homebrew/opt/gettext/lib:$HOME/homebrew/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/homebrew/opt/jpeg-turbo/lib/pkgconfig:$HOME/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
export ACLOCAL_PATH="$HOME/homebrew/share/aclocal:$ACLOCAL_PATH"
export ACLOCAL_FLAGS="-I $HOME/homebrew/share/aclocal -I $HOME/homebrew/Cellar/gettext/0.19.8.1/share/aclocal/"

export LD_LIBRARY_PATH="$HOME/homebrew/opt/libffi/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$HOME/homebrew/opt/libffi/lib/pkgconfig:$PKG_CONFIG_PATH"

export PATH="$instdir/bin:$PATH"
export LD_LIBRARY_PATH="$instdir/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$instdir/lib/pkgconfig:$instdir/share/pkgconfig:$PKG_CONFIG_PATH"

export LIBRARY_PATH="$LD_LIBRARY_PATH"


# transfer.sh
transfer() 
{ 
	if [ $# -eq 0 ]; then 
		echo "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; 		
		return 1; 
	fi
	tmpfile=$( mktemp -t transferXXX ); 
	if tty -s; then 
		basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); 
		curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; 
	else 
		curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; 
	fi; 
	cat $tmpfile; 
	rm -f $tmpfile; 
}

#long_version="$(date +%Y%m%d)"
#long_version="osx-$(date +%Y%m%d)-unstable"
#long_version="osx-$(date +%Y%m%d)_$(date +%H%M)-git-${TRAVIS_BRANCH}-${TRAVIS_COMMIT}"
#long_version="0.2.8"
gimpversion=$(pkg-config --modversion gimp-2.0)
gimpmajor=$(echo $gimpversion | cut -d"." -f 1)
gimpminor=$(echo $gimpversion | cut -d"." -f 2)
gimpmicro=$(echo $gimpversion | cut -d"." -f 3)
long_version=osx-git-$(pkg-config --modversion gimp-2.0)-$(date +%Y%m%d)
version=${long_version}
year=$(cd build/gimp && git log -1 --date=short --format=%cd origin/master | cut -d"-" -f 1)

echo "long version: $long_version"
echo "year: $year"

#exit

#cp ../../Icon/photoflow.png Icon1024.png
#bash make_icon.sh

# photoflow.bundle writes here
bdir=$HOME/Scratch/GIMP
rm -rf $bdir
mkdir -p $bdir
dst=$bdir/GIMP.app
dst_prefix=$dst/Contents/Resources

# jhbuild installs to here
src=$(pwd)/inst
src2=$HOME/homebrew
#src=/usr/local

wd=$(pwd)

function escape () {
        # escape slashes
	tmp=${1//\//\\\/}

	# escape colon
	tmp=${tmp//\:/\\:}

	# escape tilda
	tmp=${tmp//\~/\\~}

	# escape percent
	tmp=${tmp//\%/\\%}

	echo -n $tmp
}

function new () {
	echo > script.sed
}

function sub () {
        echo -n s/ >> script.sed
	escape "$1" >> script.sed
	echo -n / >> script.sed
	escape "$2" >> script.sed
	echo /g >> script.sed
}

function patch () {
	echo patching "$1"

	sed -f script.sed -i "" "$1"
}

cp Info.plist.in Info.plist
new
sub @LONG_VERSION@ "$long_version"
sub @VERSION@ "$version"
sub @GIMP_MAJOR_VERSION@ "$gimpmajor"
sub @GIMP_MINOR_VERSION@ "$gimpminor"
sub @GIMP_MICRO_VERSION@ "$gimpmicro"
sub @GIMP_GIT_LAST_COMMIT_YEAR@ "$year"
sub @MACOSX_DEPLOYMENT_TARGET@ "10.8"
patch Info.plist

#exit

rm -rf $dst 
rm -rf $bdir/gimp-$version.app

mkdir -p $bdir/tools && cd $bdir/tools

cd $bdir/tools
rm -rf macdylibbundler
git clone https://github.com/aferrero2707/macdylibbundler.git
cd macdylibbundler
make

cd $wd

mkdir -p $dst_prefix/bin
cp -a $src/bin/gimp* $dst_prefix/bin
echo "Fixing dependencies of \"$dst_prefix/bin\""
$bdir/tools/macdylibbundler/dylibbundler -od -of -b -x $dst_prefix/bin/gimp -d $dst_prefix/lib -p @executable_path/../lib > $bdir/dylibbundler.log
cp -a $src/share $src/etc $dst_prefix
cp -a $src2/share $src2/etc $dst_prefix

#exit

gdk_pixbuf_src_moduledir=$(pkg-config --variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0)
gdk_pixbuf_dst_moduledir=$dst_prefix/lib/gdk-pixbuf-2.0/loaders
mkdir -p $gdk_pixbuf_dst_moduledir
echo "Copying \"$gdk_pixbuf_src_moduledir\"/* to \"$gdk_pixbuf_dst_moduledir\""
cp -L "$gdk_pixbuf_src_moduledir"/* "$gdk_pixbuf_dst_moduledir"

gdk_pixbuf_src_cache_file=$(pkg-config --variable=gdk_pixbuf_cache_file gdk-pixbuf-2.0)
gdk_pixbuf_dst_cache_file=$dst_prefix/lib/gdk-pixbuf-2.0/loaders.cache
mkdir -p $(dirname "$gdk_pixbuf_dst_cache_file")
echo "Copying \"$gdk_pixbuf_src_cache_file\" to \"$gdk_pixbuf_dst_cache_file\""
cp -L "$gdk_pixbuf_src_cache_file" "$gdk_pixbuf_dst_cache_file"
sed -i -e "s|$gdk_pixbuf_src_moduledir|@executable_path/../lib/gdk-pixbuf-2.0/loaders|g" "$gdk_pixbuf_dst_cache_file"

for l in "$gdk_pixbuf_dst_moduledir"/*.so; do
  echo "Fixing dependencies of \"$l\""
  chmod u+w "$l"
  $bdir/tools/macdylibbundler/dylibbundler -of -b -x "$l" -d $dst_prefix/lib -p @loader_path/../lib > /dev/null
done


gtk_version=$(pkg-config --variable=gtk_binary_version gtk+-2.0)
gtk_engines_src_pixmap="$src2/lib/gtk-2.0/${gtk_version}/engines/libpixmap.so"
gtk_engines_dst_dir="$dst_prefix/lib/gtk-2.0/engines"
mkdir -p "$gtk_engines_dst_dir"
cp -L "$gtk_engines_src_pixmap" "$gtk_engines_dst_dir"
for l in "$gtk_engines_dst_dir"/*.so; do
  echo "Fixing dependencies of \"$l\""
  chmod u+w "$l"
  $bdir/tools/macdylibbundler/dylibbundler -of -b -x "$l" -d $dst_prefix/lib -p @loader_path/../lib > /dev/null
done


babl_src_dir=$(pkg-config --variable=libdir babl)
babl_dst_dir="$dst_prefix/lib"
cp -a "$babl_src_dir/babl-0.1" "$babl_dst_dir"
for l in "$babl_dst_dir/babl-0.1"/*.so; do
  echo "Fixing dependencies of \"$l\""
  chmod u+w "$l"
  $bdir/tools/macdylibbundler/dylibbundler -of -b -x "$l" -d $dst_prefix/lib -p @loader_path/../lib > /dev/null
done

gegl_src_dir=$(pkg-config --variable=pluginsdir gegl-0.4)
gegl_dst_dir="$dst_prefix/lib"
cp -a "$gegl_src_dir" "$gegl_dst_dir"
for l in "$gegl_dst_dir/gegl-0.4"/*.so; do
  echo "Fixing dependencies of \"$l\""
  chmod u+w "$l"
  $bdir/tools/macdylibbundler/dylibbundler -of -b -x "$l" -d $dst_prefix/lib -p @loader_path/../lib > /dev/null
done


#for l in "$dst_prefix/lib"/*.dylib; do
#  echo "Fixing dependencies of \"$l\""
#  chmod u+w "$l"
#  $bdir/tools/macdylibbundler/dylibbundler -of -b -x "$l" -d $dst_prefix/lib -p @loader_path/../lib > /dev/null
#done


#$src/bin/gdk-pixbuf-query-loaders > $dst_prefix/etc/gtk-2.0/gdk-pixbuf.loaders
#sed -i -e "s|$src/|././/|g'

mkdir -p $dst/Contents/MacOS
cp -a launcher.sh $dst/Contents/MacOS/gimp
cp Info.plist $dst/Contents
cp *.icns $dst_prefix

#exit

echo "Entering \"$bdir\""
cd $bdir
ls
#echo "zip -r $HOME/photoflow-${version}.zip photoflow.app"
#zip -r $HOME/photoflow-${version}.zip photoflow.app

#ls -lh $HOME/photoflow-${version}.zip
#echo "transfer $HOME/photoflow-${version}.zip"
#transfer $HOME/photoflow-${version}.zip

#exit

#cp $src/lib/pango/1.8.0/modules.cache $dst_prefix/lib/pango/1.8.0
#new
#sub "$src/lib/pango/1.8.0/modules/" ""
#patch $dst_prefix/lib/pango/1.8.0/modules.cache

#rm $dst_prefix/etc/fonts/conf.d/*.conf
#( cd $dst_prefix/etc/fonts/conf.d ; \
#	ln -s ../../../share/fontconfig/conf.avail/*.conf . )

# we can't copy the IM share with photoflow.bundle because it drops the directory
# name, annoyingly
#cp -r $src/share/ImageMagick-* $dst_prefix/share

#cp ~/PhotoFlow/vips/transform-7.30/resample.plg $dst_prefix/lib

#mv $dst ~/Desktop/PhotoFlow/photoflow-$version.app

#echo built ~/Desktop/PhotoFlow/photoflow.app

cd $bdir
rm -rf tools *.log
ln -s /Applications .
#touch .Trash

echo "Building .dmg"
rm -f $HOME/gimp-$version.dmg
size_MB=$(du -ms GIMP.app | cut -f 1)
size_MB=$((size_MB+100))
echo "hdiutil create -megabytes ${size_MB} -srcfolder $bdir -o $HOME/gimp-$version.dmg"
hdiutil create -megabytes ${size_MB} -verbose -srcfolder $bdir -o $HOME/gimp-${version}.dmg
echo built $HOME/gimp-${version}.dmg
ls -lh $HOME/gimp-${version}.dmg
transfer $HOME/gimp-${version}.dmg