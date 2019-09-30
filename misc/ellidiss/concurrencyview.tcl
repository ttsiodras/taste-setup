package provide concurrencyview 0.1 

lappend auto_path .
namespace eval concurrencyview {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Build Concurrency View"
    }
    
    # Name of the application this script can be used with
    # shall be either InterfaceView or DeploymentView
    proc getApplication {} {
        return "DeploymentView"
    }
    
    # Names of  the object this script can be used on
    # FIXME - it should be active all the time
    proc getApplyTo {} {
        return [list "alwayson" ]
    }
    
    # List of way to manage output in the Framework
    # Could be an empty list or one or both of 'dialogBox' and 'statusBar'
    proc getOutputManagement {} {
		## Ticket mantis 0000625
        return [list dialogBoxOnError ]
    }
    
    proc concurrencyview { args } {
		if { [Object::getAttribute "concurrencyview" state] == "deprecated" } {
			set dvRoot [Object::getAttribute "deploymentview" "rootID"]
			set res [API::Kernel::checkConsistency $dvRoot]
			if { [lindex $res 0] == -1 } {
				lset res 1 [ concat [ list "Deployment view is inconsistent" ] [lindex $res 1 ] ]
				return $res
			} else {
				Context::setAttribute "concurrencyview" state "normal"
				if { [ string match win32*64 [::platform::identify]] || [ string match win32* [::platform::identify]] } {
					return [concurrencyviewWindows_internal ]
				} else {
					return [concurrencyview_internal ]
				}
			}
		}
    }
    
    #  the line "exec {*}[auto_execok $::installationPath/config/externalTools/test.bat]"
    #  ask the current OS which software is to be used to open the file test.bat
    #  to launch using the absolute path, read the template2.tcl_
    
    # synchronous call
    proc concurrencyviewWindows_internal { } { 
        
        set ivFilename [lindex [Object::getAttribute "interfaceview" "filenames" ] 0 ]
        set dvFilename [lindex [Object::getAttribute "deploymentview" "filenames" ] 0 ]
        set dtFilename [lindex [Object::getAttribute "dataview" "filenames" ] 0 ]
        set hwFilenames [Object::getAttribute "hwlibrary" "filenames" ]
        
        if { [file exists $ivFilename ] && [file exists $dvFilename ] && [file exists $dtFilename ] } {
			set concatFilename "[LogManager::getLogDirectory]/concatenatedFile.aadl"
			set concatFilenamePredicates "[LogManager::getLogDirectory]/concatenatedFile.sbp"
			set cvFilename "[LogManager::getLogDirectory]/concurrencyview.aadl"
			set fout [ open $concatFilename w ]
			fconfigure $fout -translation lf
			set fin [ open $ivFilename r ]
			set content [read -nonewline $fin]
			close $fin
			puts $fout $content
			puts $fout "\n\n"
			set fin [ open $dvFilename r ]
			set content [read -nonewline $fin]
			close $fin
			puts $fout $content
			puts $fout "\n\n"
			if { [file exists $dtFilename ] } {
				set fin [ open $dtFilename r ]
				set content [read -nonewline $fin]
				close $fin
				puts $fout $content
				puts $fout "\n\n"
			}
			foreach hwFilename $hwFilenames {
				if { [file exists $hwFilename ] } {
					set fin [ open $hwFilename r ]
					set content [read -nonewline $fin]
					close $fin
					puts $fout $content
					puts $fout "\n\n"
				}
			}
			close $fout
			
			
			if { [ ::AADLInspectorTools::getFactsFromAADL $concatFilename $concatFilenamePredicates ] != 0 } {
				return [list -1 "error in aadlrev" ]
			}
			if { [lindex [ ::AADLInspectorTools::generateAadlFromFacts $concatFilenamePredicates "$::commonPluginPath/TasteVT.sbp" $cvFilename ] 0 ] != 0 } {
				return [list -1 "error in aadlrev" ]
			}

            ## add the hw library to the cv
            set fd [open "$cvFilename" a+]
            foreach hwFilename $hwFilenames {
				if { [file exists $hwFilename ] } {
					set fdRead [ open $hwFilename r ]
					set content [read -nonewline $fdRead]
					close $fdRead
					puts $fd $content
					puts $fd "\n\n"
				}
			}
            close $fd
            
			::API::HMI::loadUI "$cvFilename" "concurrencyview"
		
			return [list 0 ""]
		} else {
			return [ list -1 [list "IV, Dataview and DV shall be loaded."]]
		}
    } 
    
    #  the line "exec {*}[auto_execok $::installationPath/config/externalTools/test.bat]"
    #  ask the current OS which software is to be used to open the file test.bat
    #  to launch using the absolute path, read the template2.tcl_
    
    # synchronous call
    proc concurrencyview_internal { } { 
		## Ticket mantis 0000665
        set ivFilename [ lindex [::Object::getAttribute "interfaceview" "filenames" ] 0]
        set dvFilename [ lindex [::Object::getAttribute "deploymentview" "filenames" ] 0]
        set dtFilename [lindex [Object::getAttribute "dataview" "filenames" ] 0 ]
        set cvFilename "[LogManager::getLogDirectory]/concurrencyview.aadl"
		
		set res [catch { exec taste-config --prefix } tasteConfigDir ]
		if { $res != 0 } {
			#~ an error happend
			return [list 1 [list "taste-config error: $tasteConfigDir"] ]
		}

		set res [ catch { exec taste-edit-concurrency-view ${ivFilename} ${dvFilename} ${dtFilename} 2>@1 } errMsg ]
        
        if { $res == 0 } {
			if { [file exists "ConcurrencyView/process.aadl" ] } {
                            File::delete "$cvFilename"
                            File::copy "ConcurrencyView/process.aadl" "$cvFilename"

                            set chan [open "$cvFilename" a+ ]
                            fconfigure $chan -translation lf
                            foreach threadFile [glob -nocomplain  -type f  -directory "ConcurrencyView" *_Thread.aadl ] {
                                    set fin [ open $threadFile r ]
                                    set content [read -nonewline $fin]
                                    close $fin
                                    puts $chan $content
                                    puts $chan "\n\n"
                            }
                            set OCARINA_COMPONENTS "$tasteConfigDir/share/ocarina/AADLv2/ocarina_components.aadl"
                            set fin [ open $OCARINA_COMPONENTS r ]
                            set content [read -nonewline $fin]
                            close $fin
                            puts $chan $content
                            close $chan
                            ::API::HMI::loadUI "$cvFilename" "concurrencyview"
                            return [list 0 ""]
			}
                        else if { [file exists "work/build/system.aadl" ] } {
                            File::delete "$cvFilename"
                            File::copy "work/build/system.aadl" "$cvFilename"
                            set chan [open "$cvFilename" a+ ]
                            fconfigure $chan -translation lf
                            set OCARINA_COMPONENTS "$tasteConfigDir/share/ocarina/AADLv2/ocarina_components.aadl"
                            set fin [ open $OCARINA_COMPONENTS r ]
                            set content [read -nonewline $fin]
                            close $fin
                            puts $chan $content
                            close $chan
                            ::API::HMI::loadUI "$cvFilename" "concurrencyview"
                            return [list 0 ""]
                        }
		} else {
			return [list 1 [list "taste-edit-concurrency-view error:\n$errMsg" ] ]
		}
    } 
}
