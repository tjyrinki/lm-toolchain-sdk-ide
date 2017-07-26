// http://doc.qt.io/qtinstallerframework/noninteractive.html
 
function cancelInstaller(msg) {
    installer.setDefaultPageVisible(QInstaller.Introduction, false);
    installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
    installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
    installer.setDefaultPageVisible(QInstaller.ReadyForInstallation, false);
    installer.setDefaultPageVisible(QInstaller.StartMenuSelection, false);
    installer.setDefaultPageVisible(QInstaller.PerformInstallation, false);
    installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
    installer.setValue("FinishedText",msg)
}

function Component() {
  //installer.setDefaultPageVisible(QInstaller.TargetDirectory, false);
  if (systemInfo.productType !== "ubuntu") {
     cancelInstaller("Aborted installation! Ubuntu 16.04 or 16.10 is required. You are running " + systemInfo.prettyProductName);
     return;
  }
  if (systemInfo.productVersion.indexOf("16") == -1) {
    cancelInstaller("Aborted installation! Ubuntu 16.04 or 16.10 is required. You are running " + systemInfo.prettyProductName);
    return;
  }
  
  component.addElevatedOperation("CreateDesktopEntry","/usr/share/applications/linkmotionsdk.desktop","Version=1.0\nType=Application\nTerminal=false\nExec=@TargetDir@/qtcreator/bin/qtcreator\nName=LinkMotion SDK\nIcon=@TargetDir@/linkmotionsdk_logo.png\nName[en_US]=LinkMotion SDK");
  component.addElevatedOperation("Execute", "apt-get", "install", "git", "sshpass", "openssh-client", "libxcb-xinerama0", "lxc1", "weston", "gdb-multiarch", "-y");
}
