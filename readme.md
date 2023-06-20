# IMPORTANT
- Make sure you point it at the right drive.


# Install Script
To be run on the iso and starts the process off.

- Creates partitions, crypt volume, lvm and pacstrap.
- Copies scripts.
- Calls chroot script.

# Chroot Script
Called by the install script to be run within the chroot environment.

- configures and builds bootloader.
- creates user.
- configures Setup to run on first boot.

# Setup Script
To be run on first boot. Handles setup and configuration. 

- Things seem a bit flakey if done from within the chroot environment.

- Tidies up scripts after done.
- Prompts a reboot.








# Things to work on
- Make the user a KDE admin.
- Add a prompt to check that the right drive is selected. 
    - Hopefully prevent accidents.
    - Maybe see if you can get it to print out the device type or something.
- Enable Dark Mode
- Fix hibernation.
    - Gonna guess that you could probably just get away with a larger swap.
    - But also check all the other things that need doing.
- Optimus Manager
- Comment the scripts.
- htop, nvtop
- Figure out how to swap pipewire-media-session with wireplumber without breaking pulseaudio
- Implement ufw.
- Need to break everything that isn't essential out into a separate script to be run on boot.
- Don't forget to download the hardware acceleration libraries.
