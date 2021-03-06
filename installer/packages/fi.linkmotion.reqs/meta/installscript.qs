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
    console.log("You are running " + systemInfo.prettyProductName + "with version " + systemInfo.productVersion); 
    Component.prototype.createOperations = function() {

        switch(systemInfo.productType) {
            case "ubuntu":
                expr = /1[67]\./;
                if (!expr.test(systemInfo.productVersion)){
                    cancelInstaller("Aborted installation! Ubuntu 16.04 LTS, 16.10, 17.04 or 17.10 is required. You are running " + systemInfo.prettyProductName);
                }
                install_script = "apt update && "+
                                "env DEBIAN_FRONTEND=noninteractive apt install git sshpass openssh-client libxcb-xinerama0 lxc1 weston gdb-multiarch qemu-user-static -y"
                break;
            case "debian":
                install_script = "apt update && "+
                                "env DEBIAN_FRONTEND=noninteractive apt install git sshpass openssh-client libxcb-xinerama0 lxc weston gdb-multiarch qemu-user-static -y"
                break;
            case "opensuse":
                install_script = "zypper refresh  && "+
                                "zypper install git sshpass openssh libxcb-xinerama0 lxc weston gdb qemu-linux-user"
                break;
            default:
                cancelInstaller("Aborted installation! At least Ubuntu 16.04 LTS, 16.10, 17.04, 17.10, ebian 9 or OpenSuse 42.3 are required. You are running " + systemInfo.prettyProductName);
                return;
        }

        component.addElevatedOperation("CreateDesktopEntry",
            "/usr/share/applications/linkmotionsdk.desktop",
            "Version=1.0\n"+
            "Type=Application\n"+
            "Terminal=false\n"+
            "X-KDE-StartupNotify=true\n"+
            "Exec=@TargetDir@/lm-sdk-ide/bin/qtcreator %F\n"+
            "Name=LinkMotion SDK\n"+
            "GenericName=The official Link Motion SDK IDE\n"+
            "Icon=@TargetDir@/linkmotionsdk_logo.png\n"+
            "StartupWMClass=qtcreator\n"+
            "Categories=Development;IDE;LinkMotion;\n"+
            "MimeType=text/x-c++src;text/x-c++hdr;text/x-xsrc;application/x-designer;application/vnd.qt.qmakeprofile;application/vnd.qt.xml.resource;\n");

        component.addElevatedOperation("Execute", ["bash", "-c", install_script]);
    }
}
