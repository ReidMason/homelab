Before running any commands make sure that you have copied your ssh key to the server.

```bash
ssh-copy-id USERNAME@SERVER_IP
```

When running the `initial-setup` playbook you will be asked for the sudo password. Provide this by using the `-K` flag.

```bash
ansible-playbook -K PLAYBOOK
```
