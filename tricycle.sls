#!jinja|yaml

ensure_resource_group_exists:
    azurerm.resource.group.present:
        - name: rg-tricycle
        - location: eastus

ensure_virtual_network_exists:
    azurerm.network.virtual_network.present:
        - name: vnet-trike-eastus-001
        - resource_group: rg-tricycle
        - address_prefixes:
            - "192.168.0.0/16"
        - subnets:
            - name: default
              address_prefix: "192.168.0.0/24"

ensure_virtual_machine_exists:
    azurerm.compute.virtual_machine.present:
        - name: vmidem001
        - resource_group: rg-tricycle
        - vm_size: "Standard_B2S"
        - image: "OpenLogic|CentOS|7.7|latest"
        - virtual_network: vnet-trike-eastus-001
        - subnet: default
        - allocate_public_ip: True
        - ssh_public_keys:
            - /home/nmhughes/.ssh/id_rsa.pub

#!END
