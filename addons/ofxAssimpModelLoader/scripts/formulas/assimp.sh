#! /bin/bash
#
# Open Asset Import Library
# cross platform 3D model loader
# https://github.com/assimp/assimp
#
# uses CMake

# define the version
VER=3.1.1

# tools for git use
GIT_URL=
# GIT_URL=https://github.com/assimp/assimp.git
GIT_TAG=

FORMULA_TYPES=( "osx" "osx-clang-libc++" )

# download the source code and unpack it into LIB_NAME
function download() {

	# stable release from source forge
	curl -LO "https://github.com/assimp/assimp/archive/v$VER.zip"
	unzip -oq "v$VER.zip"
	mv "assimp-$VER" assimp
	rm "v$VER.zip"

	if [ "$OS" == "osx" ] ; then
		
		chmod +x assimp/port/iOS/build.sh

		# make a backup of the build script
		cp assimp/port/iOS/build.sh assimp/port/iOS/build.sh.orig
	fi

    # fix an issue with static libs being disabled - see issue https://github.com/assimp/assimp/issues/271
    # this could be fixed fairly soon - so see if its needed for future releases.
    sed -i -e 's/SET ( ASSIMP_BUILD_STATIC_LIB OFF/SET ( ASSIMP_BUILD_STATIC_LIB ON/g' assimp/CMakeLists.txt
    sed -i -e 's/option ( BUILD_SHARED_LIBS "Build a shared version of the library" ON )/option ( BUILD_SHARED_LIBS "Build a shared version of the library" OFF )/g' assimp/CMakeLists.txt
}

# prepare the build environment, executed inside the lib src dir
function prepare() {

	if [ "$TYPE" == "ios" ] ; then
		# ref: http://stackoverflow.com/questions/6691927/how-to-build-assimp-library-for-ios-device-and-simulator-with-boost-library

		# this is basically updating an old build system with correct xcode paths
		# and armv7s instead of armv6, hopefully the assimp project fixes this
		# in the future ...

		cd port/iOS
		cp build.sh.orig build.sh

		# convert the armv6 toolchain to armv7s, the output will say "arm6"
		# but the arch will build for armv7s
		sed -i .tmp "s|CMAKE_SYSTEM_PROCESSOR.*\"armv6\"|CMAKE_SYSTEM_PROCESSOR \"armv7s\"|" IPHONEOS_ARM6_TOOLCHAIN.cmake
		sed -i .tmp "s|armv6|armv7s|" build.sh

		# set SDK and update xcode dev root
		for toolchain in $( ls -1 *.cmake) ; do
			sed -i .tmp \
				-e "s|SDKVER.*\"5.0\"|SDKVER	\"$IOS_SDK_VER\"|" \
				-e "s|\"/Developer|\"$XCODE_DEV_ROOT|" $toolchain
		done
		sed -i .tmp \
			-e "s|IOS_BASE_SDK=.*|IOS_BASE_SDK=\"$IOS_SDK_VER\"|" \
			-e "s|IOS_DEPLOY_TGT=.*|IOS_DEPLOY_TGT=\"$IOS_MIN_SDK_VER\"|" \
			-e "s|=/Developer|=$XCODE_DEV_ROOT|" build.sh

		# fix bad lipo line (due to switch to armv7s)
		sed -i .tmp 's|lipo.*|lipo -c $lib_arm6 $lib_arm7 $lib_i386 -o $lib|' build.sh

		# fix old var names (missing ASSIMP_ prefix), keep this commented for now
		# bleeding edge assimp on git uses the ASSIMP_ prefix, so this may need to updated in the future
		#sed -i .tmp "s|-DENABLE_BOOST_WORKAROUND=|-DASSIMP_ENABLE_BOOST_WORKAROUND=|" build.sh
		#sed -i .tmp "s|-DBUILD_STATIC_LIB=|-DASSIMP_BUILD_STATIC_LIB=|" build.sh

	fi

	if [ "$TYPE" == "osx" ] ; then

		# warning, assimp on github uses the ASSIMP_ prefix for CMake options ...
		# these may need to be updated for a new release
		local buildOpts="--build build/$TYPE -DASSIMP_BUILD_STATIC_LIB=1 -DASSIMP_BUILD_SHARED_LIB=0 -DASSIMP_ENABLE_BOOST_WORKAROUND=1"

		# 32 bit
		cmake -G 'Unix Makefiles' $buildOpts -DCMAKE_C_FLAGS="-arch i386 -O3 -DNDEBUG -funroll-loops" -DCMAKE_CXX_FLAGS="-arch i386 -stdlib=libstdc++ -O3 -DNDEBUG -funroll-loops" .
		make assimp
		mv lib/libassimp.a lib/libassimp-i386.a
		make clean

		# 64 bit
		cmake -G 'Unix Makefiles' $buildOpts -DCMAKE_C_FLAGS="-arch x86_64 -O3 -DNDEBUG -funroll-loops" -DCMAKE_CXX_FLAGS="-arch x86_64 -stdlib=libc++ -O3 -DNDEBUG -funroll-loops" .
		make assimp 
		mv lib/libassimp.a lib/libassimp-x86_64.a
		make clean

		# link into universal lib
		lipo -c lib/libassimp-i386.a lib/libassimp-x86_64.a -o lib/libassimp.a

	elif [ "$TYPE" == "osx-clang-libc++" ] ; then
		echoWarning "WARNING: this needs to be updated"

		# warning, assimp on github uses the ASSIMP_ prefix for CMake options ...
		# these may need to be updated for a new release
		local buildOpts="--build build/$TYPE"

		export CPP=`xcrun -find clang++`
		export CXX=`xcrun -find clang++`
		export CXXCPP=`xcrun -find clang++`
		export CC=`xcrun -find clang`
		
		# 32 bit
		cmake -G 'Unix Makefiles' $buildOpts -DCMAKE_C_FLAGS="-arch i386 $assimp_flags" -DCMAKE_CXX_FLAGS="-arch i386 -std=c++11 -stdlib=libc++ $assimp_flags" .
		make assimp -j 
		mv lib/libassimp.a lib/libassimp-i386.a
		make clean

		# rename lib
		libtool -c lib/libassimp-i386.a -o lib/libassimp.a

	elif [ "$TYPE" == "linux" ] ; then
		echoWarning "TODO: linux build"

	elif [ "$TYPE" == "linux64" ] ; then
		echoWarning "TODO: linux64 build"

	elif [ "$TYPE" == "vs" ] ; then
		echoWarning "TODO: vs build"

	elif [ "$TYPE" == "win_cb" ] ; then
		echoWarning "TODO: win_cb build"

	elif [ "$TYPE" == "ios" ] ; then
		./build.sh
	
	elif [ "$TYPE" == "android" ] ; then
		echoWarning "TODO: android build"
	fi
}

# executed inside the lib src dir, first arg $1 is the dest libs dir root
function copy() {

	# headers
	mkdir -p $1/include
    rm -r $1/include/assimp || true
    rm -r $1/include/* || true
	cp -Rv include/* $1/include

	# libs
	mkdir -p $1/lib/$TYPE
	if [ "$TYPE" == "vs" ] ; then
		cp -Rv lib/libassimp.lib $1/lib/$TYPE/assimp.lib

	elif [ "$TYPE" == "ios" ] ; then
		cp -Rv lib/ios/libassimp.a $1/lib/$TYPE/assimp.a

	else 
		cp -Rv lib/libassimp.a $1/lib/$TYPE/assimp.a
	fi
}

# executed inside the lib src dir
function clean() {

	if [ "$TYPE" == "vs" ] ; then
		echoWarning "TODO: clean vs"

	elif [ "$TYPE" == "vs" ] ; then
		echoWarning "TODO: clean android"

	else
		make clean
		rm -f CMakeCache.txt
	fi
}
