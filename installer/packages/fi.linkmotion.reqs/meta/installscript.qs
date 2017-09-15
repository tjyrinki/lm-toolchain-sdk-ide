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
     cancelInstaller("Aborted installation! Ubuntu 16.04 LTS, 16.10, 17.04 or 17.10 is required. You are running " + systemInfo.prettyProductName);
     return;
  }
  if (systemInfo.productVersion.indexOf("16") == -1 && systemInfo.productVersion.indexOf("17") == -1) {
    cancelInstaller("Aborted installation! Ubuntu 16.04 LTS, 16.10, 17.04 or 17.10 is required. You are running " + systemInfo.prettyProductName);
    return;
  }
  
  component.addElevatedOperation("CreateDesktopEntry",
    "/usr/share/applications/linkmotionsdk.desktop",
    "Version=1.0\n"+
    "Type=Application\n"+
    "Terminal=false\n"+
    "Exec=@TargetDir@/lm-sdk-ide/bin/qtcreator\n"+
    "Name=LinkMotion SDK\n"+
    "GenericName=The official Link Motion SDK IDE\n"+
    "Icon=@TargetDir@/linkmotionsdk_logo.png\n"+
    "Name[en_US]=LinkMotion SDK\n"+
    "StartupWMClass=qtcreator\n"+
    "Categories=Development;IDE;LinkMotion;");

  install_script = "apt update && "+
                   "env DEBIAN_FRONTEND=noninteractive apt install git sshpass openssh-client libxcb-xinerama0 lxc1 weston gdb-multiarch qemu-user-static -y"

  component.addElevatedOperation("Execute", ["bash", "-c", install_script]);

}
