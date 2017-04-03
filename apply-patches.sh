#!/bin/bash

env QUILT_PATCHES=patches QUILT_REFRESH_ARGS="-p ab --no-timestamps --no-index" quilt push -a

RESULT=$?

if [ $RESULT -eq 0 -o $RESULT -eq 2 ]; then
    exit 0
fi

exit 1

