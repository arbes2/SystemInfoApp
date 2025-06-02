Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "System Information"
$form.Size = New-Object System.Drawing.Size(600, 550)
$form.StartPosition = "CenterScreen"

# Textbox
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Multiline = $true
$textbox.ScrollBars = "Vertical"
$textbox.ReadOnly = $true
$textbox.WordWrap = $false
$textbox.Font = New-Object System.Drawing.Font("Consolas", 10)
$textbox.Size = New-Object System.Drawing.Size(570, 440)
$textbox.Location = New-Object System.Drawing.Point(10, 10)

# Save Button
$saveBtn = New-Object System.Windows.Forms.Button
$saveBtn.Text = "Save Info to File"
$saveBtn.Size = New-Object System.Drawing.Size(120, 30)
$saveBtn.Location = New-Object System.Drawing.Point(240, 460)

# Close Button
$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = "Close"
$closeBtn.Size = New-Object System.Drawing.Size(80, 30)
$closeBtn.Location = New-Object System.Drawing.Point(490, 460)
$closeBtn.Add_Click({ $form.Close() })

# Gather info function
function Get-SystemInfo {
    $info = ""

    $info += "Computer Name: $env:COMPUTERNAME`r`n"
    $info += "Username: $env:USERNAME`r`n"

    $os = Get-CimInstance Win32_OperatingSystem
    $info += "OS: $($os.Caption) ($($os.Version))`r`n"
    $uptime = New-TimeSpan -Start $os.LastBootUpTime
    $info += "Uptime: {0} days {1} hrs {2} mins`r`n" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

    $ipList = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike "169.*" -and $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress
    $info += "IP Address(es): $($ipList -join ', ')`r`n"

    # CPU Info
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $info += "CPU: $($cpu.Name) | Cores: $($cpu.NumberOfCores) | Logical Processors: $($cpu.NumberOfLogicalProcessors)`r`n"

    # Battery Status (if laptop)
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $info += "Battery Status: $($battery.BatteryStatus)`r`n"
        $info += "Estimated Charge Remaining: $($battery.EstimatedChargeRemaining)%`r`n"
    } else {
        $info += "Battery Status: No battery detected`r`n"
    }

    # Disk Usage
    $info += "`r`nDisk Usage:`r`n"
    foreach ($drive in Get-PSDrive -PSProvider 'FileSystem') {
        $usedGB = [math]::Round(($drive.Used / 1GB), 1)
        $freeGB = [math]::Round(($drive.Free / 1GB), 1)
        $info += "  $($drive.Name): $usedGB GB used / $freeGB GB free`r`n"
    }

    # Installed RAM
    $ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    $info += "`r`nInstalled RAM: $([math]::Round($ram / 1GB, 2)) GB`r`n"

    # Network Adapters info
    $info += "`r`nNetwork Adapters:`r`n"
    $netAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $netAdapters) {
        $info += "  Name: $($adapter.Name) | MAC: $($adapter.MacAddress) | LinkSpeed: $($adapter.LinkSpeed)`r`n"
    }

    return $info
}

# Fill textbox on load
$textbox.Text = Get-SystemInfo

# Save file action
$saveBtn.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "Text Files (*.txt)|*.txt"
    $saveFileDialog.FileName = "SystemInfo.txt"
    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textbox.Text | Out-File -FilePath $saveFileDialog.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Info saved to $($saveFileDialog.FileName)", "Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
})

$form.Controls.Add($textbox)
$form.Controls.Add($saveBtn)
$form.Controls.Add($closeBtn)

$form.Topmost = $true
[void]$form.ShowDialog()
