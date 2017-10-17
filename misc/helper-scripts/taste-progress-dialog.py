#!/usr/bin/env python

from __future__ import print_function
import sys
import time
import signal
import os
from collections import deque

import PySide
from PySide import QtGui
from PySide.QtCore import QThread, Signal, QObject, Qt, Slot, QTimer

from PySide.QtGui import (QApplication,
                          QMessageBox,
                          QDialog,
                          QPushButton,
                          QProgressDialog)

log = deque()


class MyThread(QThread, QObject):
    ''' Thread waiting for data on stdin and sending signals to the prgress
    bar in case something came in.
    To update the bar, the line shall start with either a range or a numer.
    e.g.
        0-50 Doing something     # The bar will progress from 0 to 49%
        70   Something else      # The bar will remain at 70%

    Without a number/range, the text is only appended to the log
    If the line starts with @ERROR@ the thread will stop
    '''
    text       = Signal(str)
    progress   = Signal(int, int)
    end        = Signal()
    error      = Signal()
    force_quit = False

    def update_bar(self, from_value, to_value, text):
        ''' Request an update of the progress bar (value/range and text) '''
        if 100 < from_value < 0 or 100 < to_value < 0:
            return
        self.progress.emit(from_value, to_value)
        self.text.emit(text)
        if from_value == 100:
            self.end.emit()
            self.force_quit = True

    def run(self):
        while True:
            # read from stdin without any buffering
            if self.force_quit:
                return
            line = sys.stdin.readline()
            if len(line) == 0:
                self.end.emit()
                return
            else:
                split = line.split(' ', 1)
                try:
                    # check for a range format (e.g. 10-20)
                    left, right = split[0].split('-')
                    from_v, to_v = int(left), int(right)
                    if from_v > to_v:
                        raise ValueError
                    if 100 < from_v < 0 or 100 < to_v < 0:
                        raise ValueError
                    text = split[1]
                    self.update_bar(from_v, to_v, text)
                except (ValueError, IndexError):
                    try:
                        # check for format "NUMBER text"
                        possible_val = split[0]
                        value = int(possible_val)
                        text = split[1]
                        self.update_bar(value, value, text)
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

    def periodic_update(self):
        self.current_value += 5
        if self.current_value >= self.target_value:
            self.current_value = self.target_value
        else:
            QTimer.singleShot(200, self.periodic_update)
        self.bar.setValue(self.current_value)

    @Slot(int, int)
    def reach_target(self, from_value, to_value):
        self.current_value = from_value
        self.target_value  = to_value
        self.bar.setValue(self.current_value)
        QTimer.singleShot(100, self.periodic_update)

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

    thread.text.connect      (dialog.label.setText)
    thread.end.connect       (dialog.complete_or_cancel)
    thread.end.connect       (dialog.close)
    thread.progress.connect  (dialog.reach_target)
    thread.error.connect     (handle_error)

    thread.start()
    dialog.exec_()

    thread.wait()

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    run_gui()

if __name__ == '__main__':
    main()

