#!/usr/bin/env python

import sys
import PySide
from PySide.QtGui import (QApplication,
                          QMessageBox)

def check_crazyflie():
    ''' This function should be in a different module '''
    return

def check_snoopy():
    raise NotImplementedError()

PLATFORMS = { "crazyflie.gnat" : check_crazyflie,
              "snoopy"         : check_snoopy}

def run_gui(platform):
        app = QApplication(sys.argv)
        msg_box = QMessageBox()
        msg_box.setWindowTitle("This plaform is not installed!")
        ok    = msg_box.addButton("Install now",   QMessageBox.AcceptRole)
        later = msg_box.addButton("Install later", QMessageBox.RejectRole)
        msg_box.setEscapeButton(later)
        msg_box.setDefaultButton(ok)
        msg_box.setIcon(QMessageBox.Warning)
        msg_box.setText("Do you want to install target {} ?".format(platform))
        msg_box.exec_()
        if msg_box.clickedButton() == ok:
            print("OK, will do.")
        else:
            warn_box = QMessageBox()
            warn_box.setIcon(QMessageBox.Information)
            warn_box.setText("You can install the platform later, manually")
            warn_box.exec_()

def main():
    # check if the target in supported
    try:
        platform = sys.argv[1]
        PLATFORMS[platform]()
    except KeyError:
        print("Unknown platform: {}".format(platform))
        return 1
    except IndexError:
        print("You must specify the target in the command line")
    except NotImplementedError:
        run_gui(platform)
    else:
        print("Platform {} is installed".format(platform))
        sys.exit(0)

if __name__ == '__main__':
    main()

