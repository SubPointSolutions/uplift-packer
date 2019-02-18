netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

winrm quickconfig -q

winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

winrm set winrm/config/service '@{AllowUnencrypted="true"}'

# vagrant hangs settings hostname on windows #5742
# https://github.com/hashicorp/vagrant/issues/5742

# WinRM some settings are needed in the Windows guest to have eg. enough memory for the remote processes.
# https://github.com/boxcutter/windows/blob/master/floppy/install-winrm.cmd#L55

winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'