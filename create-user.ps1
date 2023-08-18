<#
    .NOTES
    ===========================================================================
	 Created by:   	Stefan Wackernagel ()
     Date:          18.08.2023 
	 Organization: 	free
     Twitter/X:       @wackers_bln
	===========================================================================

	.SYNOPSIS
		xxxxxx
	
	.DESCRIPTION
		xxxxxx

	.EXAMPLE
        xxxxxxxxx
	
	.NOTES
       Author:  Stefan Wackernagel
       Version: 0.1
	   
	.PARAMETER Server
        xxxxxxxxx
	
	.PARAMETER Recurse
		xxxxxxxxx
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]$jsonfile,
    [ValidateSet("Create","Remove","Check")]
    [string]$functionname
)

Clear-Host

function New-custom_User {
    param (
        [Parameter(Mandatory=$True)]$userconfigfile,
        [System.Management.Automation.PSCredential]$logincredentials
    )

    foreach ($Item in $userconfigfile.hosts) {

        try{

            $esxi_session  = Connect-VIServer $Item -Credential $logincredentials -ErrorAction Stop

        }catch{

            Write-Warning $_.Exception.Message
            
        }
        
        if($esxi_session.IsConnected -eq $true){
            
            foreach($User in $userconfigfile.new_user){
                
                try {

                    $rootFolder       = Get-Folder root -Server $esxi_session -ErrorAction Stop

                    $accountverify = Get-VMHostAccount -ID $User.username -Server $esxi_session -ErrorAction SilentlyContinue

                    if(!$accountverify){

                        Write-Host -ForegroundColor Green 'Adding User: '$User.username' to Host: '$Item''
                        New-VMHostAccount -Id $User.username -Password  $User.password -Server $esxi_session -ErrorAction Stop | Out-Null
                            
                        Write-Host -ForegroundColor Green 'Adding User: '$User.username' to Role: '$User.role' '
                        New-VIPermission -Entity $rootFolder -Principal $User.username -Role $User.role -ErrorAction Stop | Out-Null

                    }else{

                        Write-Host -ForegroundColor Red 'User: '$User.username'already exists on Host: '$Item''
                        Clear-Variable -Name "accountverify"

                    }
                }
                catch {
                    
                    Write-Warning $_.Exception.Message
                    break
                }
            }
        }

        Disconnect-VIServer -Server $esxi_session -Confirm:$false -Verbose:$false 
    }
}

function Remove-custom_User {
    param (
        [Parameter(Mandatory=$True)]$userconfigfile,
        [System.Management.Automation.PSCredential]$logincredentials
    )

    foreach ($Item in $userconfigfile.hosts ) {

        try{

            $esxi_session  = Connect-VIServer $Item -Credential $logincredentials -ErrorAction Stop

        }catch{

            Write-Warning $_.Exception.Message
            break
        }
        if($esxi_session.IsConnected -eq $true){
            
            foreach($User in $userconfigfile.new_user){
                
                try {

                    Get-VMHostAccount -ID $User.username -Server $esxi_session -ErrorAction Stop | Remove-VMHostAccount -Confirm:$false

                    Write-Host -ForegroundColor Red 'Remove User:'$User.username'from Host:'$Item''
                }
                catch {
                                      
                    Write-Warning $_.Exception.Message
                    break
                }
            }
        }

        Disconnect-VIServer -Server $esxi_session -Confirm:$false -Verbose:$false 
    }
}

function Add-custom_User {
    param (
        [Parameter(Mandatory=$True)]$userconfigfile
    )

    foreach ($Item in $userconfigfile.hosts ) {
    
        foreach($User in $userconfigfile.new_user){
            
            try {
                
                $esxi_test_session  = Connect-VIServer $Item -User $User.username -Password $User.password -ErrorAction Stop
            }
            catch {
                
                Write-Warning $_.Exception.Message
            }
            
            if($esxi_test_session.IsConnected){

                Write-Host -ForegroundColor Green 'User:'$User.username'connected to Host:'$Item' successfully'

                Disconnect-VIServer -Server $esxi_test_session -Confirm:$false -Verbose:$false

            }else {
                Write-Host -ForegroundColor Red 'User:'$User.username'cant connect to Host:'$Item''
            } 
        }
    }
}

#
#   Main Script
#

try{

    $json = Get-Content -Path $jsonfile -ErrorAction Stop
    $json = $json | ConvertFrom-Json

}catch{

    Write-Warning $_.Exception.Message
    break
}


if($functionname -eq 'Create'){
    
    New-custom_User -userconfigfile $json -logincredentials $(Get-Credential)


}elseif ($functionname -eq 'Remove') {
    
    Remove-custom_User -userconfigfile $json -logincredentials $(Get-Credential)

}elseif ($functionname -eq 'Check') {
   
    Add-custom_User -userconfigfile $json
}
