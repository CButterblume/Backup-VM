<#

.SYNOPSIS    

Name: Backup-VM.ps1
Backs up/exports virtual machines to a specified folder

    

.DESCRIPTION  

The script exports a given list of virtual machines from a given list of Hyper-V hosts to a specified folder.
It is possible to exports all virtual machines on a given Hyper-V host. This is triggered by a special value for the VM-parameter.

There are two different modes for exports:

Production Checkpoint: Triggered by the -ProductionCheckpoint parameter, this modes creates a consistent checkpoint for the virtual machine(s) prior to the export operation.

Online: Without the -ProdutionCheckpoint parameter, the script exports the virtual machine(s) in online-mode.


Full and detailed description of all function actions


.PARAMETER HVhost  

This parameter specifies the Hyper-V hosts. It cannot be empty. It is possible to hand over a comma-seperated list of values.

.PARAMETER VM 

This parameter specifies the virtual machines. If this parameter is empty, ALL found virtual machines are going to be exported.

.PARAMETER ExportPath  

This parameter specifies the export path for the virtual machines.

.PARAMETER LogPath  

This parameter specifies the log file path. If parameter is left empty, the log files are stored at %Windows%\logs\HyperVBackup

.PARAMETER ProductionCheckpoint 

This parameter triggers the Production Checkpoint creation. Without this parameter, the virtual machines are exported in online-mode (no consistency guaranteed).

                             

.NOTES    
Author: Michael Wittmann, SNEU: IT - DE, michael.wittmann@socionext.com

DateCreated: 19.07.2017

   

.EXAMPLE    

Show how to invoke the function with the desired syntax


.EXAMPLE    

Give examples using any and all parameters and pipe inputs (if any) that the function will accept

#>
Param(
    [Parameter(Mandatory = $true)]
    [array] $HVhost,
    [string] $VM,
    [Parameter(Mandatory = $true)]
    [string] $ExportPath,
    [string] $Logpath = "${env:homedrive}\windows\Logs\HyperVBackup",
    [switch] $ProductionCheckpoint
)



# region Logging
$LogDate = Get-Date -Format yyyy-MM-dd 
$LogPathExists = Test-Path $Logpath
if(!$LogPathExists){

    New-Item -Path $Logpath -ItemType "directory"
    Write-Host "No Log directory found. Creating Log directory in $Logpath"
    $LogFile = "$Logpath\$Logdate.log"
}
else{
    Write-Host "Log directory found."
    $Logfile = "$Logpath\$Logdate.log"
}
# endregion


# Start Logging
Start-Transcript -Path $LogFile -Append


# Checking the Hosts

##TODO: Check if Hosts are online

# List of VM to be exported

if(!$VM){
    Write-Host -ForegroundColor Yellow (Get-Date) "No VM specified. Exporting all VMs on host(s): $HVhost"
    $VMlist = Get-VM -ComputerName $HVhost
}
else{
    Write-Host -ForegroundColor Yellow (Get-Date) "The following VM(s) are going to be exported: $VM"
    $VMlist = $VM
}


# region Export

if($ProductionCheckpoint -match "true"){

    Foreach($VMEntry in $VMlist.Name){

        $SnapshotName = "BackupCheckpoint_$Logdate"
        Write-Host -ForegroundColor Green (Get-Date) "### Creating Checkpoint. ###"
        $DestinationPathExists = Test-Path $ExportPath\$VMEntry
        if($DestinationPathExists -eq $False){ 
           
            Checkpoint-VM -Name $VMEntry -SnapshotName $SnapshotName -verbose
            Export-VMSnapshot -VMName $VMEntry -Name $SnapshotName -Path $ExportPath -verbose
            Remove-VMSnapshot -VMName $VMEntry -Name $SnapshotName -verbose
        }
        else{ 
            
            Remove-Item -Recurse -Force $Exportpath\$VMEntry -verbose
            Checkpoint-VM -Name $VMEntry -SnapshotName $SnapshotName -verbose
            Export-VMSnapshot -VMName $VMEntry -Name $SnapshotName -Path $ExportPath -verbose
            Remove-VMSnapshot -VMName $VMEntry -Name $SnapshotName -verbose
        }
        Write-Host -ForegroundColor Green (Get-Date) "### Export of $VMEntry concluded. ###"
    }
}
else{

    Foreach($VMEntry in $VMlist.Name){

        Write-Host -ForegroundColor Green (Get-Date)"### Exporting VM(s) online. ###"
         $DestinationPathExists = Test-Path $ExportPath\$VMEntry
        if($DestinationPathExists -eq $False){
            Export-VM -Name $VMEntry -Path $Exportpath -verbose
        }
        else{
             Remove-Item -Recurse -Force $Exportpath\$VMEntry -verbose
             Export-VM -Name $VMEntry -Path $Exportpath -verbose
        }
        Write-Host -ForegroundColor Green (Get-Date) "### Export of $VMEntry concluded. ###"
    }
}
# endregion










