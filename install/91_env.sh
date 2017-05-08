#!/bin/bash
grep ASSERT_IGNORE_PYTHON_ERRORS $HOME/.bashrc.taste >/dev/null || {
    echo "export ASSERT_IGNORE_PYTHON_ERRORS=1" >> $HOME/.bashrc.taste
}
