HELP_MESSAGE = <<-S
xephyr-run is to run programs inside of dedicated Xephyr instances.

xephyr-run COMMAND

It takes a COMMAND that starts a program as its first argument, starts a
dedicated Xephyr instance for it, and -- once the program is running inside
of it -- outputs its display name to STDOUT, and exits.

For example:

    xephyr-run "sakura"

  would output ":10";

    xephyr-run "qemu-system-x86_64 -full-screen -m 6G -enable-kvm -vga virtio -fsdev local,security_model=mapped,id=shared0,path=$HOME/shared/ -device virtio-9p-pci,fsdev=shared0,mount_tag=shared0 -cdrom $PWD/alpine-virt-3.24.1-x86_64.iso"

  would output ":11";

And so on. The first display name is ":10", and it gets incremented by one(by
the counter living inside of the xephyrd daemon).
S

def print_help
  puts HELP_MESSAGE
end
