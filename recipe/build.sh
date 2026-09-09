#!/usr/bin/env bash
set -ex

OSX_ARGS=""
if [[ $target_platform == "osx-"* ]]; then
  # the following do not build on macOS
  # wall is already on macOS
  # uuid conflicts with ossp-uuid
  OSX_ARGS="--disable-ipcs \
            --disable-ipcrm \
            --disable-wall \
            --disable-libmount \
            --enable-libuuid"
fi

# https://kernelnewbies.org/Linux_4.10
# https://elixir.bootlin.com/linux/v4.10.17/source/include/uapi/linux/sockios.h
export CPPFLAGS="${CPPFLAGS} -DSIOCGSKNS=0x894C"

./configure --prefix="${PREFIX}" \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-uuidd      \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-static     \
            --without-systemd    \
            --disable-makeinstall-chown \
            --disable-makeinstall-setuid \
            --without-systemdsystemunitdir \
            ${OSX_ARGS}
make -j${CPU_COUNT}

known_fail="TS_OPT_misc_setarch_known_fail=yes"
known_fail+=" TS_OPT_column_invalid_multibyte_known_fail=yes"
known_fail+=" TS_OPT_hardlink_options_known_fail=yes"  # flaky on py3.9?
known_fail+=" TS_OPT_uuid_oids_known_fail=yes"
# stale libuuid.so.1 in build-time library path lacks the UUID_2.41
# symbol version exported by the freshly-built lib, since these tests
# run before `make install`; ELF symbol versioning makes this Linux-only
known_fail+=" TS_OPT_uuidgen_oids_known_fail=yes"
known_fail+=" TS_OPT_uuidgen_uuidgen_known_fail=yes"
known_fail+=" TS_OPT_uuidparse_time_known_fail=yes"
known_fail+=" TS_OPT_uuidparse_uuidparse_known_fail=yes"

if [[ $target_platform == linux-aarch64 ]]; then
  known_fail+=" TS_OPT_lsfd_mkfds_ro_regular_file_known_fail=yes"  # can be flaky on this platform
  known_fail+=" TS_OPT_libmount_tabfiles_py_known_fail=yes"
  known_fail+=" TS_OPT_kill_name_to_number_known_fail=yes"
  known_fail+=" TS_OPT_kill_queue_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_directory_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_symlink_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_tcp6_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_mkfds_udp6_known_fail=yes"
  known_fail+=" TS_OPT_lsfd_option_inet_known_fail=yes"
  # script/options fails on pypy + aarch64 under emulation
  known_fail+=" TS_OPT_script_options_known_fail=yes"
  known_fail+=" TS_OPT_fincore_count_known_fail=yes"
fi

if [[ $target_platform != osx-* ]]; then
  make check $known_fail
fi

make install