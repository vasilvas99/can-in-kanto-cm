# Unprivileged access to can-bus from kanto-cm containers

This is a guide for manually creating a virtual can interface, sending it to a kanto-cm container process' namespace,
and routing this virtual interface to the physical can0 if. That way the container will not need elevated privileges to read/write to the can-bus.

Based on [_Forwarding CAN Bus traffic to a Docker container using vxcan on Raspberry Pi_](https://www.lagerdata.com/articles/forwarding-can-bus-traffic-to-a-docker-container-using-vxcan-on-raspberry-pi).

# Quick Setup

1) Start with a cleanly-built Leda Distro QEMU image with internet access.

2) Take the `ubuntu_ctr.json` provided here and put it in `/data/var/containers/manifests_dev`. 

    *Note:* This is an otherwise basic manifest, the only special options that are set are:

    ```json
        "io_config": {
            "attach_stderr": true,
            "attach_stdin": true,
            "attach_stdout": true,
            "open_stdin": true,
            "stdin_once": true,
            "tty": true
        }
    ```
    That way you would be able to attach to the container's terminal.

3) Restart kanto-auto-deployer:

    ```shell
    $ systemctl restart kanto-auto-deployer
    ```

4) Wait for the container image to be pulled and to start successfully.

5) To attach to the container in interactive mode, you need to stop it first and then start it with the `--i` flag:

    ```shell
    $ kanto-cm stop -n ubuntu --force
    $ kanto-cm start -n ubuntu --i
    ```
    
    You will now be put in a shell inside the container. 
 
6) Update the container and install can-utils
    
    ```shell
    $ apt-get update
    $ apt-get install can-utils
    ```
    _Important_: leave this container terminal open. You will need it later. (Shortened as *CT* from now on)

7) Open another terminal to the Leda QEMU image (e.g. use `ssh -p 2222 root@127.0.0.1`). (Shortened as *QT* from now on)

8) In *QT* copy the `setup_container_can.sh` script in your home directory and run:
    ```shell
    $ cd ~
    $ chmod +x ./setup_container_can.sh
    $ ./setup_container_can.sh ubuntu
    ```

9) In *QT*  run `cangen can0` and leave *QT* open.

10) Go back to *CT* and run candump vxcan1. You should now be able to see the generated can data from outside the container.
