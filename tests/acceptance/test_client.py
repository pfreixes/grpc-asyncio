import asyncio
import pytest
import subprocess
import time

from grpc_asyncio import grpc_init_asyncio
from grpc_asyncio import create_channel

from tests.acceptance.fixtures import echo_pb2


@pytest.fixture
def server():
    """
    Synchronous server runs in another process which initializes
    implicitly the grpc using the synchronous configuration.

    Both worlds can not cohexist within the same process.
    """
    p = subprocess.Popen(
        ["python", "tests/acceptance/fixtures/sync_server.py"],
        env=None
    )

    # giving some time to the server
    time.sleep(1)

    try:
        yield
    finally:
        p.terminate()


class TestClient:

    @pytest.mark.asyncio
    async def test_unary_call(self, server):
        grpc_init_asyncio()
        channel = await create_channel("127.0.0.1", 3333)
        response = await channel.unary_call(
            b'/echo.Echo/Hi',
            echo_pb2.EchoRequest(message="Hi Grpc Asyncio").SerializeToString()
        )
        assert response is not None
        assert echo_pb2.EchoReply.FromString(response).message == "Hi Grpc Asyncio"
