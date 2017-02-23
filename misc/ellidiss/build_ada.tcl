package provide build_ada 0.1 

lappend auto_path .
namespace eval build_ada {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Build the system (in Ada)"
    }
    
    # Name of the application this script can be used with
    # shall be either InterfaceView or DeploymentView
    proc getApplication {} {
        return "InterfaceView"
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
    
    proc build_ada { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [build_internal $aadlFilePath $aadlId]
    }
    
    # synchronous call
    proc build_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        set msg ""
        set ::env(USE_POHIADA) "1"
        set errNumb [catch { exec [auto_execok "taste-build-system"] } ]
        if { $errNumb == 0 } {
           set msg "Everything went fine!"
        } else {
           set msg "Some errors were reported - check the console"
        }
        unset ::env(USE_POHIADA)
        cd $initialPath
        return [list $errNumb $msg]
    } 
    
}
