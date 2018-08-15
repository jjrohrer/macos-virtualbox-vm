# macOS VirtualBox VM Instructions

Current macOS version: *High Sierra (10.13)*, tested with VirtualBox *5.1.28 r117968*

Note: this is a forked version of the project that only supports HighSierra
To build a VM running macOS, follow the directions below:

  1. Download the installer from Mac App Store (it should be available in the 'Purchases' section if you've acquired it previously). The installer will be placed in your Applications folder. (Should work for High Sierra - 10.13.).          
         The Installer will download to your Application folder, which is fine.  You can also move a copy to your current working directory.          
         
  2. Make the script executable and run it: 
    
        `
        chmod +x prepare-iso.sh
        ./prepare-iso.sh
        `
        
        This takes a long time to run, like 30 minutes.
        
        <!> Your iso should be about 7.17gB.

  3. Open VirtualBox and create a new VM.
  4. Set:
      - name: your choice, such as `Mac2`
      - type: `OS X`
      - version: `macOS HightSierra`
  5. Follow the rest of the VM creation wizard and either leave the defaults or adjust to your liking. Increase the video memory from the VirtualBox default of 16MB to at least 128MB, otherwise Sierra might not boot correctly, and display performance will be abysmal.
  6. In Terminal, run the command 
        
        `VBoxManage modifyvm "{vmname}" --cpuidset 00000001 000306a9 00020800 80000201 178bfbff`
                 
        (where `"{vmname}"` is the exact name of the VM set in step 4) so the VM has the right CPU settings for macOS.
  7. To prevent choppiness in the VM, go into settings and uncheck the 'Enable Audio' option under 'Audio'.
  8. Click 'Start' to boot the new VM.
  9. Select the iso created in step 2  (it will be sitting your Downloads directory) when VirtualBox asks for it.
      
      (You'll see lots of scrolling text, after a couple of minutes, the Apple logo with progress bar, and then the macOS Utilities menu)
  10. In the installer, select your preferred language.
  11. Go to `Utilities > Disk Utility`. Select the VirtualBox disk (something like VBOX HARDDISK MEDIE)and choose `Erase` to format it as a `Mac OS Extended (Journaled)` drive.
  
        If for you can not find the VirtualBox disk created inside the Disk Utility (likely), select View -> Show All Devices and format the newly visible device (Source: tinyapps.org). 
  12. Quit Disk Utility, and then continue with installation as normal (by clicking Reinstall macOS).
  11. This is where I am stuck....<!>  I can get to a related "macOS Install Data"
from the mac 
  12. When the install process complete, the machine will guest reboot, probably back onto your .iso.  To avoid this, ...        
        1. power off the virtual machine.
        2. Open Virtual Box
        3. Go to setting (for you new Mac)-> Storage-->HighSierra.iso-->Right Click-->Remove
        4. Start the new guest Mac
  13. If for High Sierra you encounter boot / EFI problems (likley), get yourself to the EFI Shell (Not the Mac Terminal) restart the VM and hit `F12` to get to the VirtualBox boot manager.  Select **EFI In-Terminal Shell** and run:
```bash
Shell> fs1:
FS1:\> cd "macOS Install Data"
FS1:\macOS Install Data\> cd "Locked Files"
FS1:\macOS Install Data\Locked Files\> cd "Boot Files"
FS1:\macOS Install Data\Locked Files\Boot Files\> boot.efi
```    
  15. Tip: After initial installation, be sure to take a snapshot in VirtualBox so that you don't need to reinstall again, unless you found this really fun.


## Troubleshooting & Improvements

- I've noticed that sometimes I need to go in and explicitly mark the iso as a Live CD in the VM settings in order to get the VM to boot from the image.
- If you try to start your VM and it does not boot up at all, check to make sure you have enough RAM to run your VM.
- Conversly, VirtualBox sometimes does not eject the virtual installer DVD after installation. If your VM boots into the installer again, remove the ISO in `Settings -> Storage`.
- VirtualBox uses the left command key as the "host key" by default. If you want to use it for shortcuts like `command+c` or `command-v` (copy&paste), you need to remap or unset the "Host Key Combination" in `Preferences -> Input -> Virtual Machine`.
- The default Video Memory of 16MB is far below Apple's official requirement of 128MB. Increasing this value may help if you run into problems and is also the most effective performance tuning.
- Depending on your hardware, you may also want to increase RAM and the share of CPU power the VM is allowed to use.
- When the installation is complete, and you have a fresh new macOS VM, you can shut it down and create a snapshot. This way, you can go back to the initial state in the future. I use this technique to test the [`mac-dev-playbook`](https://github.com/geerlingguy/mac-dev-playbook), which I use to set up and configure my own Mac workstation for web and app development.
- If for High Sierra you can not find the VirtualBox disk created inside the Disk Utility select `View -> Show All Devices` and format the newly visible device ([Source: tinyapps.org](https://tinyapps.org/blog/mac/201710010700_high_sierra_disk_utility.html)).

## Larger VM Screen Resolution

To control the screen size of your macOS VM:

  1. Shutdown your VM
  2. Run the following VBoxManage command:

          VBoxManage setextradata "[VM_NAME]" VBoxInternal2/EfiGopMode N

Replace `[VM_NAME]` with the name of your Virtual Machine.  Replace `N` with one of 0,1,2,3,4,5. These numbers correspond to the screen resolutions 640x480, 800x600, 1024x768, 1280x1024, 1440x900, 1920x1200 screen resolution, respectively.

The video mode can only be changed when the VM is powered off and remains persistent until changed. See more details in [this forum discussion](https://forums.virtualbox.org/viewtopic.php?f=22&t=54030).

## Notes

  - Code for this example mostly comes from VirtualBox forums and [this article](http://sqar.blogspot.de/2014/10/installing-yosemite-in-virtualbox.html).
  - Subsequently updated to support Yosemite - Sierra based on [this thread](https://forums.virtualbox.org/viewtopic.php?f=22&t=77068&p=358865&hilit=elCapitan+iso#p358865).
  - I'm currently looking into using Packer (maybe in tandem with Ansible) to automate the process of building a macOS box for VirtualBox. Since the ISO needs to be generated by the end user, it's a bit more involved (i.e. manual download of the original installer image), but not much worse than Packer for linux distros.
    - See also:
      - https://github.com/timsutton/osx-vm-templates
      - https://github.com/AndrewDryga/vagrant-box-osx-mavericks/blob/master/README.md
  - To install command line tools after macOS is booted, open a terminal window and enter `xcode-select --install` (or just try using `git`, `gcc`, or other tools that would be installed with CLI tools).

## Author

This project was originally created in 2015 by [Jeff Geerling](http://jeffgeerling.com/).
- 2017 Oct 28th: Fork of @dotCipher's fork of the above(https://github.com/dotCipher/macos-virtualbox-vm)

## History, Forking, Contributions
  
  ### Motivation & History of the Fork: 
  I wanted to create a clean Mac install, install guest HighSierra on top of a HighSierra host.  When
  I started, HighSierra wasn't yet supported, but dotCipher had a fork that seemed to work for him, but not for me.  
  In getting the script to work for me, it was easier for me to start ripping everything out so I could understand the
  flow.  I had originally hoped to fix up dotCipher's fork and submit my changes, but things are now hopelessing 
  borked and I doubt this branch will ever be merged the any of the original work.  Thanks to Jeff and dotCipher for
  getting the code to this point. JJ Rohrer(http://gitbug.com/jjrohrer)
  
  ### Contributing
  If your have improvements to this script, please contribute.
  Improvements that improve readability and robustness are particularly welcome
  
  
  
