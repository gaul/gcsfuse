#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail
set -x

function wait_for_port() {
    PORT=$1
    for i in $(seq 30); do
        if exec 3<>"/dev/tcp/127.0.0.1/${PORT}"; then
            exec 3<&-  # Close for read
            exec 3>&-  # Close for write
            return 0
        fi
        sleep 1
    done
    return 1
}

FAKE_GCS_SERVER_ROOT="/tmp/fake-gcs-server"
rm -rf $FAKE_GCS_SERVER_ROOT
mkdir $FAKE_GCS_SERVER_ROOT
mkdir $FAKE_GCS_SERVER_ROOT/container
# TODO: better path
$HOME/work/fake-gcs-server/fake-gcs-server -filesystem-root $FAKE_GCS_SERVER_ROOT -scheme http &
FAKE_GCS_SERVER_PID=$?
# TODO: why doesn't this work?
#wait_for_port 4443
sleep 1

GCS_MOUNTPOINT="/tmp/mnt/"
rm -rf $GCS_MOUNTPOINT
mkdir $GCS_MOUNTPOINT
./gcsfuse -endpoint http://127.0.0.1:4443 --foreground container $GCS_MOUNTPOINT &

# TODO: better path
#(cd $GCS_MOUNTPOINT && prove -rv $HOME/work/pjdfstest/tests/) || echo done
# TODO: remove
(cd $GCS_MOUNTPOINT && prove -rv $HOME/work/pjdfstest/tests/truncate/02.t) || echo done
#(cd $GCS_MOUNTPOINT && prove -rv $HOME/work/pjdfstest/tests/mkdir/02.t) || echo done
#(cd $GCS_MOUNTPOINT && prove -rv $HOME/work/pjdfstest/tests/utimensat/) || echo done

fusermount -u $GCS_MOUNTPOINT
kill $FAKE_GCS_SERVER_PID
rm -rf $FAKE_GCS_SERVER_ROOT
