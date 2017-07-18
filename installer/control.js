function Controller() {
    if (installer.isUninstaller()) {
        installer.setDefaultPageVisible(QInstaller.Introduction, false);
        installer.setDefaultPageVisible(QInstaller.ComponentSelection, false);
        installer.setDefaultPageVisible(QInstaller.LicenseCheck, false);
    }
}


Controller.prototype.TargetDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.IntroductionPageCallback = function() {
    var widget = gui.currentPageWidget();
    if (widget != null) {
        widget.MessageLabel.setText("This installer will install LinkMotion SDK into /opt/linkmotion.");
    }
}
