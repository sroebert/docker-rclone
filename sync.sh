#!/bin/sh

set -e

echo "INFO: Starting sync.sh pid $$ $(date)"

# Delete logs by user request
if [ ! -z "${ROTATE_LOG##*[!0-9]*}" ]
then
  echo "INFO: Removing logs older than $ROTATE_LOG day(s)..."
  touch /logs/tmp.txt && find /logs/*.txt -mtime +$ROTATE_LOG -type f -delete && rm -f /logs/tmp.txt
fi

if [ `lsof | grep $0 | wc -l | tr -d ' '` -gt 1 ]
then
  echo "WARNING: A previous $RCLONE_CMD is still running. Skipping new $RCLONE_CMD command."
else

  echo $$ > /tmp/sync.pid

  if [ ! -z "$SYNC_OPTS_EVAL" ]
  then
    SYNC_OPTS_EVALUALTED=$(eval echo $SYNC_OPTS_EVAL)
    echo "INFO: Evaluated SYNC_OPTS_EVAL to: ${SYNC_OPTS_EVALUALTED}"
    SYNC_OPTS_ALL="${SYNC_OPTS} ${SYNC_OPTS_EVALUALTED}"
  else
    SYNC_OPTS_ALL="${SYNC_OPTS}"
  fi

  if [ ! -z "$RCLONE_DIR_CHECK_SKIP" ]
  then
    echo "INFO: Skipping source directory check..."
    if [ ! -z "$OUTPUT_LOG" ]
    then
      d=$(date +%Y_%m_%d-%H_%M_%S)
      LOG_FILE="/logs/$d.txt"
      echo "INFO: Log file output to $LOG_FILE"
      if [ ! -z "$CHECK_URL" ]
      then
        echo "INFO: Sending start signal to healthchecks.io"
        wget $CHECK_URL/start -O /dev/null
      fi
      echo "INFO: Starting rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL --log-file=${LOG_FILE}"
      eval rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL --log-file=${LOG_FILE}
      export RETURN_CODE=$?
    else
      if [ ! -z "$CHECK_URL" ]
      then
        echo "INFO: Sending start signal to healthchecks.io"
        wget $CHECK_URL/start -O /dev/null
      fi
      echo "INFO: Starting rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL"
      eval rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL
      export RETURN_CODE=$?
    fi
  else
    if test "$(rclone $RCLONE_DIR_CMD $SYNC_SRC $RCLONE_OPTS --copy-links)"; then
    echo "INFO: Source directory is not empty and can be processed without clear loss of data"
    if [ ! -z "$OUTPUT_LOG" ]
    then
      d=$(date +%Y_%m_%d-%H_%M_%S)
      LOG_FILE="/logs/$d.txt"
      echo "INFO: Log file output to $LOG_FILE"
      if [ ! -z "$CHECK_URL" ]
      then
        echo "INFO: Sending start signal to healthchecks.io"
        wget $CHECK_URL/start -O /dev/null
      fi
      echo "INFO: Starting rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL --log-file=${LOG_FILE}"
      eval rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL --log-file=${LOG_FILE}
      export RETURN_CODE=$?
    else
      echo "INFO: Starting rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL"
      if [ ! -z "$CHECK_URL" ]
      then
        echo "INFO: Sending start signal to healthchecks.io"
        wget $CHECK_URL/start -O /dev/null
      fi
      eval rclone $RCLONE_CMD $SYNC_SRC $SYNC_DEST $RCLONE_OPTS $SYNC_OPTS_ALL
      export RETURN_CODE=$?
    fi
      if [ -z "$CHECK_URL" ]
      then
        echo "INFO: Define CHECK_URL with https://healthchecks.io to monitor $RCLONE_CMD job"
      else
        if [ "$RETURN_CODE" == 0 ]
        then
          echo "INFO: Seding complete signal to healthchecks.io"
          wget $CHECK_URL -O /dev/null
        else
          echo "INFO: Seding failure signal to healthchecks.io"
          wget $FAIL_URL -O /dev/null
        fi
      fi
    else
      echo "WARNING: Source directory is empty. Skipping $RCLONE_CMD command."
    fi
  fi

rm -f /tmp/sync.pid

fi
