# Benchmark

## Test client

### Unary call

The environment used during that test was

* CPP sever running in a _c4.xlarge_ instance, with 4 cores.
* Python client running in a _c4.xlarge_ instance, with 4 cores.
* Both machines in the same availability zone.

The following table shows the benchmarks results of the unary call client performance by comparing the
gRPC default synchronous versus the asynchronous version. For the asynchronous version we
got results using two different loop implementations, the default CPython loop, and Uvloop.

Each row is a different execution of one of the implementations with a specific concurrency, for
the synchronous version concurrency is achieved by using threads while in the asynchronous version
concurrency is achieved by scheduling Asyncio tasks.

As a result, each row gives you the following metrics:

* QPS Maximum throughput achieved per second.
* Latency avg, in seconds, tells you the average time that each request took.
* Max CPU client, max CPU spotted during the experiment in the client side.
* Max CPU server, max CPU spotted during the experiment in the server side.

| Version       | Concurrency   | QPS           | latency avg  | Max CPU client | Max CPU server  |
| ------------- | -------------:| -------------:| ------------:| --------------:| ---------------:|
| sync          |             1 |          5724 |     0.000172 |            40% |             30% |
| sync          |             2 |         10030 |     0.000199 |           110% |             50% |
| sync          |             4 |         11621 |     0.000344 |           150% |             60% |
| sync          |             8 |         11792 |     0.000678 |           150% |             60% |
| sync          |             16|         11761 |     0.001341 |           150% |             60% |
| sync          |             32|         11865 |     0.002685 |           150% |             60% |
| sync          |             64|         11718 |     0.005467 |           150% |             60% |
| async (py)    |             1 |          4548 |     0.000220 |            50% |             25% |
| async (py)    |             2 |          8460 |     0.000236 |            90% |             45% |
| async (py)    |             4 |         10686 |     0.000374 |           100% |             60% |
| async (py)    |             8 |         14129 |     0.000566 |           100% |             80% |
| async (py)    |             16|         15696 |     0.001019 |           100% |            100% |
| async (py)    |             32|         17491 |     0.001829 |           100% |            120% |
| async (py)    |             64|         16982 |     0.003889 |           100% |            100% |
| async (py)    |            128|         17675 |     0.007244 |           100% |            120% |
| async (uvloop)|             1 |          5369 |     0.000186 |            40% |             30% |
| async (uvloop)|             2 |         10861 |     0.000184 |            80% |             50% |
| async (uvloop)|             4 |         13822 |     0.000289 |            98% |             90% |
| async (uvloop)|             8 |         18289 |     0.000437 |            95% |            150% |
| async (uvloop)|             16|         20332 |     0.000786 |            95% |            190% |
| async (uvloop)|             32|         22543 |     0.001419 |            95% |            225% |
| async (uvloop)|             64|         24971 |     0.002562 |           100% |            245% |
| async (uvloop)|            128|         25885 |     0.004944 |           100% |            250% |
| async (uvloop)|            256|         26658 |     0.009604 |           100% |            250% |

As we can see in the table results the synchronous client reaches quickly a limit of **11K QPS**, where
the CPP server is only spending a 60% of the CPU about the 400% that should be available. Hereby, adding
more concurrency does not increment the throughput and only adds more latency to each request.

The asynchronous version with the CPython loop keeps increasing the throughput up to reach the **17K QPS** and
having the CPP server using up to 120%. Hence, even adding more concurrency the throughput remains stable
but adding more latency to each request. The asynchronous version with the Uvloop loop increases the
throughput up to reach more than **25K QPS** and having the CPP sever using up to 250%.


Command for running the server

```bash
DYLD_LIBRARY_PATH=`pwd`/../vendor/grpc/libs/opt ./cpp_server/cpp_server
```

Commands for running the different client benchmarks

```bash
DYLD_LIBRARY_PATH=`pwd`/../vendor/grpc/libs/opt python async_unary.py --uvloop --concurrency 128 --seconds 10
DYLD_LIBRARY_PATH=`pwd`/../vendor/grpc/libs/opt python async_unary.py --concurrency 128 --seconds 10
DYLD_LIBRARY_PATH=`pwd`/../vendor/grpc/libs/opt python sync_unary.py --concurrency 128 --seconds 10
```

We have also benchmarked the none native gRPC library for Asyncio [grpclib](https://github.com/vmagamedov/grpclib).
The following table shows the benchmark for that specific library for the unary call from the perspective of the
client side, using the same CPP server used in the previous benchmark.

| Version          | Concurrency   | QPS           | latency avg  | Max CPU client | Max CPU server  |
| ---------------- | -------------:| -------------:| ------------:| --------------:| ---------------:|
| grpclib (uvloop) |             1 |          1608 |     0.000621 |            80% |              7% |
| grpclib (uvloop) |             2 |          1974 |     0.001012 |           100% |             10% |
| grpclib (uvloop) |             4 |          2137 |     0.001871 |           100% |             10% |
| grpclib (uvloop) |             8 |          2266 |     0.003530 |           100% |             10% |

As we can see the `grpclib` library performing is about 10x times worse than the native gRPC library
for Asyncio.
