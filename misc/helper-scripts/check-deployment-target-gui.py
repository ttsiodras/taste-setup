#!/usr/bin/env python

import sys
import os
import PySide
from PySide.QtGui import (QApplication,
                          QMessageBox)

def install_gr740_rtems410_gaisler_posix():
    print 'Installing this nice target'

def check_gr740_rtems410_gaisler_posix():
    if not os.path.isdir("/opt/rtems-4.10"):
        raise NotImplementedError(install_gr740_rtems410_gaisler_posix)


PLATFORMS = { "crazyflie_v2.gnat"      : lambda: True,
              "stm32f4_discovery.gnat" : lambda: True,
              "leon.rtems_posix"       : lambda: True,
              "leon2.rtems412_posix"   : lambda: True,
              "leon3.rtems412_posix"   : lambda: True,
              "gr712.rtems412_posix"   : lambda: True,
              "gr740.rtems412_posix"   : lambda: True,
              "gr740.rtems410_gaisler_posix" :
                  check_gr740_rtems410_gaisler_posix,
              "x86.linux"              : lambda: True,
              "x86.win32"              : lambda: True
             }

def query_user(platform):
        msg_box = QMessageBox()
        msg_box.setWindowTitle("This plaform is not installed!")
        ok    = msg_box.addButton("Install now",   QMessageBox.AcceptRole)
        later = msg_box.addButton("Install later", QMessageBox.RejectRole)
        msg_box.setEscapeButton(later)
        msg_box.setDefaultButton(ok)
        msg_box.setIcon(QMessageBox.Warning)
        msg_box.setText("Do you want to install target\n{} ?".format(platform))
        msg_box.exec_()
        if msg_box.clickedButton() == ok:
           return True
        else:
            warn_box = QMessageBox()
            warn_box.setIcon(QMessageBox.Information)
            warn_box.setText("You can install the platform later, manually")
            warn_box.exec_()
            return False

def main():
    app = QApplication(sys.argv)
    # check if the target in supported
    try:
        platform = sys.argv[1]
        PLATFORMS[platform]()
    except KeyError:
        warn_box = QMessageBox()
        warn_box.setIcon(QMessageBox.Information)
        warn_box.setText("Unknown platform: {}".format(platform))
        warn_box.exec_()
        return 1
    except IndexError:
        print("You must specify the target in the command line")
    except NotImplementedError as exc:
        install_it, = exc.args
        if query_user(platform):
            install_it()
    else:
        print("Platform {} is installed".format(platform))
        sys.exit(0)

if __name__ == '__main__':
    main()

