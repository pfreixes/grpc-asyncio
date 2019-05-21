cimport cpython

import time


cdef class Channel:
    def __cinit__(self, target):
        self.g_channel = NULL
        self.target = target
        self.functor.functor_run = Channel.functor_run

        self.watcher_connector.functor.functor_run = Channel.watcher_connector_functor_run
        self.watcher_connector.obj = <cpython.PyObject *> self
        self._waiter_connection = None

        self.watcher_call.functor.functor_run = Channel.watcher_call_functor_run
        self.watcher_call.obj = <cpython.PyObject *> self
        self._waiter_call = None

    def __repr__(self):
        class_name = self.__class__.__name__ 
        id_ = id(self)
        return f"<{class_name} {id_}>"

    @staticmethod
    cdef void functor_run(grpc_experimental_completion_queue_functor* functor, int succeed):
        pass
 
    @staticmethod
    cdef void watcher_connector_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed):
        channel = <Channel>(<CallbackGlue *>functor).obj

        assert channel._waiter_connection

        state = grpc_channel_check_connectivity_state(channel.g_channel, 0)
        if state == GRPC_CHANNEL_CONNECTING:
            pass
        elif state == GRPC_CHANNEL_SHUTDOWN:
            pass
        elif state == GRPC_CHANNEL_TRANSIENT_FAILURE:
            pass
        elif state == GRPC_CHANNEL_READY:
            pass
        elif state == GRPC_CHANNEL_IDLE:
            pass
        else:
            pass

        channel._waiter_connection.set_result(state)

    @staticmethod
    cdef void watcher_call_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed):
        channel = <Channel>(<CallbackGlue *>functor).obj

        assert channel._waiter_call

        if succeed == 0:
            channel._waiter_call.set_exception(Exception("Some error ocurred"))
        else:
            channel._waiter_call.set_result(None)

    def close(self):
        grpc_channel_destroy(self.g_channel)

    async def connect(self):
        cdef grpc_channel_args args
        cdef grpc_connectivity_state state
        args.arguments = NULL
        self.g_channel = grpc_insecure_channel_create(<char *>self.target, &args, NULL)
        self.cq = grpc_completion_queue_create_for_callback(<grpc_experimental_completion_queue_functor *> &self.functor, NULL)
        state = grpc_channel_check_connectivity_state(self.g_channel, 1)

        self._waiter_connection = asyncio.get_running_loop().create_future()

        grpc_channel_watch_connectivity_state(
            self.g_channel,
            GRPC_CHANNEL_IDLE,
            _timespec_from_time(time.time() + 4),
            self.cq,
            &self.watcher_connector.functor
        )

        # Does not really wait till it is connected, returning to whaterver transition state
        return await self._waiter_connection

    async def unary_call(self, method, request):
        call = _UnaryCall(self)
        return await call.process(method, request)


async def create_channel(host, port):
    channel = Channel("{}:{}".format(host, port).encode())
    state = await channel.connect()
    return channel
