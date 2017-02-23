package provide c_kate 0.1 
# C code editor (using Kate)
lappend auto_path .
namespace eval c_kate {
    
    # Graphical name of the operation
    proc getLabel {} {
        return "Edit C source code"
    }
    
    # Name of the application this script can be used with
    # shall be either InterfaceView or DeploymentView
    proc getApplication {} {
        return "InterfaceView"
    }
    
    # Names of  the object this script can be used on
    proc getApplyTo {} {
        return [list { "Function" {"Source_Language" "C"} }  ]
    }
    
    # List of way to manage output in the Framework
    # Could be an empty list or one or both of 'dialogBox' and 'statusBar'
    proc getOutputManagement {} {
        return [list statusBar]
    }
    
    proc c_kate { args } {
        set params [lindex $args 0]
        set aadlFilePath [Parameter::getParameter $params aadlFilePath]
        set aadlId [Parameter::getParameter $params id]
        return [c_internal $aadlFilePath $aadlId]
    }
    
    #  the line "exec {*}[auto_execok $::installationPath/config/externalTools/test.bat]"
    #  ask the current OS which software is to be used to open the file test.bat
    #  to launch using the absolute path, read the template2.tcl_
    
    # synchronous call
    proc c_internal { aadlFilePath aadlId } {    
        set initialPath [pwd]
        cd [file dirname $aadlFilePath]
        set msg ""
        
        set errNumb [catch { exec -ignorestderr {*}[auto_execok "taste-generate-skeletons"] } ]
        
        set aadlId [string tolower $aadlId 0 end]
        
        if { $errNumb == 0 && [file exists [file normalize "[pwd]/$aadlId" ] ] } {
            cd [file normalize "[pwd]/$aadlId" ]
            set errNumb [catch { exec -ignorestderr {*}[auto_execok kate] ${aadlId}.h ${aadlId}.c & } ]
            if { $errNumb == 0 } {
             # TODO: check code - but we need to have C_ASN1_Types.h
             #   set errNumb [catch { exec -ignorestderr {*}[auto_execok gcc] -fsyntax-only -c ${aadlId}.c } ]
             #   if { $errNumb != 0 } {
             #       set msg "Note: There are syntax errors in your code - check it before you build"
             #   }
            } else {
                set msg "Error in execution of \"kate ${aadlId}.c ${aadlId}.h\""
            }
        } else {
            set msg "Error in execution of \"taste-generate-skeletons $aadlFilePath\""
        }
        
        cd $initialPath
        return [list $errNumb $msg]
    } 
    
    # asynchronous call
    #proc template_internal { aadlFilePath aadlId } {        
    #    exec {*}[auto_execok $::installationPath/config/externalTools/test.bat] $aadlFilePath $aadlId &
    #    return ""
    #} 
    
}
