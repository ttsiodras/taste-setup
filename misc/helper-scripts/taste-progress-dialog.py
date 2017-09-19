#!/usr/bin/env python

import sys
import PySide
import time
import signal

from PySide.QtCore import QThread, Signal, QObject

from PySide.QtGui import (QApplication,
                          QMessageBox,
                          QProgressDialog)

class MyThread(QThread, QObject):
    signal = Signal(str)
    progress = Signal(int)
    quit = Signal()
    def run(self):
        value = 10
        while True:
            # read from stdin without any buffering
            line = sys.stdin.readline()
            if len(line) == 0:
                print ("Bye")
                self.quit.emit()
                return
            elif line[0] == 'q':
                print ("Quit")
                self.quit.emit()
                return
            else:
                self.signal.emit(line)
                self.progress.emit(value)
                value += 10
                if value == 100:
                    value = 0
                time.sleep(0.1)



def run_gui():
        app = QApplication(sys.argv)
        thread = MyThread()       
        progress = QProgressDialog()
        progress.setValue(0)
        thread.signal.connect(progress.setLabelText)
        thread.quit.connect(progress.cancel)
        thread.progress.connect(progress.setValue)
        thread.start()
        progress.exec_()

def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    run_gui()

if __name__ == '__main__':
    main()

