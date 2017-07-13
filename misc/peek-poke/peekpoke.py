#!/usr/bin/env python2

import sys, os, re, threading, time, signal, ctypes

sys.path.append(".")

import DV
import dataview_uniq_asn
import PythonController
PA = PythonController.PythonAccess

sizePerType = {
    DV.int_32:4,
    DV.int_64:8,
    DV.real_single:4,
    DV.real_double:8,
    DV.octet_string:0
}

try:
    import pygtk, gobject
    pygtk.require("2.0")
except:
    pass
try:
    import gtk
    import gtk.glade
except:
    sys.exit(1)

def inform(format, *args):
    if g_Debug:
        print format % args

class Matcher:
    '''Helper class to ease the matching of regular expressions.'''
    def __init__(self, pattern, flags=0):
        self._pattern = re.compile(pattern, flags)
        self._hit = None
    def match(self, line):
        '''Match at start of line'''
        self._hit = re.match(self._pattern, line)
        return self._hit
    def search(self, line):
        '''Match anywhere in the line'''
        self._hit = re.search(self._pattern, line)
        return self._hit
    def group(self, idx):
        '''Return the matched () group'''
        return self._hit.group(idx)

class PlottedVariable:
    '''This calls holds the PIDs and FIFOs for GnuPlots and speedometers'''
    def __init__(self):
        self._pidMeter = None
        self._pidGnuplot = None
        self._fifoMeter = None
        self._fifoGnuPlot = None

class Poll_taste_probe_console(threading.Thread):
    '''Class hosting the message queue polling thread'''
    msgQname = ""
    # Class-global dictionary, that holds mappings between
    # the actual offsets coming in from across the chasm, 
    # and the PlottedVariable instance holding PIDs and FIFOs.
    plottedVariables = {}

    def run(self):
        '''Thread that polls the taste_probe_console_PI_Python_queue.'''
        # If GTK Window initialization fails, 
        # we get here with _bDie set to True
        if hasattr(self, "_bDie") and self._bDie: 
            return
        # Reset _bDie - when the main thread sets it, we will die.
        self._bDie = False
        # The recording .csv variables: filename and filehandle
        self._savingInFilename = ""
        self._savingFile = None
        # First, open the queue:
        while True:
            inform("Attempting to open msgQ %s", self.msgQname)
            self._msgQueue = PA.OpenMsgQueueForReading(self.msgQname)
            if (self._msgQueue != -1):
                break
            print "Communication channel over", self.msgQname, "not established yet...\n"
            time.sleep(1)
            if self._bDie:
                return
        # Then, now that msgQ is opened, start polling:
        bufferSize = PA.GetMsgQueueBufferSize(self._msgQueue)
        self._pMem = ctypes.create_string_buffer(bufferSize).raw
        while not self._bDie:
            inform("Polling Q")
            self.messageReceivedType = PA.RetrieveMessageFromQueue(self._msgQueue, bufferSize, self._pMem)
            if self.messageReceivedType == -1:
                time.sleep(0.1)
                continue
            # parse the incoming TM
            self.ProcessTM()

    def UpdateGridAndSendToFIFOs(self, actualOffset, strValueMonitor, strValuePlot):
        '''Function that updates the grid and sends to FIFOs'''
        gtk.gdk.threads_enter()
        try:
            # Update GTK control in thread-safe way
            self.window.UpdateMonitoredVariable(
                actualOffset, strValueMonitor)
        finally:
            gtk.gdk.threads_leave()
        if self.plottedVariables.has_key(actualOffset):
            plot = self.plottedVariables[actualOffset]
            if plot._fifoGnuPlot: plot._fifoGnuPlot.write('0:'+strValuePlot+'\n')
            if plot._fifoMeter:   plot._fifoMeter.write(strValuePlot+'\n')

    def ProcessTM(self):
        '''Parses the incoming Telemetry (Update_monitorings)'''
        # For now, there's only one type of monitoring TM
        if self.messageReceivedType != PA.i_update_monitorings:
            return

        # Are we recording?
        if self.window.checkbuttonStoreMonitorings.get_active():
            # Yes, get the filename...
            fname = self.window.entryFilenameMonitorings.get_text()
            # ...and check if it changed since last time
            if fname != self._savingInFilename:
                # it did, so close the old file and open new one
                self._savingInFilename = fname
                if None != self._savingFile:
                    self._savingFile.close()
                bExistedBefore = os.path.exists(self._savingInFilename)
                self._savingFile = open(self._savingInFilename, 'a')
                if not bExistedBefore:
                    # Add CSV banner
                    self._savingFile.write('"Timestamp(Epoch)";"Variable name";"Variable value"\n')
        else: 
            # Check if user toggled the recording checkbox, 
            # and if so, close the file
            if None != self._savingFile:
                self._savingFile.close()
                self._savingFile = None

        # Actual TM handling:
        var_monitorings = dataview_uniq_asn.TASTE_Monitoring_list()
        DV.SetDataFor_TASTE_Monitoring_list(var_monitorings._ptr, self._pMem)
        # for each one of the entries in the list
        for i in xrange(0, var_monitorings.GetLength()):
            monitoring = var_monitorings[i]
            iden = str(monitoring.id.Get())
            inform("Arrived values for %s are...", iden)
            # Identify type size in bytes
            actualOffset = int(iden)
            baseName = self.window.actualOffsetToFullNameMap.get(actualOffset, None)
            if baseName == None: 
                # we don't know what to do with this actualOffset, go to next variable
                continue
            # at this point, baseName is "variableName(offset)[idx]"
            baseName = re.sub(r'\[\d+\]','',baseName)
            # baseName is now "variableName(offset)", so find the type:
            symbolType = self.window.symbolChosenTypeMap[baseName]
            # Helper function, re-used for octet strings (one elem) and others (many elem)
            def HandleElement(j,symbolTypeSize):
                actualOffset = int(iden) + j*symbolTypeSize
                if self._savingFile:
                    fullGridLineName = self.window.actualOffsetToFullNameMap.get(actualOffset, None)
                    if fullGridLineName:
                        # .csv stuff - Excel is stupid, so replace "." in time with ","
                        self._savingFile.write(str(time.time()).replace(".",",")+";")
                        # remove the extra offset
                        fullGridLineName = fullGridLineName.replace("(0)","")
                        fullGridLineName = re.sub(r'\((\d+)\)',r'+\1 ', fullGridLineName)
                        self._savingFile.write('"'+fullGridLineName + '";')
                kind = var_monitorings[i].values[j].kind.Get()
                # Read the CHOICE selector, and act based on incoming type:
                if kind == DV.int_32_PRESENT:
                    int32V = str(var_monitorings[i].values[j].int_32.Get())
                    inform("%s", int32V)
                    self.UpdateGridAndSendToFIFOs(
                        actualOffset, 
                        int32V + "(" + hex(int(int32V)) + ")", int32V)
                    if self._savingFile and fullGridLineName:
                        self._savingFile.write(int32V+"\n")
                elif kind == DV.int_64_PRESENT:
                    int64V = str(var_monitorings[i].values[j].int_64.Get())
                    inform("%s", int64V)
                    self.UpdateGridAndSendToFIFOs(
                        actualOffset, 
                        int64V + "(" + hex(int(int64V)) + ")", int64V)
                    if self._savingFile and fullGridLineName:
                        self._savingFile.write(int64V+"\n")
                elif kind == DV.real_single_PRESENT:
                    singleV = str(var_monitorings[i].values[j].real_single.Get())
                    inform("%s", singleV)
                    self.UpdateGridAndSendToFIFOs(actualOffset, singleV, singleV)
                    if self._savingFile and fullGridLineName:
                        self._savingFile.write(str(singleV).replace(".",",")+"\n")
                elif kind == DV.real_double_PRESENT:
                    doubleV = str(var_monitorings[i].values[j].real_double.Get())
                    inform("%s", doubleV)
                    self.UpdateGridAndSendToFIFOs(actualOffset, doubleV, doubleV)
                    if self._savingFile and fullGridLineName:
                        self._savingFile.write(str(doubleV).replace(".",",")+"\n")
                elif kind == DV.octet_string_PRESENT:
                    octetStringV = str(var_monitorings[i].values[j].octet_string.GetPyString())
                    inform("%s", octetStringV)
                    if baseName in self.window.hexVariables:
                        octetStringV = "0x" + "".join("%02x" % ord(c) for c in octetStringV).upper()
                        self.UpdateGridAndSendToFIFOs(actualOffset, octetStringV, octetStringV)
                    else:
                        self.UpdateGridAndSendToFIFOs(actualOffset, octetStringV, octetStringV)
                    if self._savingFile and fullGridLineName:
                        self._savingFile.write(octetStringV.replace(";","\;")+"\n")
                else:
                    print "For now, only int32, int64, single and double are supported."
            # and the size from the type:
            if symbolType != DV.octet_string:
                symbolTypeSize = sizePerType[symbolType]
                # for each one of the elements for this id
                for j in xrange(0, var_monitorings[i].values.GetLength()):
                    HandleElement(j,symbolTypeSize)
            else:
                symbolTypeSize = var_monitorings[i].values.GetLength()
                HandleElement(0,symbolTypeSize)

class PeekPoker:
    '''Main GTK window class'''
    def on_About_activate(self, _):
        '''Shows the About dialog box'''
        about = gtk.AboutDialog()
        about.set_program_name("PeekAndPoker")
        about.set_version("0.6")
        about.set_copyright("(c) Semantix Information Technologies")
        about.set_comments("Real-time monitoring and modification\nof variables in TASTE-generated systems")
        about.set_website("http://www.semantix.gr/taste")
        gtk.about_dialog_set_url_hook(lambda _,url,__: os.system("luakit \"%s\"" % url), None)
        about.run()
        about.destroy()

    def ShowError(self, title, text, type=gtk.MESSAGE_ERROR):
        '''Shows an error message dialog'''
        md = gtk.MessageDialog(parent=None, 
            flags=gtk.DIALOG_DESTROY_WITH_PARENT, type=type, 
            buttons=gtk.BUTTONS_CLOSE, 
            message_format=title)
        md.format_secondary_text(text)
        md.run()
        md.destroy()

    def LabelAndTypeAndActualOffsetOfSelectedLine(self):
        '''Returns full label, type and actualOffset of currently selected grid line'''
        selection = self.treeviewMonitored.get_selection()
        model, selected = selection.get_selected_rows()
        if len(selected) != 1:
            self.ShowError("Usage error:", "One entry must be selected...")
            return
        row = self.listOfMonitoredStore[selected[0]]
        rowName,rowOffset,_ = re.split(r'[()]', row[0])
        symbolType = self.symbolChosenTypeMap[row[0]]
        return (
            row[0] + "[" + str(row[1]) + "]",
            symbolType,
            # the actual offset is:
            #   the offset of the symbol from objdump
            self.symbolTable[rowName][0] + 
            #   plus the additional offset given by the user
            int(rowOffset) + 
            #   plus the selected element offset i.e. sizeof(type)*elementIndex
            sizePerType[symbolType]*int(row[1]))

    def on_buttonAddToList_clicked(self, _):
        '''Add the currently described variable to monitoring list'''
        offset = self.entryOffset.get_text()
        name = self.entryVariable.get_text()
        try:
            elementsNo = int(self.entryElements.get_text())
            if elementsNo>10:
                return self.ShowError(
                    "Mandatory information wrong", 
                    "Number of elements must be <=10 (or change the ASN.1 grammar to enlarge)")
        except:
            # the elements number must be a valid integer
            return self.ShowError("Mandatory information missing", "number of elements missing or invalid.")
        try:
            pollingPeriod = int(self.entrySeconds.get_text())
        except:
            # the polling period must be a valid integer
            return self.ShowError("Mandatory information missing", "number of seconds missing or invalid.")
        variableType = self.comboboxType.get_active_text()
        if variableType == None:
            # A type must be chosen
            return self.ShowError("Mandatory information missing", "You must choose a proper primitive type.")
        dvVariableType = {
            "int32":DV.int_32,
            "int64":DV.int_64,
            "real single":DV.real_single,
            "real double":DV.real_double,
            "real double":DV.real_double,
            "byte[] (hex)":DV.octet_string,
            "char[] (printable)":DV.octet_string
        }.get(variableType, None)
        if dvVariableType == None:
            self.ShowError("Unsupported type", "Only int32, int64, single, double, char[10] and byte[10] supported (for now)")
        else:
            self.AddVariable(name, offset, elementsNo, dvVariableType, pollingPeriod)
        if variableType == "byte[] (hex)":
            self.hexVariables.append("%s(%s)" % (name,offset))

    def AddVariable(self, name, offset, elementsNo, dvVariableType, pollingPeriod):
        '''Helper function that sets up the "listening" of a new variable'''
        # Set the selected type in the symbolChosenTypeMap (use "name(offset)" as key)
        self.symbolChosenTypeMap["%s(%s)" % (name,offset)] = dvVariableType
        # Add lines to the grid - as many as the elementsNo
        if dvVariableType != DV.octet_string:
            for _ in xrange(0, elementsNo):
                self.AddToMonitorList(name, offset, elementsNo, dvVariableType)
        else:
            self.AddToMonitorList(name, offset, 1, dvVariableType)
        # And invoke the TC to add the new monitoring entry
        var_TASTE_Peek_list = dataview_uniq_asn.TASTE_Peek_list()
        var_TASTE_Peek_list.SetLength(1)
        var_TASTE_Peek_list[0].base_address.Set(self.symbolTable[name][0])
        var_TASTE_Peek_list[0].offset.Set(int(offset))
        var_TASTE_Peek_list[0].base_type.Set(dvVariableType)
        var_TASTE_Peek_list[0].nb_of_elements.Set(elementsNo)
        var_TASTE_Peek_list[0].sample_time.Set(pollingPeriod)
        if -1 == PA.SendTC_add_monitorings(var_TASTE_Peek_list._ptr):
            self.ShowError("TC error:", 'Failed to send TC for Add_monitorings...\n')
        # Add the actual offset of each element in the plottedVariables dictionary of the thread
        # (offset of the symbol from objdump plus the additional offset given by the user,
        #  plus the selected element offset  i.e. sizeof(type)*elementIndex)
        #
        # This actual offset will be the key used to decide which FIFO to send data to
        # (FIFOs that drive GnuPlots)
        for elm in xrange(0,elementsNo):
            actualOffset = \
                self.symbolTable[name][0] + int(offset) + sizePerType[dvVariableType]*elm
            # mark as non-plotted (pid,fifo)
            self.poll_taste_probe_console.plottedVariables[actualOffset] = PlottedVariable()

    def on_buttonPoke_clicked(self, _):
        '''Sets the selected element to a new value'''
        _, symbolType, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
        # Now invoke the TC (Patch_memory)
        var_TASTE_Poke_list = dataview_uniq_asn.TASTE_Poke_list()
        var_TASTE_Poke_list.SetLength(1)
        var_TASTE_Poke_list[0].id.Set(actualOffset)
        var_TASTE_Poke_list[0].values.SetLength(1)
        if symbolType == DV.int_32:
            var_TASTE_Poke_list[0].values[0].int_32.Set(int(self.entryValue.get_text()))
            var_TASTE_Poke_list[0].values[0].kind.Set(DV.int_32_PRESENT)
        elif symbolType == DV.int_64:
            var_TASTE_Poke_list[0].values[0].int_64.Set(int(self.entryValue.get_text()))
            var_TASTE_Poke_list[0].values[0].kind.Set(DV.int_64_PRESENT)
        elif symbolType == DV.real_single:
            var_TASTE_Poke_list[0].values[0].real_single.Set(float(self.entryValue.get_text()))
            var_TASTE_Poke_list[0].values[0].kind.Set(DV.real_single_PRESENT)
        elif symbolType == DV.real_double:
            var_TASTE_Poke_list[0].values[0].real_double.Set(float(self.entryValue.get_text()))
            var_TASTE_Poke_list[0].values[0].kind.Set(DV.real_double_PRESENT)
        elif symbolType == DV.octet_string:
            var_TASTE_Poke_list[0].values[0].octet_string.SetFromPyString(self.entryValue.get_text())
            var_TASTE_Poke_list[0].values[0].kind.Set(DV.octet_string_PRESENT)
        if -1 == PA.SendTC_patch_memory(var_TASTE_Poke_list._ptr):
            self.ShowError("TC Error:", 'Failed to send TC: Patch_memory...\n')

    def KillTree(self, diepid):
        '''Helper function, used to shutdown the spawned GnuPlots and meters'''
        #print "Die", diepid
        tokill = [diepid]
        changed = True
        while changed:
            changed = False
            for line in os.popen("ps -o pid= -o ppid= -a").readlines():
                pid, ppid = line.split()
                pid = int(pid)
                ppid = int(ppid)
                if ppid in tokill and pid not in tokill:
                    tokill.append(pid)
                    changed = True
        for pid in reversed(tokill):
            try:
                os.kill(pid, signal.SIGTERM)
                os.waitpid(pid, 0)
            except:
                pass

    def on_buttonRemoveSelected_clicked(self, _):
        '''Removes all elements of the selected variable'''
        selection = self.treeviewMonitored.get_selection()
        model, selected = selection.get_selected_rows()
        if len(selected) != 1:
            self.ShowError("Usage error:", "One entry must be selected...")
            return
        # Can't re-use LabelAndTypeAndActualOffsetOfSelectedLine,
        # since we need to find the element 0 for the selected variable
        name = self.listOfMonitoredStore[selected[0]]
        it = model.get_iter_root()
        firstElementRowPath = None
        numberOfElements = 0
        while it:
            path = model.get_path(it)
            row = model[path]
            if name[0] == row[0]:
                numberOfElements += 1
                if row[1] == 0:
                    # element 0 - that's the row index we want
                    firstElementRowPath = path
                    rowName,rowOffset,_ = re.split(r'[()]', row[0])
                    actualOffset = self.symbolTable[rowName][0] + int(rowOffset)
                    symbolType = self.symbolChosenTypeMap[row[0]]
                    if row[0] in self.hexVariables:
                        self.hexVariables.remove(row[0])
            it = model.iter_next(it)
        # to erase all lines (elements) of this variable,
        # repeatedly delete line index of the first element
        for i in xrange(0,numberOfElements):
            del self.listOfMonitoredStore[firstElementRowPath]
            try:
                off = actualOffset + sizePerType[symbolType]*i
                plot = self.poll_taste_probe_console.plottedVariables[off]
                if plot._pidGnuplot != None:
                    self.KillTree(plot._pidGnuplot)
                    plot._pidGnuplot = None
                    plot._fifoGnuPlot = None
                if plot._pidMeter != None:
                    self.KillTree(plot._pidMeter)
                    plot._pidMeter = None
                    plot._fifoMeter = None
            except:
                pass # not all elements are ploted/metered

        # Now invoke the TC (Remove_monitorings) 
        # with the actual offset of element 0
        var_TASTE_Peek_id_list = dataview_uniq_asn.TASTE_Peek_id_list()
        var_TASTE_Peek_id_list.SetLength(1)
        var_TASTE_Peek_id_list[0].Set(actualOffset)
        if -1 == PA.SendTC_remove_monitorings(var_TASTE_Peek_id_list._ptr):
            self.ShowError("TC error:", 'Failed to send TC for Remove_monitorings...\n')

    def on_buttonPlotSelected_clicked(self, _, defcmd='cat %s | ./driveGnuPlotsStreams.pl 1 30 ', defsizepos="320x240+0+0"):
        '''Common function used for both metering and gnuplotting a grid line'''
        descr, _, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
        isGnuPlot = "GnuPlot" in defcmd
        if isGnuPlot and g_gnuplotIsMissing:
            self.ShowError("Missing dependency:", "gnuplot is not installed in your machine, plot is disabled...")
            return
        # use the actualOffset to identify the PlottedVariable instance
        plot = self.poll_taste_probe_console.plottedVariables[actualOffset]
        if ((isGnuPlot and plot._fifoGnuPlot == None) or \
                ((not isGnuPlot) and plot._fifoMeter == None)):
            # construct new FIFO name
            cleanFIFOname = "/tmp/" + re.sub(r'[^a-zA-Z0-9_]', '_', descr)
            cleanFIFOname += "_gnuplot" if isGnuPlot else "_meter"
            try:
                os.mkfifo(cleanFIFOname)
            except:
                pass
            cmd = defcmd % cleanFIFOname
            if 'speedom' not in defcmd:
                cmd += '"GP:%s" %s' % (descr, defsizepos)
            else:
                cmd += '"SM:%s" %s' % (descr, defsizepos)
            # Spawn the proper binary via the constructed command "cmd"
            pid = os.spawnvp(os.P_NOWAIT, "/bin/sh", ["/bin/sh", "-c", cmd])
            time.sleep(0.5)
            fifo = open(cleanFIFOname, 'w', 1)
            # Update the PlottedVariable instance
            if isGnuPlot:
                plot._pidGnuplot = pid
                plot._fifoGnuPlot = fifo
            else:
                plot._pidMeter = pid
                plot._fifoMeter = fifo

    def on_buttonMeterSelected_clicked(self, x, defsizepos="250x250+0+0"):
        '''Calls on_buttonPlotSelected_clicked to re-use spawning funtionality'''
        cmd = 'cat %s | speedometer.py '
        self.on_buttonPlotSelected_clicked(x, cmd, defsizepos)

    def on_buttonUnplotSelected_clicked(self, *_):
        '''Kills the relevant GnuPlot and resets the PlottedVariable instance'''
        _, __, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
        plot = self.poll_taste_probe_console.plottedVariables.get(actualOffset, None)
        if plot and plot._fifoGnuPlot:
            if plot._pidGnuplot != None:
                self.KillTree(plot._pidGnuplot)
                plot._fifoGnuPlot = None
                plot._pidGnuplot = None

    def on_buttonUnmeterSelected_clicked(self, *_):
        '''Kills the relevant speedometer and resets the PlottedVariable instance'''
        _, __, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
        plot = self.poll_taste_probe_console.plottedVariables.get(actualOffset, None)
        if plot and plot._fifoMeter:
            if plot._pidMeter != None:
                self.KillTree(plot._pidMeter)
                plot._fifoMeter = None
                plot._pidMeter = None

    def on_buttonChooseFilename_clicked(self, _):
        '''Spawns File/SaveAs dialog for choosing the recorded .csv filename'''
        self.filew = gtk.FileChooserDialog(
            action=gtk.FILE_CHOOSER_ACTION_SAVE,
            buttons=(
                gtk.STOCK_CANCEL,
                gtk.RESPONSE_CANCEL,
                gtk.STOCK_SAVE_AS,
                gtk.RESPONSE_OK))
        self.filew.connect("destroy", lambda _: self.filew.destroy())
        self.filew.set_current_name("recordedMonitorings.csv")
        response = self.filew.run()
        if response == gtk.RESPONSE_OK:
            self.entryFilenameMonitorings.set_text(os.path.relpath(self.filew.get_filename()))
        self.filew.destroy()

    def AddToMonitorList(self, name, offset, elementsNo, symbolType):
        '''Add new variable in GTK TreeView store'''
        model = self.listOfMonitoredStore
        symbolTypeSize = sizePerType[symbolType]
        fullname = name + "(" + offset + ")"
        # for each of the elements desired (i.e. 0 .. elementsNo-1)
        for i in xrange(0, elementsNo):
            # check that it doesn't already exist there
            it = model.get_iter_root()
            exists = False
            while it:
                row = model[model.get_path(it)]
                exists = fullname == row[0] and i == row[1]
                if exists:
                    break
                it = model.iter_next(it)
            if not exists:
                self.listOfMonitoredStore.append([fullname,i,"no data yet"])
                actualOffset = self.symbolTable[name][0] + int(offset) + i*symbolTypeSize
                self.actualOffsetToFullNameMap[actualOffset] = "%s(%s)[%d]" % (name,offset,i)

    def UpdateMonitoredVariable(self, incomingOffset, strValue):
        '''Called from the listening thread to update grid with new values'''
        model = self.listOfMonitoredStore
        it = model.get_iter_root()
        while it:
            row = model[model.get_path(it)]
            symbolType = self.symbolChosenTypeMap[row[0]]
            # split row[0] to: [variableName,offset,'']
            rowName,rowOffset,_ = re.split(r'[()]', row[0])
            # the actual offset is:
            #   the offset of the symbol from objdump
            #   plus the additional offset given by the user
            #   plus the selected element offset 
            #   i.e. sizeof(type)*elementIndex
            finalRowOffset = \
                self.symbolTable[rowName][0] +  \
                int(rowOffset) +  \
                sizePerType[symbolType]*int(row[1])
            # actual offsets are primary keys, compare against them
            inform("Checking update against grid (%s == %s)", 
                str(incomingOffset), str(finalRowOffset))
            if incomingOffset == finalRowOffset:
                model[model.get_path(it)] = [row[0], row[1], strValue]
                break
            it = model.iter_next(it)

    def idleFunc(self):
        '''Controls the GUI controls state - enables/disables accordingly.'''
        # The button to add to list will only be enabled if...
        if self.entryVariable.get_text() not in self.symbolTable.keys() \
                or self.comboboxType.get_active_text() == None \
                or self.entrySeconds.get_text() == "" \
                or self.entryElements.get_text() == "":
            self.buttonAddToList.set_sensitive(False)
        else:
            self.buttonAddToList.set_sensitive(True)
        selection = self.treeviewMonitored.get_selection()
        if None != selection:
            model, selected = selection.get_selected_rows()
            if 0 != len(selected):
                # The buttons to poke and remove from list will only be enabled 
                # if one entry is selected in the list.
                _, selectedType, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
                # esp. for octet strings, dont try to validate input
                inputData = self.entryValue.get_text()
                if selectedType != DV.octet_string:
                    try:
                        _ = float(inputData)
                        self.buttonPoke.set_sensitive( 0 != len(selected) and inputData != "")
                    except:
                        self.buttonPoke.set_sensitive(False)
                else:
                    self.buttonPoke.set_sensitive( 0 != len(selected) and inputData != "")
            else:
                self.buttonPoke.set_sensitive(False)
            # Same for the remove button - a grid line must be selected
            self.buttonRemoveSelected.set_sensitive( 0 != len(selected) )
            # Logic for Plot/Meter/Unplot/Unmeter
            ctls = [
                self.buttonPlotSelected, 
                self.buttonMeterSelected, 
                self.buttonUnplotSelected, 
                self.buttonUnmeterSelected]
            def disableAll():
                for ctl in ctls:
                    ctl.set_sensitive(False)
            if 0 != len(selected):
                _, selectedType, actualOffset = self.LabelAndTypeAndActualOffsetOfSelectedLine()
                if selectedType == DV.octet_string:
                    disableAll()
                else:
                    plot = self.poll_taste_probe_console.plottedVariables.get(actualOffset, None)
                    if plot:
                        self.buttonPlotSelected.set_sensitive(plot._fifoGnuPlot == None)
                        self.buttonMeterSelected.set_sensitive(plot._fifoMeter == None)
                        self.buttonUnplotSelected.set_sensitive(plot._fifoGnuPlot != None)
                        self.buttonUnmeterSelected.set_sensitive(plot._fifoMeter != None)
                    else:
                        self.buttonPlotSelected.set_sensitive(True)
                        self.buttonMeterSelected.set_sensitive(True)
                        self.buttonUnplotSelected.set_sensitive(False)
                        self.buttonUnmeterSelected.set_sensitive(False)
            else:
                disableAll()
        else:
            self.buttonPoke.set_sensitive(False)
            self.buttonRemoveSelected.set_sensitive(False)
            self.buttonPlotSelected.set_sensitive(False)
            self.buttonMeterSelected.set_sensitive(False)
            self.buttonUnplotSelected.set_sensitive(False)
            self.buttonUnmeterSelected.set_sensitive(False)
        # Allow the recording checkbox when a filename is chosen
        self.checkbuttonStoreMonitorings.set_sensitive(self.entryFilenameMonitorings.get_text() != "")
        return True

    def DetectELF(self, filename):
        '''Detects kind of ELF binary, and returns proper objdump filename.'''
        # 2011/09/30: Deprecated - Maxime discovered that x86 objdump works in all cases.

        #binarySignature = os.popen("file \"%s\"" % filename).readlines()[0]
        #x86  = Matcher(r'ELF 32-bit LSB.*80.86')
        #x64  = Matcher(r'ELF 64-bit LSB.*x86-64')
        #leon = Matcher(r'ELF 32-bit MSB.*SPARC')
        #if x86.search(binarySignature) or x64.search(binarySignature):
        #    return 'objdump'
        #elif leon.search(binarySignature):
        #    return 'sparc-elf-objdump'
        #else:
        #    self.ShowError("Fatal error", "This kind of binary is not supported")
        #    sys.exit(1)
        return 'objdump'

    def RemoveAllMonitorings(self):
        '''Removes all from grid - called on destruction and on loading'''
        selection = self.treeviewMonitored.get_selection()
        for i in xrange(0,len(self.listOfMonitoredStore)):
            selection.unselect_path(i)
        while True:
            l =  len(self.listOfMonitoredStore)
            if 0 == l: break
            selection.select_path(0)
            self.on_buttonRemoveSelected_clicked('blah')
        
    def on_Exit_activate(self,*_):
        '''When we File/Exit, remove all from grid and stop GTK'''
        self.RemoveAllMonitorings()
        gtk.main_quit()

    def on_Open_activate(self,*_):
        '''Shows File/Open dialog and restores state of grid and gnuplot/meters'''
        self.filew = gtk.FileChooserDialog(
            action=gtk.FILE_CHOOSER_ACTION_OPEN,
            buttons=(
                gtk.STOCK_CANCEL,
                gtk.RESPONSE_CANCEL,
                gtk.STOCK_OPEN,
                gtk.RESPONSE_OK))
        self.filew.connect("destroy", lambda x: self.filew.destroy())
        filt = gtk.FileFilter()
        filt.set_name("All .mon files")
        filt.add_pattern("*.mon")
        self.filew.add_filter(filt)
        response = self.filew.run()
        if response == gtk.RESPONSE_OK:
            openFilename = os.path.relpath(self.filew.get_filename())
        self.filew.destroy()
        if response != gtk.RESPONSE_OK:
            return
        # First, clear any stuff we have open right now
        self.RemoveAllMonitorings()
        # Then load the 3 lines from the .mon using "eval"
        s = {}
        for line in open(openFilename,'r'):
            for prefix in ('variables','plotWindows','meterWindows'):
                locals()[prefix] = []
                if line.startswith(prefix):
                    try:
                        s[prefix] = eval(line.strip()[len(prefix)+1:])
                    except:
                        pass
        # Add the variables to the grid
        for name, offset, elemNo, asnType in s["variables"]:
            self.AddVariable(name, str(offset), elemNo, asnType, 1)
            time.sleep(0.2)
        # And now spawn meters and gnuplots:
        # First, un-select all grid lines
        selection = self.treeviewMonitored.get_selection()
        for i in xrange(0,len(self.listOfMonitoredStore)):
            selection.unselect_path(i)
        def PlotOrMeter(self, container, action):
            # Then, for each gnuplot/meter, select the line
            for x,y,w,h,actualVariable in container:
                model = self.listOfMonitoredStore
                idx, it = 0, model.get_iter_root()
                while it:
                    row = model[model.get_path(it)]
                    if row[0] + "[" + str(row[1]) + "]" == actualVariable:
                        selection.select_path(idx)
                        # ...and "click" on the proper button (Plot/Meter)
                        action('blah', defsizepos="%dx%d+%d+%d" % (w-2,h-15,x-4,y-50))
                    it = model.iter_next(it)
                    idx += 1
        PlotOrMeter(self, s["plotWindows"], self.on_buttonPlotSelected_clicked)
        PlotOrMeter(self, s["meterWindows"], self.on_buttonMeterSelected_clicked)

    def on_SaveAs_activate(self,*_):
        '''Show File/SaveAs dialog, and store variables and gnuplot/meter windows'''
        if g_wmctrlIsMissing:
            self.ShowError("Missing dependency:", "wmctrl is not installed in your machine, Save As is disabled...")
            return
        self.filew = gtk.FileChooserDialog(
            action=gtk.FILE_CHOOSER_ACTION_SAVE,
            buttons=(
                gtk.STOCK_CANCEL,
                gtk.RESPONSE_CANCEL,
                gtk.STOCK_SAVE_AS,
                gtk.RESPONSE_OK))
        self.filew.connect("destroy", lambda _: self.filew.destroy())
        self.filew.set_current_name("variables.mon")
        response = self.filew.run()
        if response == gtk.RESPONSE_OK:
            saveFilename = os.path.relpath(self.filew.get_filename())
        self.filew.destroy()
        if response != gtk.RESPONSE_OK:
            return

        # Serialize variables as tupples of 4 things:
        # (variableName, offset, noOfElements, ASN1type)
        model = self.listOfMonitoredStore
        it = model.get_iter_root()
        serializeList = []
        elements = {}
        while it:
            row = model[model.get_path(it)]
            name, offset = row[0].split("(")
            offset = offset.rstrip(")")
            if (name,offset) not in serializeList:
                serializeList.append((name,offset))
                #actualOffset = self.symbolTable[name][0] + int(offset)
                elements[(name,offset)] = 1
            else:
                elements[(name,offset)] += 1
            it = model.iter_next(it)
        if len(serializeList) == 0:
            self.ShowError("Nothing to save", "There are no variables added in your monitoring list")
            return
        # Create the serialized form of the variable list
        s = []
        for name,offset in serializeList:
            s.append(
                (name, 
                 int(offset), 
                 elements[(name,offset)], 
                 self.symbolChosenTypeMap[name + "(" + offset + ")"]))
        # Create the serialized form of the windows lists (gnuplot/meters)
        plotWindows = []
        meterWindows = []
        actionList = (("GP:",plotWindows),("SM:",meterWindows))
        # Spawn wmctrl to detect windows and sizes
        for line in os.popen("wmctrl -l -G").readlines():
            data = line.strip().split()
            for prefix, container in actionList:
                if data[7].startswith(prefix):
                    x,y,w,h = map(int, data[2:6])
                    actualVariable = data[7][len(prefix):]
                    # format: the 4 dimensions and the name
                    container.append((x,y,w,h,actualVariable))
        f = open(saveFilename, 'w')
        f.write("variables:" + str(s) + "\n")
        f.write("plotWindows:" + str(plotWindows) + "\n")
        f.write("meterWindows:" + str(meterWindows) + "\n")
        f.close()

    def __init__(self):
        '''Creates the GTK Window with the controls, and populates it via objdump.'''
        self.gladefile = os.path.abspath(os.path.dirname(sys.argv[0])) + "/PeekPoke.glade"  
        self.wTree = gtk.glade.XML(self.gladefile)
        # Use Python's ability to set fields at runtime,
        # to populate the class with control attributes
        for s in (  "entryVariable","entryOffset","entrySeconds", 
                    "entryElements", "entryValue", 
                    "entryFilenameMonitorings",
                    "comboboxType",
                    "treeviewMonitored",
                    "buttonAddToList", "buttonPoke", "buttonRemoveSelected",
                    "buttonPlotSelected", "buttonMeterSelected",
                    "buttonUnplotSelected", "buttonUnmeterSelected",
                    "buttonChooseFilename",
                    "checkbuttonStoreMonitorings"):
            setattr(self, s, self.wTree.get_widget(s))    
        dic = { 
            "on_buttonAddToList_clicked" : self.on_buttonAddToList_clicked,
            "on_buttonPoke_clicked" : self.on_buttonPoke_clicked,
            "on_Open_activate" : self.on_Open_activate,
            "on_SaveAs_activate" : self.on_SaveAs_activate,
            "on_Exit_activate" : self.on_Exit_activate,
            "on_About_activate" : self.on_About_activate,
            "on_buttonRemoveSelected_clicked" : self.on_buttonRemoveSelected_clicked,
            "on_buttonPlotSelected_clicked" : self.on_buttonPlotSelected_clicked,
            "on_buttonMeterSelected_clicked" : self.on_buttonMeterSelected_clicked,
            "on_buttonUnplotSelected_clicked" : self.on_buttonUnplotSelected_clicked,
            "on_buttonUnmeterSelected_clicked" : self.on_buttonUnmeterSelected_clicked,
            "on_buttonChooseFilename_clicked": self.on_buttonChooseFilename_clicked
        }
        self.wTree.signal_autoconnect(dic)
        self.window = self.wTree.get_widget("MainWindow")
        if (self.window):
            self.window.connect("destroy", self.on_Exit_activate)
            self.window.connect("delete-event", self.on_Exit_activate)
        # The symbolTable keeps the offsets extracted from objdump
        self.symbolTable = {}
        # The symbolChosenTypeMap keeps the user-selected type per variable
        self.symbolChosenTypeMap = {}
        # The actualOffsetToFullNameMap goes from memory address to full name
        self.actualOffsetToFullNameMap = {}
        # Create the two Stores: one for the auto-completion variable name entry,
        # and one for the grid.
        listOfVariablesControl = gtk.ListStore(gobject.TYPE_STRING)
        objdump = self.DetectELF(sys.argv[1])
        for line in os.popen("%s -t \"%s\"" % (objdump,sys.argv[1])).readlines():
            # example data:
            # 40069598 g     O .bss     0000000c Internal_errors_What_happened
            # 00000000 g       *ABS*    00000000 PROM_START
            # 00000000  w      *UND*    00000000 _Jv_RegisterClasses
            # 400690c8 g     O .bss     00000004 rtems_libio_semaphore
            if line.find(".bss") == -1 and line.find(".data") == -1:
                continue
            fields = line.strip().split()
            try:
                offset, size, name = int(fields[0],16), int(fields[-2],16), fields[-1]
                # deprecated: filter based on size
                # if size < 8: continue
                # Store in symbolTable
                if "." in name:
                    name = name[:name.index(".")]
                self.symbolTable[name] = [offset, size]
            except:
                pass
        # Add the names to the Store for the auto-completion entry
        for name in sorted(self.symbolTable.keys()):
            listOfVariablesControl.append([name])
        self.hexVariables = []
        completion = gtk.EntryCompletion()
        completion.set_model(listOfVariablesControl)
        completion.set_text_column(0)
        self.entryVariable.set_completion(completion)
        self.cell = gtk.CellRendererText()

        # The Grid (TM)
        self.listOfMonitoredStore = gtk.ListStore(str,int,str)
        self.column1 = gtk.TreeViewColumn('VariableName(offset)')
        self.column2 = gtk.TreeViewColumn('ElementIndex')
        self.column3 = gtk.TreeViewColumn('Value')
        self.column1.set_resizable(True)
        self.column2.set_resizable(True)
        self.column3.set_resizable(True)
        self.treeviewMonitored.append_column(self.column1)
        self.treeviewMonitored.append_column(self.column2)
        self.treeviewMonitored.append_column(self.column3)
        self.column1.pack_start(self.cell, True)
        self.column2.pack_start(self.cell, True)
        self.column3.pack_start(self.cell, True)
        self.column1.add_attribute(self.cell, 'text', 0)
        self.column2.add_attribute(self.cell, 'text', 1)
        self.column3.add_attribute(self.cell, 'text', 2)
        self.treeviewMonitored.set_search_column(0)
        self.column1.set_sort_column_id(0)
        self.treeviewMonitored.set_reorderable(True)
        self.treeviewMonitored.set_model(self.listOfMonitoredStore)
        self.tag = gobject.timeout_add(100, self.idleFunc)

def which(program):
    '''Helper function, checks if binary is in PATH'''
    def is_exe(fpath):
        return os.path.exists(fpath) and os.access(fpath, os.X_OK)
    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None

if __name__ == "__main__":
    # Check first that the binaries we spawn exist in PATH
    os.putenv(
        "PATH",
        os.getenv("PATH") + ":" + \
                os.popen("taste-config --prefix").readlines()[0].strip() + \
                "/share/speedometer")
    for f in ('ps','file','objdump'):
        where = which(f)
        if None == where:
            print "Missing dependency: please install '%s' in your PATH" % f
            sys.exit(1)
    # ESA request: make wmctrl optional (disable SaveAs if missing)
    global g_wmctrlIsMissing
    g_wmctrlIsMissing = False
    if which('wmctrl') == None:
        print "WARNING: wmctrl is missing, SaveAs functionality disabled...\n"
        g_wmctrlIsMissing = True
    global g_gnuplotIsMissing
    g_gnuplotIsMissing = False
    if which('gnuplot') == None:
        print "WARNING: gnuplot is missing, plot functionality disabled...\n"
        g_gnuplotIsMissing = True
    global g_Debug
    g_Debug = "-g" in sys.argv
    if g_Debug:
        sys.argv.remove("-g")
    if len(sys.argv) != 2:
        print "Usage:", sys.argv[0], "<leonBinary>"
        sys.exit(1)
    try:
        # The grid must be updated from another thread,
        # so we need the workarounds described in section 2 of this:
        # http://faq.pygtk.org/index.py?req=show&file=faq20.006.htp
        gtk.gdk.threads_init()
        hwg = PeekPoker()
        poll_taste_probe_console = Poll_taste_probe_console()
        poll_taste_probe_console.msgQname = str(os.geteuid()) + "_taste_probe_console_PI_Python_queue"
        poll_taste_probe_console.window = hwg
        poll_taste_probe_console.start()
        hwg.poll_taste_probe_console = poll_taste_probe_console
        gtk.gdk.threads_enter()
        gtk.main()
        gtk.gdk.threads_leave()
    except:
        pass
    poll_taste_probe_console._bDie = True
    inform("Waiting for msgQ thread to die...")
    poll_taste_probe_console.join()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
