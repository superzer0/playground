You cannot do rolling update deployments with PVC that are provisioned by ReadWriteOnce disks. 
It will fail if the node is scheduled on different node. 

