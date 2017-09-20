#!/usr/bin/env python

import sys
import time
import signal
from collections import deque

import PySide
from PySide.QtCore import QThread, Signal, QObject

from PySide.QtGui import (QApplication,
                          QMessageBox,
                          QProgressDialog)

class MyThread(QThread, QObject):
    ''' Thread waiting for data on stdin and sending signals to the prgress
    bar in case something came in.
    Text can be formatted:
      * if the line starts with a number, it will use the value (range 0..100)
        to update the progress bar, and it will display the text above the bar.
      * if the line starts with @ERROR@ the process will stop and all the
        history will be dispayed in a log dialog.
      * in all other cases, the line is appended to the log
    '''
    text       = Signal(str)
    progress   = Signal(int)
    end        = Signal()
    error      = Signal()
    log        = deque()
    force_quit = False

    def run(self):
        value = 10
        while True:
            # read from stdin without any buffering
            if self.force_quit:
                return
            line = sys.stdin.readline()
            if len(line) == 0:
                print("Bye")
                self.end.emit()
                return
            else:
                split = line.split()
                try:
                    # check for format "NUMBER text"
                    possible_val = split[0]
                    value = int(possible_val)
                    if 100 < value < 0:
                        raise ValueError
                    text = ' '.join(split[1:])
                    self.progress.emit(value)
                    self.text.emit(text)
                    if value == 100:
                        self.end.emit()
                        return
                except (ValueError, IndexError):
                    text = line
                self.log.append(text)
                try:
                    if split[0] == '@ERROR@':
                        self.error.emit()
                except IndexError:
                    pass



def run_gui():
    app      = QApplication(sys.argv)
    thread   = MyThread()
    progress = QProgressDialog()
    progress.setValue(0)
    progress.setAutoClose(True)

    thread.text.connect     (progress.setLabelText)
    thread.end.connect      (progress.cancel)
    thread.progress.connect (progress.setValue)
    thread.setTerminationEnabled(True)

    thread.start()
    progress.exec_()
    if progress.wasCanceled:
        print 'Cancel was pressed'
        thread.force_quit = True
    thread.wait()
    print "end"

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    run_gui()

if __name__ == '__main__':
    main()

