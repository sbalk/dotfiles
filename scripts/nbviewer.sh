#!/bin/bash

nbviewer() {
    if [ $# -eq 0 ]; then
        echo "No arguments specified. Usage: nbviewer /tmp/test.ipynb OR cat /tmp/test.ipynb | nbviewer test.ipynb"
        return 1
    fi

    tmpfile=$(mktemp -t transferXXX)
    upload-file "$1" >> $tmpfile
    cat $tmpfile | sed 's@https://@https://nbviewer.jupyter.org/urls/@g'
    rm -f $tmpfile
}

nbviewer "$@"
