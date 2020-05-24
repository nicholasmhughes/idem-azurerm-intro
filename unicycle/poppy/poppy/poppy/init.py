import asyncio
import os

def __init__(hub):
    acct_file = os.environ.get("ACCT_FILE", "")
    acct_key = os.environ.get("ACCT_KEY", "")
    hub.pop.conf.integrate(["poppy"], loader="yaml", cli="poppy", roots=True)
    hub.pop.sub.add(dyne_name="idem")
    hub.pop.sub.add(dyne_name="exec")
    hub.pop.sub.load_subdirs(hub.exec, recurse=True)
    hub.pop.sub.add(dyne_name="states")
    hub.pop.sub.load_subdirs(hub.states, recurse=True)
    hub.acct.init.unlock(acct_file, acct_key)
    hub.pop.sub.add(pypath="poppy.rpc")
