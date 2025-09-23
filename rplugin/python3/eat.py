#!/usr/bin/env python

import pynvim
import asyncio
import aiohttp
import os
import json


@pynvim.plugin
class UnixSocketWsClient(object):
    def __init__(self, nvim):
        self.nvim = nvim
        self.loop = asyncio.get_event_loop()
        self.ws = None
        self.session = None
        uid = os.getuid()
        self.unix_socket_path = f'/run/user/{uid}/eat'

    async def scan(self):
        instances = []
        for pid in os.listdir(self.unix_socket_path):
            path = os.path.join(self.unix_socket_path, pid)
            try:
                connector = aiohttp.UnixConnector(path=path)
                session = aiohttp.ClientSession(connector=connector)
                ws = await session.ws_connect("http://localhost/ws")
            except aiohttp.client_exceptions.UnixClientConnectorError:
                os.unlink(path)
                continue

            await ws.send_str('"SendInfo"')
            info = await ws.receive()
            await ws.close()
            info = json.loads(info.data)['Info']
            if info['bound']:
                continue
            instances.append((path, info))
        return instances

    async def scan_and_callback(self):
        res = await self.scan()
        self.nvim.call('EatBindCallback', res)

    async def bind(self, path):
        try:
            connector = aiohttp.UnixConnector(path=path)
            session = aiohttp.ClientSession(connector=connector)
            ws = await session.ws_connect("http://localhost/ws")
        except aiohttp.client_exceptions.UnixClientConnectorError:
            return
        await ws.send_str('"Bind"')
        await ws.receive()
        self.session = session
        self.ws = ws
        self.listener_task = asyncio.create_task(self.websocket_listener())
        self.nvim.err_write("Connected\n")

    async def next(self):
        if self.ws:
            await self.ws.send_str('"Next"')

    async def prev(self):
        if self.ws:
            await self.ws.send_str('"Prev"')

    async def redo(self):
        if self.ws:
            await self.ws.send_str('"Redo"')

    async def first(self):
        if self.ws:
            await self.ws.send_str('"First"')

    async def websocket_listener(self):
        """Continuously listen for messages and call the callback."""
        try:
            async for msg in self.ws:
                if msg.type == aiohttp.WSMsgType.TEXT:
                    # When a text message is received, call the callback.
                    self.handle_incoming_message(msg.data)
                elif msg.type == aiohttp.WSMsgType.ERROR:
                    self.nvim.err_write("WebSocket error occurred.\n")
        except Exception as e:
            self.nvim.err_write(f"Error in websocket_listener: {e}\n")

    def handle_incoming_message(self, message):
        """Callback function invoked when a message is received."""
        # Use async_call to ensure thread-safe interactions with Neovim.
        info = json.loads(message)
        if "VisitSource" in info:
            visit_source = info["VisitSource"]
            pathname = visit_source["pathname"]
            line = visit_source["line_idx"]

            def open_file():
                current_buf = self.nvim.current.buffer
                current_name = current_buf.name if current_buf else ''
                if current_name and current_name == pathname:
                    # The file is already open, jump to the line.
                    self.nvim.command(f"normal! {line}G")
                else:
                    # Open the file at the specified line.
                    self.nvim.command(f"edit +{line} {pathname}")

            self.nvim.async_call(open_file)

    @pynvim.function('EatScan', sync=False)
    def eat_scan(self, args):
        self.loop.create_task(self.scan_and_callback())

    @pynvim.function('EatBind', sync=False)
    def eat_bind(self, args):
        self.loop.create_task(self.bind(*args))

    @pynvim.function('EatNext', sync=False)
    def eat_enxt(self, args):
        self.loop.create_task(self.next(*args))

    @pynvim.function('EatPrev', sync=False)
    def eat_prev(self, args):
        self.loop.create_task(self.prev(*args))

    @pynvim.function('EatRedo', sync=False)
    def eat_redo(self, args):
        self.loop.create_task(self.redo(*args))

    @pynvim.function('EatFirst', sync=False)
    def eat_first(self, args):
        self.loop.create_task(self.first(*args))
