# terminal-config

Run the Linux installer (with `sudo` installed):
```sh
sh linux/apply-cfg-linux.sh
chsh -s <your-shell-option> <username>
```

You can specify the distribution when needed:
```sh
sh linux/apply-cfg-linux.sh --run-as-distro <distro>
```

try it with a docker container :)
```sh
docker run --rm -it --name=alpine-test -h=Alpinezera -v $PWD:/cfg alpine:3.17.2 sh -c "apk update; apk add sudo; adduser -S $USER; echo '$USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER; chmod 0440 /etc/sudoers.d/$USER; cd /cfg/linux; sudo -u $USER sh apply-cfg-linux.sh"
```
or 
```sh
docker run --rm -it --name=debian-test -h=Debianzera -v $PWD:/cfg debian:stable-slim sh -c "apt update; apt install sudo; adduser --system $USER; echo '$USER ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER; chmod 0440 /etc/sudoers.d/$USER; cd /cfg/linux; sudo -u $USER sh apply-cfg-linux.sh"
```