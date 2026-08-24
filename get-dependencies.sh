#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	cmake         \
	fmt           \
	libzip        \
	nlohmann-json \
	sdl2          \
	spdlog        \
	tinyxml2

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

make-aur-package zenity-rs-bin

echo "Making stable build of Starship..."
echo "---------------------------------------------------------------"
REPO=https://github.com/HarbourMasters/Starship
TAG=$(git ls-remote --tags --refs --sort=-v:refname "$REPO" | awk -F/ '{print $NF; exit}')
git clone --branch "$TAG" --single-branch --recursive --depth 1 "$REPO" ./Starship && (
	cd ./Starship

	patch -Np1 -i ../patches/starship-stack-underflow-guard.patch
	patch -Np1 -i ../patches/starship-non-portable-fix.patch
	patch -Np1 -i ../patches/torch-src-dest-paths.patch
	sed -i 's/-mfpu=neon/-mcpu=native/' CMakeLists.txt

	cmake ./ -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON
	cmake --build build --config Release -j$(nproc)
	cmake --build build --config Release --target GeneratePortO2R -j$(nproc)
	echo "${TAG#v}" > ~/version
)

mkdir -p ./AppDir/bin
for a in assets Starship config.yml starship.o2r; do
	mv -v ./Starship/build/"$a" ./AppDir/bin
done
wget -O ./AppDir/bin/gamecontrollerdb.txt https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/master/gamecontrollerdb.txt
