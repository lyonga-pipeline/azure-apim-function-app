$driveLetters = @(${drive_letters})
$driveLabel = @(${drive_label})
$i=0

$disks = Get-Disk | Where partitionstyle -eq 'raw'
foreach ($disk in $disks)  
{  
    echo "Bring disk to online"
    Get-Disk -Number $disk.Number | Set-Disk -IsOffline $False

    echo "Initializing Disk to MBR partition"
    Initialize-Disk -Number $disk.Number -PartitionStyle MBR -PassThru

    echo "Creating Partitioning $driveLetters[$i]"
   
    if($null -eq $driveLabel[$i]){ $label = 'LocalDisk' } else { $label = $driveLabel[$i]} 
    if($null -eq $driveLetters[$i]){ $drive = "" } else { $drive = $driveLetters[$i]} 
    
    if ( $drive -eq ""){
        New-Partition -UseMaximumSize -AssignDriveLetter -DiskNumber $disk.Number | Format-Volume -FileSystem NTFS -NewFileSystemLabel $label
    } else {
        New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $drive | Format-Volume -FileSystem NTFS -NewFileSystemLabel $label
    }
   
    $i++
}  
