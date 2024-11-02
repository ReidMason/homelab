# Kubernetes configs

This directory contains the configuration files for my kubernetes cluster.

# Initial setup

The first thing we need to set up is metallb. This is a load balancer for bare metal kubernetes clusters.
Edit the metalb ip range in the metallb.yaml file.
Then run the following command.

```bash
# Inside the metallb directory
kubectl apply -k .
```
