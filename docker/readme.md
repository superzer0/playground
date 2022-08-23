# Debug container

Debug container used for debugging network issues primarly in K8S.

## Build & push

```sh
./build.docker.sh
```

## Run

```sh
kubectl run debug-container -it --image superzer0/debug-container
```
