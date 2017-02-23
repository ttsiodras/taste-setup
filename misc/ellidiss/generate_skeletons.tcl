package provide generate_skeletons 0.1 

lappend auto_path .
namespace eval generate_skeletons {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Generate code skeletons"
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
    
    proc generate_skeletons { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [generate_skeletons_internal $aadlFilePath $aadlId]
    }
    
    # synchronous call
    proc generate_skeletons_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        set msg ""
        set ::env(FORCE) 1
        set errNumb [catch { exec -ignorestderr {*}[auto_execok "taste-generate-skeletons"] } ]
        if { $errNumb == 0 } {
           set msg "Everything went fine!"
           unset ::env(FORCE)
        } else {
           set msg "Some errors were reported - check the console"
        }
                
        cd $initialPath
        return [list $errNumb $msg]
    } 
    
}
