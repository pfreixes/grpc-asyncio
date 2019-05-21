cimport cpython

cdef class _UnaryCall:
    cdef:
        Channel channel
        CallbackGlue watcher_call
        grpc_completion_queue * cq
        grpc_experimental_completion_queue_functor functor
        object _waiter_call

    @staticmethod
    cdef void functor_run(grpc_experimental_completion_queue_functor* functor, int succeed)
    @staticmethod
    cdef void watcher_call_functor_run(grpc_experimental_completion_queue_functor* functor, int succeed)
