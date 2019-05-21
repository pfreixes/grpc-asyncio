import argparse
import time
import grpc
from threading import Thread, Lock, Condition

from proto import echo_pb2
from proto import echo_pb2_grpc


DEFAULT_CONCURRENCY = 1
DEFAULT_SECONDS = 10

latencies = []
finish_benchmark = False
lock_latencies = Lock()
threads_started = 0
thread_start = Condition()
benchmark_start = Condition()


def requests(idx, stub, duration):
    global latencies, real_started, threads_started

    local_latencies = []
    elapsed = None

    with thread_start:
        threads_started += 1
        thread_start.notify()

    with benchmark_start:
        benchmark_start.wait()

    while not finish_benchmark:
        start = time.monotonic()
        stub.Hi(echo_pb2.EchoRequest(message="ping"))
        latency = time.monotonic() - start
        local_latencies.append(latency)

    lock_latencies.acquire()
    latencies += local_latencies
    lock_latencies.release()



def benchmark(seconds=DEFAULT_SECONDS, concurrency=DEFAULT_CONCURRENCY):
    global finish_benchmark, real_started

    print("Creating stubs and warmming up ....")
    stubs = []
    for i in range(concurrency):
        channel = grpc.insecure_channel("127.0.0.1:50051")
        stub = echo_pb2_grpc.EchoStub(channel)
        response = stub.Hi(echo_pb2.EchoRequest(message="ping"))
        assert response
        stubs.append(stub)

    print("Starting threads ....")
    threads = []
    for idx, stub in enumerate(stubs):
        thread = Thread(target=requests, args=(idx, stub, seconds))
        thread.start()
        threads.append(thread)

    def all_threads_started():
        return threads_started == concurrency

    # Wait till all of the threads are ready to start the benchmark
    with thread_start:
        thread_start.wait_for(all_threads_started)

    # Signal the threads to start the benchmark
    with benchmark_start:
        benchmark_start.notify_all()

    time.sleep(seconds)
    finish_benchmark = True

    for thread in threads:
        thread.join()

    latencies.sort()

    total_requests = len(latencies)
    avg = sum(latencies) / total_requests 

    p75 = latencies[int((75*total_requests)/100)]
    p90 = latencies[int((90*total_requests)/100)]
    p99 = latencies[int((99*total_requests)/100)]

    print('QPS: {0}'.format(int(total_requests/seconds)))
    print('Avg: {0:.6f}'.format(avg))
    print('P75: {0:.6f}'.format(p75))
    print('P90: {0:.6f}'.format(p90))
    print('P99: {0:.6f}'.format(p99))



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--concurrency', type=int, default=DEFAULT_CONCURRENCY)
    parser.add_argument('-s', '--seconds', type=int, default=DEFAULT_SECONDS)
    args = parser.parse_args()

    print("Starting benchmark with concurrency {} during {} seconds".format(args.concurrency, args.seconds))
    benchmark(seconds=args.seconds, concurrency=args.concurrency)
