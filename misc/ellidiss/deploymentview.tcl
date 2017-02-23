package provide deploymentview 0.1 

lappend auto_path .
namespace eval deploymentview {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Edit Deployment View"
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
    
    proc deploymentview { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [deploymentview_internal $aadlFilePath $aadlId]
    }
    
    #  the line "exec {*}[auto_execok $::installationPath/config/externalTools/test.bat]"
    #  ask the current OS which software is to be used to open the file test.bat
    #  to launch using the absolute path, read the template2.tcl_
    
    # synchronous call
    proc deploymentview_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        set msg ""
        
        if { [file exists "[pwd]/DeploymentView.aadl" ] } {
            set errNumb [catch { exec -ignorestderr {*}[auto_execok "taste-edit-deployment-view"] } ]
        } else {
            set errNumb [catch { exec -ignorestderr {*}[auto_execok "taste-create-deployment-view"] } ]
        }
        
        set aadlId [string tolower $aadlId 0 end]
        
        cd $initialPath
        return [list $errNumb $msg]
    } 
    
    # asynchronous call
    #proc template_internal { aadlFilePath aadlId } {        
    #    exec {*}[auto_execok $::installationPath/config/externalTools/test.bat] $aadlFilePath $aadlId &
    #    return ""
    #} 
    
}
