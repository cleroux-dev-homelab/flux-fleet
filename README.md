# Flux-fleet

My Flux Fleet repository

## Running the cluster

Install the Flux Operator and Flux on the current kubectl context (the homelab cluster):

```bash
make flux
```

Flux's version, components and controller settings live in `clusters/homelab/flux-instance.yaml`.
To upgrade Flux, change `spec.distribution.version` there.
