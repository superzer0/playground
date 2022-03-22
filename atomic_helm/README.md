# Failed deployment leaves running pods orphaned

Inspiration:  
<https://medium.com/polarsquad/check-your-kubernetes-deployments-46dbfbc47a7c>  
<https://polarsquad.com/blog/check-your-helm-deployments>

kubectl rollout status deployment myapp - will fail if the deployment is not successfull.  
Wait if it is in progress. Usefull for CI/CD  

Failed deployment leaves running pods in failed state. This needs to be cleaned up.  

```
helm upgrade --install failing.one .\failing-deployment\  --wait --timeout 20s --set "failedDeployment=true"
```

```
kubectl rollout status deployment myap
```

Then you would need to rollback  
```
helm rollback --wait --timeout 20 demo 1
```

But that can be one operation:
```
helm upgrade --install --atomic failing.one .\failing-deployment\ --wait --timeout 20s --set "failedDeployment=true"
```

And we have correct behavior  
```
Release "failing.one" does not exist. Installing it now.
Error: release failing.one failed, and has been uninstalled due to atomic being set: timed out waiting for the condition
```
