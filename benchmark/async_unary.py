import argparse
import asyncio
import time
import uvloop

from grpc_asyncio import grpc_init_asyncio
from grpc_asyncio import create_channel

from proto import echo_pb2


DEFAULT_CONCURRENCY = 1
DEFAULT_SECONDS = 10

finish_benchmark = False

async def requests(idx, channel):
    global finish_benchmark

    times = []
    while not finish_benchmark:
        # Synchronous client serializes and deserializes under the hood, so
        # to be fear we do the same by attributing the serialization and the
        # deserialization of the protobuf to the whole time

        # Also we build the request message at each call

        start = time.monotonic()
        response = await channel.unary_call(
            b'/echo.Echo/Hi',
            echo_pb2.EchoRequest(message="ping").SerializeToString()
        )
        echo_reply = echo_pb2.EchoReply.FromString(response)
        elapsed = time.monotonic() - start
        times.append(elapsed)

    return times


async def benchmark(loop, seconds=DEFAULT_SECONDS, concurrency=DEFAULT_CONCURRENCY):
    global finish_benchmark

    grpc_init_asyncio()

    print("Creating channels and warmming up ....")
    channels = []
    for i in range(concurrency):
        channel = await create_channel("127.0.0.1", 50051)
        response = await channel.unary_call(
            b'/echo.Echo/Hi',
            echo_pb2.EchoRequest(message="ping").SerializeToString()
        )
        response = echo_pb2.EchoReply.FromString(response)
        assert response

        channels.append(channel)

    print("Starting tasks ....")
    tasks = [ asyncio.ensure_future(requests(idx, channel)) for idx, channel in enumerate(channels) ]

    await asyncio.sleep(seconds)

    print("Finishing tasks ....")
    finish_benchmark = True

    while not all([task.done() for task in tasks]):
        await asyncio.sleep(0)

    times = []
    for task in tasks:
        times += task.result()

    times.sort()

    total_requests = len(times)
    avg = sum(times) / total_requests 

    p75 = times[int((75*total_requests)/100)]
    p90 = times[int((90*total_requests)/100)]
    p99 = times[int((99*total_requests)/100)]

    print('QPS: {0}'.format(int(total_requests/seconds)))
    print('Avg: {0:.6f}'.format(avg))
    print('P75: {0:.6f}'.format(p75))
    print('P90: {0:.6f}'.format(p90))
    print('P99: {0:.6f}'.format(p99))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--uvloop', action='store_true')
    parser.add_argument('-c', '--concurrency', type=int, default=DEFAULT_CONCURRENCY)
    parser.add_argument('-s', '--seconds', type=int, default=DEFAULT_SECONDS)
    args = parser.parse_args()
    if args.uvloop:
        uvloop.install()
    print("Starting benchmark with concurrency {} during {} seconds".format(args.concurrency, args.seconds))
    loop = asyncio.get_event_loop()
    loop.run_until_complete(benchmark(loop, seconds=args.seconds, concurrency=args.concurrency))
