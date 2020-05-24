async def rg_list(hub, **kwargs):
    acct = await hub.acct.init.gather(["azurerm"], "default")
    kwargs.update(acct or {})
    ret = await hub.exec.azurerm.resource.group.list(**kwargs)
    return ret
