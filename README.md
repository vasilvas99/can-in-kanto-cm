# Unprivileged access to can-bus from kanto-cm containers

This is a guide for manually creating a virtual can interface, sending it to a kanto-cm container process' namespace,
and routing this virtual interface to the physical can0 interface. 

That way the container will not need elevated privileges to read/write to the can-bus.

Based on [_Forwarding CAN Bus traffic to a Docker container using vxcan on Raspberry Pi_](https://www.lagerdata.com/articles/forwarding-can-bus-traffic-to-a-docker-container-using-vxcan-on-raspberry-pi).

# Quick Setup

1) Start a cleanly-built Leda Distro QEMU image with internet access.

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
 
6) Update the container's apt repositories and install can-utils
    
    ```shell
    $ apt-get update
    $ apt-get install can-utils
    ```
    _Important_: leave this container terminal open. You will need it later. (Shortened as **CT** from now on)

7) Open another terminal to the Leda QEMU image (e.g. use `ssh -p 2222 root@127.0.0.1`). (Shortened as **QT** from now on)

8) In **QT** copy the `setup_container_can.sh` script from this repository in your home directory and run:
    ```shell
    $ cd ~
    $ chmod +x ./setup_container_can.sh
    $ ./setup_container_can.sh ubuntu
    ```

9) In **QT**  run `cangen can0` and leave **QT** open.

10) Go back to **CT** and run `candump vxcan1`. You should now be able to see the generated can data from outside the container.


# Details

Steps 1. - 7. were mostly container setup. The actual can-routing setup is done by the `setup_container_can.sh` script.

Briefly it does the following:

1) Tries to obtain the PID of a kanto-cm container named `ubuntu` (or  whatever the `$1` argument is)

2) Sets up two virtual vxcan interfaces `vxcan0` and `vxcan1` that are connected to each other ("peers").
Kernel modules `vxcan` and `can-gw` required and included in the Leda-distro by default.

3) Uses `nsenter` to send the `vxcan1` peer to the container's process namespace

4) Uses `can-gw` to route all traffic from and to can0 to vxcan0. 


5) Being able to run `cangen can0` in **QT** and read the output from **CT** with `candump vxcan1` (and the other way around) proves that the setup was successful. 

6) The ` .host_config.privileged` property was set to `false` in the container manifest, so this proves that the container does not need elevated privileges to read the `can0` traffic when using this procedure.


# Other

If you start the Leda distro image with QEMU-host-guest can0 routing with the command

```shell
$ kas shell kas/leda-qemux86-64.yaml -c 'runqemu slirp qemuparams="-object can-host-socketcan,id=canhost0,if=can0,canbus=canbus0" nographic ovmf sdv-image-all'
```

This would allow you to run `cangen can0` on the **QEMU HOST** and read it from the ubuntu container inside the **QEMU GUEST** with `candump vxcan1`



# Limitations of the approach

- The current procedure is quite manual

- The container has to be already started to obtain a PID and move the `vxcan1` peer interface into its namespace. This can be a problem as the container entrypoint might be ran before the `vxcan1` is moved and thus fail if it expects a can interfaces to be available on startup. (TODO: check if hard-coding the PID in the manifest is possible/feasible)

- Ideally this should be a kanto-cm plugin/feature.

