async def rg_list(hub, **kwargs):
    acct = await hub.acct.init.gather(["azurerm"], "default")
    ctx = {"acct": acct}
    ret = await hub.exec.azurerm.resource.group.list(ctx, **kwargs)
    return ret
