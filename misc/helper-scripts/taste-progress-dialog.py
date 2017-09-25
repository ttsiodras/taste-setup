#!/usr/bin/env python

from __future__ import print_function
import sys
import time
import signal
import os
from collections import deque

import PySide
from PySide import QtGui
from PySide.QtCore import QThread, Signal, QObject, Qt, Slot

from PySide.QtGui import (QApplication,
                          QMessageBox,
                          QDialog,
                          QPushButton,
                          QProgressDialog)

log = deque()




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
                log.append(text)
                try:
                    if split[0] == '@ERROR@':
                        self.error.emit()
                        return
                except IndexError:
                    pass

class MyDialog(QDialog):
    def __init__(self):
        super(MyDialog, self).__init__()
        self.bar         = QtGui.QProgressBar()
        self.more_button = QtGui.QPushButton("Details")
        self.extension   = QtGui.QWidget()
        self.log_window  = QtGui.QListWidget()
        self.label       = QtGui.QLabel()

        # Layouts
        self.top_layout  = QtGui.QVBoxLayout()
        self.ext_layout  = QtGui.QVBoxLayout()
        self.main_layout = QtGui.QVBoxLayout()

        self.more_button.setCheckable(True)
        self.more_button.hide()
        self.more_button.toggled.connect(self.log_window.setVisible)

        self.top_layout.addWidget(self.label)
        self.top_layout.addWidget(self.bar)
        #self.top_layout.addWidget(self.more_button)
        self.top_layout.setStretch(0, 0)
        self.top_layout.setStretch(1, 0)
        self.top_layout.setStretch(2, 1)
        self.main_layout.addLayout(self.top_layout)
        self.main_layout.addWidget(self.log_window)
        self.setLayout(self.main_layout)
        self.main_layout.setStretch(2, 1)
        self.setWindowTitle("TASTE")
        self.extension.hide()
        self.log_window.hide()

        self.done = False

    @Slot()
    def complete_or_cancel(self):
        self.done = True

    def closeEvent(self, e):
        if not self.done:
            e.ignore()


def handle_error():
    print("== An error occured, here is the log ==")
    print("\n".join(log))


def run_gui():
    app       = QApplication(sys.argv)
    thread    = MyThread()
    dialog    = MyDialog()
    progress  = dialog.bar

    progress.setValue(0)

    thread.text.connect     (dialog.label.setText)
    thread.end.connect      (dialog.complete_or_cancel)
    thread.end.connect      (dialog.close)
    thread.progress.connect (progress.setValue)
    thread.error.connect    (handle_error)

    thread.start()
    dialog.exec_()

    thread.wait()

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    run_gui()

if __name__ == '__main__':
    main()

