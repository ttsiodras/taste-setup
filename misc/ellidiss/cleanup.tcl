package provide cleanup 0.1 
# Delete output (binary) directory
lappend auto_path .
namespace eval cleanup {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Cleanup output (binary) directory"
    }
    
    # Name of the application this script can be used with
    # shall be either InterfaceView or DeploymentView
    proc getApplication {} {
        return "InterfaceView"
    }
    
    # Names of  the object this script can be used on
    proc getApplyTo {} {
        return [list "alwayson" ]
    }
    
    # List of way to manage output in the Framework
    # Could be an empty list or one or both of 'dialogBox' and 'statusBar'
    proc getOutputManagement {} {
        return [list statusBar]
    }
    
    proc cleanup { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [cleanup_internal $aadlFilePath $aadlId]
    }
    
    # synchronous call
    proc cleanup_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        
        set errNumb [catch { exec -ignorestderr {*}[auto_execok "bash"] "-c" "rm -rf binary*"} ]
        
        set msg "Output directory was removed."
        
        cd $initialPath
        return [list $errNumb $msg]
    } 
}
