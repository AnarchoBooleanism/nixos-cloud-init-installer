# nixos-cloud-init-installer
A minimal NixOS flake with cloud-init designed for use as an installer ISO image for provisioning virtual machines

This was designed to be used to provision new NixOS virtual machines on a Proxmox host, while allowing the dynamic configuration of disks and other hardware.

There exist pre-built ISO images that you are able to download, for both x86_64 and aarch64, in this repository's releases. 

## Steps to build this image yourself:

This assumes that you have Nix installed on your system, with flakes and nix-commands enabled.

1. First, clone this Git repository.
2. Then, you can run one of these commands based on the architecture that you want to target:

**x86_64 (Intel/AMD):**
```bash
nix run nixpkgs#nixos-generators -- \
  --format iso --system x86_64-linux \
  --flake .#x86_64 --out-link result
```

**aarch64 (ARM64):**
```bash
nix run nixpkgs#nixos-generators -- \
  --format iso --system aarch64-linux \
  --flake .#aarch64 --out-link result
```

After building, your image should be in the `result/iso/` directory, being named something in the vein of `nixos-minimal-25.05-DATE-HASH-ARCHITECTURE-linux.iso`.

### Notice for cross-compiling images
If building an image for an architecture different to the native architecture of the build host, you will need to configure Nix accordingly.

Firstly, you will need to add the target architecture to your list of extra platforms on Nix.

For NixOS, you just need to add this line to your configuration file: `boot.binfmt.emulatedSystems = [ "ARCHITECTURE_NAME" ];`

For non-NixOS systems, you just need to add this line to `nix.conf`: `extra-platforms = ARCHITECTURE_NAME`

**Example for an x86_64 build system targetting aarch64:**
- `extra-platforms = aarch64-linux`

Furthermore, on non-NixOS systems, you will need QEMU installed, particularly the `qemu-system` and `qemu-efi` for your target architecture, as well as `binfmt-support` and `qemu-user-static`. This will allow you to run the binaries of your target architecture that are necessary for building the image with that architecture.

**Example apt command for Ubuntu on x86_64, for compiling as aarch64:**
- `sudo apt install qemu-system-aarch64 qemu-efi-aarch64 binfmt-support qemu-user-static` 

**NOTE:** As this approach uses emulation (with QEMU), build time is significantly increased, compared to native builds.

## Example workflow with Ansible on Proxmox
**1. Building or retrieving the ISO image**

Ansible can either build an ISO image (with the commands above), or download the latest release from GitHub.

**2. Uploading the ISO image to Proxmox**

The ISO image is then uploaded to Proxmox storage (accessible by the target node).

**3. Provisioning a new virtual machine**

Using the information from the playbook's inventory, as well as other provided variables, Ansible requests that Proxmox provision a new virtual machine. Furthermore, it attaches a cloud-init drive, providing credentials (e.g. SSH keys) and networking details needed by nixos-anywhere.

**4. Booting the virtual machine with the ISO image and cloud-init**

After the virtual machine is ready to start, Ansible boots the virtual machine, waiting until it can establish an SSH connection. Once NixOS is booted, cloud-init injects the listed credentials and details, allowing for unattended setup and SSH access.

**5. Initiating the install with nixos-anywhere**

With SSH ready, Ansible then runs nixos-anywhere, using the provided SSH key and a NixOS flake configuration, to then remotely install NixOS onto the virtual machine's disk. After this, NixOS should reboot into the new system.

**6. Post-installation**

With NixOS completely installed on the virtual machine, Ansible detaches the cloud-init drive and the ISO image, as they are no longer needed.