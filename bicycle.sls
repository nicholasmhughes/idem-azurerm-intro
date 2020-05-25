#!jinja|yaml

{%- set id_string = "/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}/{4}" %}
{%- set sub = hub.acct.PROFILES["azurerm"].get("default", {}).get("subscription_id") %}
{%- set rg = "rg-bicycle" %}
{%- set tags = {
        "ApplicationName": "devopscolumbia",
        "Approver": "nicholas.hughes@eitr.tech",
        "BudgetAmount": "$50.00",
        "BusinessUnit": "RESEARCH",
        "CostCenter": "0001",
        "DR": "None",
        "EndDate": "2020-06-01",
        "Env": "Dev",
        "Owner": "nicholas.hughes@eitr.tech",
        "Requestor": "nicholas.hughes@eitr.tech",
        "ServiceClass": "Dev",
        "StartDate": "2020-05-28"
    }
%}
{%- set nsg_id = id_string.format(
      sub,
      rg,
      "Microsoft.Network",
      "networkSecurityGroups",
      "nsg-bike-001"
    )
%}
{%- set bepool_id = id_string.format(
      sub,
      rg,
      "Microsoft.Network",
      "loadBalancers",
      "lbe-bike-001/backendAddressPools/lbe-bike-bepool-001"
    )
%}
{%- set avail_id = id_string.format(
      sub,
      rg,
      "Microsoft.Compute",
      "availabilitySets",
      "avail-bike-001"
    )
%}

ensure_resource_group_exists:
    azurerm.resource.group.present:
        - name: rg-bicycle
        - location: eastus
        - tags: {{ tags }}

ensure_network_security_group_exists:
    azurerm.network.network_security_group.present:
        - name: nsg-bike-001
        - resource_group: rg-bicycle
        - security_rules:
            - name: allow_all_outbound
              priority: 100
              protocol: tcp
              access: allow
              direction: outbound
              source_address_prefix: virtualnetwork
              destination_address_prefix: internet
              source_port_range: "*"
              destination_port_range: "*"
            - name: allow_encrypted_inbound
              priority: 101
              protocol: tcp
              access: allow
              direction: inbound
              source_address_prefix: internet
              destination_address_prefix: virtualnetwork
              source_port_range: "*"
              destination_port_ranges:
                - "22"
                - "80"
                - "443"
        - tags: {{ tags }}

ensure_virtual_network_exists:
    azurerm.network.virtual_network.present:
        - name: vnet-bike-eastus-001
        - resource_group: rg-bicycle
        - address_prefixes:
            - "192.168.0.0/16"
        - subnets:
            - name: default
              address_prefix: "192.168.0.0/24"
              network_security_group:
                id: "{{ nsg_id }}"
        - tags: {{ tags }}

Ensure public IP exists:
    azurerm.network.public_ip_address.present:
        - name: pip-bike-001
        - resource_group: rg-bicycle
        - dns_settings:
            domain_name_label: devopscolumbia
        - sku: basic
        - public_ip_allocation_method: static
        - public_ip_address_version: ipv4
        - idle_timeout_in_minutes: 4
        - tags: {{ tags }}

Ensure availability set exists:
    azurerm.compute.availability_set.present:
        - name: avail-bike-001
        - resource_group: rg-bicycle
        - platform_update_domain_count: 1
        - platform_fault_domain_count: 1
        - sku: aligned
        - tags: {{ tags }}

Ensure load balancer exists:
    azurerm.network.load_balancer.present:
        - name: lbe-bike-001
        - resource_group: rg-bicycle
        - location: eastus
        - frontend_ip_configurations:
          - name: lbe-bike-feip-001
            public_ip_address: pip-bike-001
        - backend_address_pools:
          - name: lbe-bike-bepool-001
        - probes:
          - name: lbe-bike-probe-001
            protocol: tcp
            port: 80
            interval_in_seconds: 15
            number_of_probes: 3
        - load_balancing_rules:
          - name: lbe-bike-rule-001
            protocol: tcp
            frontend_port: 80
            backend_port: 80
            idle_timeout_in_minutes: 4
            frontend_ip_configuration: lbe-bike-feip-001
            backend_address_pool: lbe-bike-bepool-001
            probe: lbe-bike-probe-001
        - tags: {{ tags }}

{%  for i in [1, 2] %}
{%-   set nic_id = id_string.format(
        sub,
        rg,
        "Microsoft.Network",
        "networkInterfaces",
        "vmidem00{0}-nic0".format(i)
      )
-%}
ensure_network_interface{{i}}_exists:
    azurerm.network.network_interface.present:
        - name: vmidem00{{i}}-nic0
        - subnet: default
        - virtual_network: vnet-bike-eastus-001
        - resource_group: rg-bicycle
        - ip_configurations:
          - name: vmidem00{{i}}-nic0-ipc0
            load_balancer_backend_address_pools:
            - id: "{{ bepool_id }}"
        - primary: True
        - tags: {{ tags }}

ensure_virtual_machine{{i}}_exists:
    azurerm.compute.virtual_machine.present:
        - name: "vmidem00{{i}}"
        - resource_group: rg-bicycle
        - vm_size: "Standard_B2S"
        - image: "OpenLogic|CentOS|7.7|latest"
        - availability_set: "{{ avail_id }}"
        - network_interfaces:
          - id: "{{ nic_id }}"
        - ssh_public_keys:
            - /home/nmhughes/.ssh/id_rsa.pub
        - userdata: |
            sudo yum install -y httpd; sudo systemctl enable httpd --now
        - tags: {{ tags }}

{%  endfor -%}
