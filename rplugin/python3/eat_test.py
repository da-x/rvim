import pynvim
import asyncio
import aiohttp
import os
import eat

async def main():
    instance = eat.UnixSocketWsClient(None)
    for res in await instance.scan():
        print(res)


if __name__ == '__main__':
    asyncio.run(main())
