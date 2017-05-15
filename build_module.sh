#!/bin/bash
# vim: ts=4 sw=4 expandtab
#
# Author: Feras Daoud <ferasda@mellanox.com>
#

ex()
{
    if ! eval "$@"; then
        echo "Failed to execute: $@" >&2
        exit 1
    fi
}

tmpdir=`mktemp -d /tmp/nv.XXXXXX`
if [ ! -d "$tmpdir" ]; then
    echo "Failed to create a temp directory!" >&2
    exit 1
fi

dirname=`basename "$PWD"`
VERSION=`grep Version: *.spec | cut -d : -f 2 | sed -e 's@\s@@g'`
RELEASE=`grep "define _release" *.spec | cut -d" " -f"4"| sed -r -e 's/}//'`
if [ "X$VERSION" == "X" ] || [ "X$RELEASE" == "X" ]; then
    echo "Failed to get version numbers!" >&2
    exit 1
fi

ex cp -r . $tmpdir/nvidia_peer_memory-$VERSION
pushd $tmpdir > /dev/null
ex tar czf nvidia_peer_memory-$VERSION.tar.gz nvidia_peer_memory-$VERSION --exclude=.* --exclude=build_release.sh
popd > /dev/null

echo
echo "Building source rpm for nvidia_peer_memory..."
mkdir -p $tmpdir/topdir/{SRPMS,RPMS,SPECS,BUILD}
ex "rpmbuild -ts --nodeps --define '_topdir $tmpdir/topdir' --define 'dist %{nil}' --define '_source_filedigest_algorithm md5' --define '_binary_filedigest_algorithm md5' $tmpdir/nvidia_peer_memory-$VERSION.tar.gz >/dev/null"
srpm=`ls -1 $tmpdir/topdir/SRPMS/`
mv $tmpdir/topdir/SRPMS/$srpm /tmp

echo "Building debian tarball for nvidia-peer-memory..."
ex mv $tmpdir/nvidia_peer_memory-$VERSION $tmpdir/nvidia-peer-memory-$VERSION
# update version in changelog
sed -i -r "0,/^(.*) \(([a-zA-Z0-9.-]+)\) (.*)/s//\1 \(${VERSION}-${RELEASE}\) \3/" $tmpdir/nvidia-peer-memory-${VERSION}/debian/changelog
pushd $tmpdir > /dev/null
ex tar czf nvidia-peer-memory_$VERSION.orig.tar.gz nvidia-peer-memory-$VERSION --exclude=.* --exclude=build_release.sh
ex mv nvidia-peer-memory_$VERSION.orig.tar.gz /tmp
popd > /dev/null

/bin/rm -rf $tmpdir

echo ""
echo Built: /tmp/$srpm
echo Built: /tmp/nvidia-peer-memory_$VERSION.orig.tar.gz
echo ""
echo "To install run on RPM based OS:"
echo "    # rpmbuild --rebuild /tmp/$srpm"
echo "    # rpm -ivh <path to generated binary rpm file>" 
echo ""
echo "To install on DEB based OS:"
echo "    # cd /tmp"
echo "    # tar xzf /tmp/nvidia-peer-memory_$VERSION.orig.tar.gz"
echo "    # cd nvidia-peer-memory-$VERSION"
echo "    # dpkg-buildpackage -us -uc"
echo "    # dpkg -i <path to generated deb files>"
echo ""
