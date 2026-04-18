#! /bin/bash

die () {
	local ERR_CODE=$1
	shift
	local MESSAGE=( "$@" )

	echo "${MESSAGE[@]}"
	exit "${ERR_CODE}"
}

GIT_ROOT=$(git rev-parse --show-toplevel)
[[ ${PWD} == "${GIT_ROOT}" ]] || die 1 \
		"The current path is: '${PWD}'" \
		$'\n' \
		"This script must be run in '${GIT_ROOT}'"

make distclean
find . -path "./upnp/generator" -prune -o -name Makefile -exec rm '{}' \;
find . -name '*.o' -exec rm '{}' \;

./bootstrap || die 2 "'bootstrap' failed"

#if false; then
	echo "debug, no openssl dynamic, no sanitizer:"
	./configure --enable-debug  --enable-shared --prefix="${HOME}"/usr/libupnp CFLAGS="-Wconversion -Wchar-subscripts -Wall -Wextra -Wpointer-arith -Wwrite-strings -Wformat-security -Wmissing-format-attribute"
#fi

if false; then
	echo "debug, no openssl static:"
	./configure --enable-debug  --disable-shared --prefix="${HOME}"/usr/libupnp CFLAGS="-Wconversion -Wchar-subscripts -Wall -Wextra -Wpointer-arith -Wwrite-strings -Wformat-security -Wmissing-format-attribute -fsanitize=address,leak" LDFLAGS="-fsanitize=address,leak"
fi

if false; then
	echo "debug, no openssl static, no leak sanitizer, for gdb debugging:"
	./configure --enable-debug  --disable-shared --prefix="${HOME}"/usr/libupnp CFLAGS="-Wconversion -Wchar-subscripts -Wall -Wextra -Wpointer-arith -Wwrite-strings -Wformat-security -Wmissing-format-attribute"
fi

if false; then
	echo "debug, with shared lib:"
	./configure --enable-debug  --enable-open_ssl --prefix="${HOME}"/usr/libupnp CFLAGS="-Wconversion -Wchar-subscripts -Wall -Wextra -Wpointer-arith -Wwrite-strings -Wformat-security -Wmissing-format-attribute -fsanitize=address,leak" LDFLAGS="-fsanitize=address,leak"
fi

if false; then
	echo "#no debug:"
	./configure --prefix="${HOME}"/usr/libupnp CFLAGS="-Wconversion -Wchar-subscripts -Wall -Wextra -Wpointer-arith -Wwrite-strings -Wformat-security -Wmissing-format-attribute"
fi

# shellcheck disable=SC2181
[[ $? == 0 ]] || die 3 "'configure' failed"

make clean > /dev/null || die 4 "'make clean' failed"
make -j8 > /dev/null || die 5 "'make' failed"
make check || die 6 "'make check' failed"
make install > /dev/null || die 7 "'make install' failed"

die 0 "success"

# if false; then
# 	echo "cmake build"
# 	rm -rf build
# 	cmake -DBUILD_TESTING=ON -DDOWNLOAD_AND_BUILD_DEPS=ON -DCMAKE_BUILD_TYPE=Debug -S . -B build
# 	cmake --build build
# 	cd build || exit 1
# 	ctest --output-on-failure
# fi

# exit
