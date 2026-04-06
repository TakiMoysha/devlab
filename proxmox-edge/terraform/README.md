## Proxmox

### Alternatives

**Apache OpenStack** - представляет IaaS решение для поднятие своего облака, в то время когда proxmox решает только оркестрацию lxc и vm.

В CloudStack идет управление ресурсками, биллинг, изоляцию проектов, RBAC и автоматическую балансировку нагрузки на уровне гипервизора (KVM, XenServer, VMare ESXi). По сути это как ОС для датацентра или очень большой организации.
Для K8s потребуется rancher для управления кластерами, что усложняет работу с devlab, в proxmox просто поднимает lxc контейнер.

Proxmox же, это просто дистрибутив linux построеный на стеке виртуализации (KVM/QEMU + LXC). Это не облачная платформа, хоть и может быть расширен через VE Cluster, остается просто хост-системой.

Более того, proxmox дает декларативность для описания сервака. То есть мы избегаем состояния, что важно для devlab-ы. Мы описываем, что хотим получить в terraform и работаем с этим (infrastructure as code - IaC).

Для работы с сетью есть OVS и VLAN + ZFS/Ceph для упрощения работы с сетью/подсетями.

Будет слишком overhead для devlab/stage сервера.

## Resources

1. [Cloud init Guide / registry.terraform.io](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/guides/cloud_init)
