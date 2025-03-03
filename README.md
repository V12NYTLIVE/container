# DOM Cloud Container

Set up your own DOM Cloud server instance inside a virtualized platform and control it with our cloud platform.

![](https://domcloud.co/assets/ss/selfhost.png)

Our self hosted solution is for our customers who:

+ Behind a corporate that mandates all data is self hosted to an on-premise server
+ Wishing for more computing power or having the hardware their your control

With Caveats:

+ This approach is generally more complex than simply using our cloud servers
+ Requires good knowledge of Linux and its networking components to make everything works
+ You're resposible to everything a server needs to do, including keeping the software up to date

Here's feature comparison:

| Compare Features | Cloud | Self-Hosted |
|:---|:---:|:---:|
| Getting Started  | Easy  | Easy but Challenging |
| Who own the Infra? | Us  | You |
| Who monitor Infra? | Us  | You |
| Has Public IP | ✅  | Depends on your ISP |
| Use `nsp/nss.domcloud.co` NS   | ✅ | ❌ |
| Can use `domcloud.dev` | ✅ | If not behind NAT |
| Storage/Network Limit  | Calculated  | Unlimited  |
| Can have `root` Access   | ❌ | ✅ |
| Self-hosted email  | ❌ | Possible [but discouraged](https://cfenollosa.com/blog/after-self-hosting-my-email-for-twenty-three-years-i-have-thrown-in-the-towel-the-oligopoly-has-won.html) |

## Built Images

The most recent one built on 2024-11-25:

+ [domcloud-x86_64.qcow2](https://domcloud-images.fra1.cdn.digitaloceanspaces.com/2411/domcloud-x86_64.qcow2) 4.3 GB
+ [domcloud-x86_64.vmdk](https://domcloud-images.fra1.cdn.digitaloceanspaces.com/2411/domcloud-x86_64.vmdk) 2.6 GB
+ [domcloud-aarch64.qcow2](https://domcloud-images.fra1.cdn.digitaloceanspaces.com/2411/domcloud-aarch64.qcow2) 4.2 GB
+ [domcloud-aarch64.vmdk](https://domcloud-images.fra1.cdn.digitaloceanspaces.com/2411/domcloud-aarch64.vmdk) 2.9 GB
+ [checksum](https://domcloud-images.fra1.cdn.digitaloceanspaces.com/2411/checksums.txt)

Select based on Virtualization platform e.g. Proxmox and QEMU uses `QCOW2` while VMWare and VirtualBox uses `VMDK`.

If you don't want to download our custom prebuilt images, you can run these from freshly installed [Rocky Linux Minimal ISO](https://rockylinux.org/download) instead:

```sh
# make sure to run this inside root privilenge:
curl -sSL https://github.com/domcloud/container/raw/refs/heads/master/install.sh | bash
curl -sSL https://github.com/domcloud/container/raw/refs/heads/master/preset.sh | bash
```

## About the image

We use [Hashicorp Packer](https://developer.hashicorp.com/packer/docs/install) to build images. We ran it inside privilenged docker. Simply run `make build-image`. With KVM acceleration the build should be done around one hour.

The image consist of [Rocky Linux Minimal ISO](https://rockylinux.org/download) + Some scripts that installs Virtualmin and additional services to make it exactly like how a DOM Cloud server works. See [install.sh](./install.sh) and [preset.sh](./preset.sh) to see the install scripts.


To run the final image using [QEMU](https://www.qemu.org):

```bash
qemu-system-x86_64 -hda domcloud-x86_64.qcow2 -smp 2 -m 2048 -net nic -net user,hostfwd=tcp::2022-:22,hostfwd=tcp::2080-:80,hostfwd=tcp::3443-:443,hostfwd=tcp::2443-:2443 -cpu max -accel kvm
# Windows: -cpu Broadwell -accel whpx,kernel-irqchip=off
```

This VM expose these ports:

+ 22 for SSH
+ 53 for DNS
+ 80 and 443 for HTTP/HTTPS
+ 2443 for Webmin

There's `http://localhost` Handled by NGINX to that runs our [bridge](https://github.com/domcloud/bridge/) software. This software orchestrates your VM based on (To be undocumented) REST APIs.

Go to `https://localhost:2443` in your browser to open webmin. Additionally, go to `http://localhost/status/check` and  `http://localhost/status/test` To see if all services running and configured correctly.

Enter credential `root` with `rocky` as password for SSH and Webmin login. 

The root password includes the `root` webmin access is `rocky`. The `bridge` HTTP secret and webmin login is also set to `rocky`.

## Things to do after your VM Running

### Have A Static Public IP

Please assign your `80` and `443` to your static public IP address.

If you don't have a public IP address or you're just running the whole VM behind NAT or your personal laptop, please **have a domain** and install [Cloudfare Zero Trust HTTP Tunnel](https://medium.com/@tomer.klein/cloudflare-zero-trust-setting-up-my-first-tunnel-1276ae4b61a4) to port `80` inside the VM. 

### Change your VM passwords

You have 4 passwords to change:

1. Root password, change it with `passwd`
2. Webmin root password, change it with `/usr/libexec/webmin/changepass.pl /etc/webmin root "<password>"`
3. User `bridge` password, change it with `passwd bridge`
4. `bridge` HTTP Secret key, change it in `/home/bridge/public_html/.env` and restart it `sudo systemctl restart bridge`.

Note that the `bridge` HTTP Secret key is used to be communitated with DOM Cloud software. More below.

### Check Virtualmin Configuration

Go to `https://localhost:2443` and log in with user `root`. 

1. Finish the post installation wizard
2. Go to `Virtualmin` -> `System Settings` -> `Re-Check Configuration`

### Install the correct IPv4 and IPv6 addresses

The VM is built with QEMU. The networking IP addresses definitely changed and you need to adjust it.

1. Identify your IP addresses, run `nmcli dev show ens3` or `ip addr show scope global` in terminal.
2. Go to `Virtualmin` -> `Addresses and Networking` -> `Change IP Addresses`
3. Enter old IP `10.0.2.15` and new IP. Click `Change Now`.

### Rename Bridge's `localhost` domain

The bridge default domain name is defaulted to `localhost` so you can open it via your laptop. But to connect it to DOM Cloud, you must put it to a domain. You can run this in SSH:

```sh
virtualmin change-domain --username bridge --new-domain mynewdomain.com
```

### Update Packages

Run `yum update --nobest`.

## Connect to DOM Cloud

Goto `Servers` section in [DOM Cloud Portal Dashboard](https://my.domcloud.co) to connect to our cloud portal.

Why still connecting to our cloud portal?

+ Bridge is `headless`. There are no UI, just pure APIs. The APIs are used to communicate to your instance.
+ All tools works out of the box, including Deployment systems, templates and GitHub integration
+ Deployments for self-hosted instances doesn't use storage/data network/instance limit
+ You get some cloud features like backups, domcloud.dev domain, team collab, etc
+ Can be connected for free

