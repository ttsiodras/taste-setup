package provide concurrencyview 0.1 

lappend auto_path .
namespace eval concurrencyview {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Edit Concurrency View"
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
        return [list statusBar]
    }
    
    proc concurrencyview { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [concurrencyview_internal $aadlFilePath $aadlId]
    }
    
    #  the line "exec {*}[auto_execok $::installationPath/config/externalTools/test.bat]"
    #  ask the current OS which software is to be used to open the file test.bat
    #  to launch using the absolute path, read the template2.tcl_
    
    # synchronous call
    proc concurrencyview_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        set msg ""
        
        set errNumb [catch { exec -ignorestderr {*}[auto_execok "taste-edit-concurrency-view"] } ]
        
        cd $initialPath
        return [list $errNumb $msg]
    } 
}
